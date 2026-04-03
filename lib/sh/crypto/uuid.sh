# shellcheck shell=ksh

# Copyright 2022 Rawiri Blundell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################
# Provenance: https://github.com/rawiriblundell/shellac
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_crypto_uuid+x}" ] && return 0
_SHELLAC_LOADED_crypto_uuid=1

# We cross-reference the Shellac epoch library here
# This gives us epoch functions: time_epoch() and time_epoch_ms()
include time/epoch

# RFC4122-style UUIDs
# I just thought I'd take a brief moment for a shout-out. intl-spectrum.com had
# a couple of great articles by Nathan Rector that I referenced for v1 and v4.
# They managed to dumb this down enough _and_ throw in a couple of non-obvious
# nuggets of technical information that other resources didn't clearly articulate

# An updated shout-out: playfulprogramming.com has a series of articles by
# Corbin Crutchley that manage to neatly articulate the different UUID versions
# This was a useful resource for the decisions for v2, v6, v7 and v8

# UUID's are basically strings of hex with _at least_ the following byte features
# adc763c3-e5cb-43bd-a0ae-5d11615562bf
# Version ------^    ^    ^^-- Must be '17' if user generated
#                    ^-------- Must be '8', '9', 'a' or 'b'.

# @internal
_uuid_randchars() {
  local _n
  local _raw
  _n="${1:-36}"
  # Bounded dd read avoids the SIGPIPE propagation that hangs in CI pipeline
  # environments where SIGPIPE is SIG_IGN. 16/256 = 6.25% hex density, so
  # _n * 100 bytes yields ~6*_n hex chars on average — far more than needed.
  _raw=$(dd if=/dev/urandom bs=$(( _n * 100 )) count=1 2>/dev/null | tr -dc 'a-f0-9')
  printf -- '%s\n' "${_raw:0:${_n}}"
}

# @internal
# Populate UUID_NODE with a hardware MAC address if available, rejecting all-zero
# results (e.g. loopback). Falls back to a hostname-derived node ID prefixed with
# '17' to signal user-generated. Callers use UUID_NODE directly after this returns;
# the export persists across calls so node detection runs at most once per session.
_uuid_getnode() {
  local _uuid_mac
  local _uuid_hostname

  if command -v ip >/dev/null 2>&1; then
    _uuid_mac="$(ip -brief link | awk '$4 ~ /BROADCAST/ {print $3; exit}' | tr -d ':')"
  elif command -v ifconfig >/dev/null 2>&1; then
    _uuid_mac="$(ifconfig |
      grep -Eo '([[:xdigit:]]{1,2}[:-]){5}[[:xdigit:]]{1,2}' |
      grep -Ev '^00[:-]00[:-]00[:-]00[:-]00[:-]00$' |
      head -n 1 |
      tr -d ':-')"
  fi

  if [[ -n "${_uuid_mac}" ]] && [[ "${_uuid_mac}" != "000000000000" ]]; then
    UUID_NODE="${_uuid_mac}"
    export UUID_NODE
    return 0
  fi

  # No usable MAC — derive a node ID from the hostname instead
  # We start with '17' to indicate that this is a user generated value
  # Each ascii char takes two hex chars; 5 chars = 10 hex + '17' prefix = 12 total
  _uuid_hostname="${HOSTNAME:-$(uname -n)}"
  while (( "${#_uuid_hostname}" < 5 )); do
    _uuid_hostname="${_uuid_hostname}${HOSTNAME:-$(uname -n)}"
  done

  UUID_NODE="17$(printf -- '%s\n' "${_uuid_hostname}" |
    fold -w 1 |
    head -n 5 |
    while read -r _uuid_char; do
      printf -- '%02x' \'"${_uuid_char}"
    done)"
  export UUID_NODE
}

# @internal
# Capture the current Unix epoch in nanoseconds atomically in a single date call.
# Detects nanosecond support once at load time; exports UUID_EPOCH_NS on each call.
# Callers derive seconds via $(( UUID_EPOCH_NS / 1000000000 )) and nanoseconds
# via $(( UUID_EPOCH_NS % 1000000000 )) with no further subprocess calls.
if _uuid_ns_test="$(date +%s%N 2>/dev/null)" && [[ "${_uuid_ns_test}" != *N* ]] && [[ -n "${_uuid_ns_test}" ]]; then
  _uuid_now_ns() {
    UUID_EPOCH_NS="$(date +%s%N)"
    export UUID_EPOCH_NS
  }
else
  _uuid_now_ns() {
    UUID_EPOCH_NS="$(( $(time_epoch) * 1000000000 ))"
    export UUID_EPOCH_NS
  }
fi
unset _uuid_ns_test

# @internal
_uuid_clockseq() {
  if (( "${#UUID_CLOCK}" > 0 )); then
    # Increment with wraparound at the 14-bit boundary; keep zero-padded to 4 chars
    UUID_CLOCK="$(printf -- '%04x' $(( (16#${UUID_CLOCK} + 1) & 0x3fff )))"
  else
    # Initialise to a random 14-bit value (0x0000–0x3fff)
    # SRANDOM (bash 5.1+) gives 32-bit OS-sourced randomness; fall back to RANDOM
    UUID_CLOCK="$(printf -- '%04x' $(( (${SRANDOM:-$RANDOM}) & 0x3fff )))"
  fi
  export UUID_CLOCK
}

# @internal
_uuid_format() {
  local _uuid_version
  local _uuid_9th_byte
  local _uuid_hex

  case "${1}" in
    (v[1-8]|[1-8]) _uuid_version="${1/v/}" ;;
    (*)
      printf -- 'uuid: %s\n' "Unrecognised version specifier" >&2
      return 1
    ;;
  esac

  read -r _uuid_hex

  if (( ${#_uuid_hex} < 32 )); then
    printf -- 'uuid: %s\n' "Input too short: need at least 32 hex chars, got ${#_uuid_hex}" >&2
    return 1
  fi

  _uuid_9th_byte=( 8 9 a b )

  printf -- '%s-%s-%s%s-%s%s-%s\n' \
    "${_uuid_hex:0:8}" \
    "${_uuid_hex:8:4}" \
    "${_uuid_version}" "${_uuid_hex:13:3}" \
    "${_uuid_9th_byte[$((${SRANDOM:-$RANDOM}%4))]}" "${_uuid_hex:17:3}" \
    "${_uuid_hex:20:12}"
}

# @internal
_uuid_gettime() {
  local _uuid_lillian
  local _uuid_unix
  local _uuid_epoch
  local _uuid_g1582
  local _uuid_g1582ns100
  local _uuid_ns100_now
  local _uuid_nano_100
  local _epoch_s
  local _epoch_ns

  # The following magical numbers sourced from Go's UUID implementation
  # Copyright (c) 2009,2014 Google Inc. BSD 3-Clause License
  _uuid_lillian=2299160                            # Julian day of 15 Oct 1582
  _uuid_unix=2440587                               # Julian day of 1 Jan 1970
  _uuid_epoch="$(( _uuid_unix - _uuid_lillian ))"  # Days between epochs
  _uuid_g1582="$(( _uuid_epoch * 86400 ))"         # seconds between epochs
  _uuid_g1582ns100="$(( _uuid_g1582 * 10000000 ))" # 100-nanosecond intervals between epochs

  # Capture seconds and nanoseconds atomically; split by arithmetic only
  _uuid_now_ns
  _epoch_s="$(( UUID_EPOCH_NS / 1000000000 ))"
  _epoch_ns="$(( UUID_EPOCH_NS % 1000000000 ))"

  _uuid_ns100_now="$(( _epoch_s * 10000000 ))"
  _uuid_nano_100="$(( _epoch_ns / 100 ))"

  # We pre-pend with '1', add the lot and emit it in hex format
  printf -- '1%x' "$(( _uuid_ns100_now + _uuid_nano_100 + _uuid_g1582ns100 ))"
}

# Populate globals once at load time; callers reference them directly
_uuid_getnode
_uuid_now_ns
_uuid_clockseq

# @internal
# Convert a hex string (with or without hyphens) to raw binary bytes.
# Used by uuid_hash to encode the namespace UUID as bytes per RFC 4122.
_uuid_hex_to_bytes() {
  local _hex
  _hex="${1//-/}"
  while [[ -n "${_hex}" ]]; do
    printf -- "\\x${_hex:0:2}"
    _hex="${_hex:2}"
  done
}

# @description Generate a version 3 (MD5) or version 5 (SHA-1) namespace-based UUID.
#   Select the algorithm and namespace, then provide a unique name.
#
# @arg $@ string md5|v3 or sha1|v5, @dns|@url|@oid|@x500|@custom, and a name string
#
# @stdout A version 3 or 5 UUID string
# @exitcode 0 Success
# @exitcode 1 Missing hashmode, namespace, or name
uuid_hash() {
  local _uuid_hashmode
  local _uuid_namespace
  local _uuid_name
  while (( "${#}" > 0 )); do
    case "${1}" in
      (md5|v3)  _uuid_hashmode=md5 ;;
      (sha1|v5) _uuid_hashmode=sha1 ;;
      (@dns)    _uuid_namespace='6ba7b810-9dad-11d1-80b4-00c04fd430c8' ;;
      (@url)    _uuid_namespace='6ba7b811-9dad-11d1-80b4-00c04fd430c8' ;;
      (@oid)    _uuid_namespace='6ba7b812-9dad-11d1-80b4-00c04fd430c8' ;;
      (@x500)   _uuid_namespace='6ba7b814-9dad-11d1-80b4-00c04fd430c8' ;;
      (@custom) _uuid_namespace="${2}" ;;
      (*)       _uuid_name="${1}" ;;
    esac
    shift 1
  done

  if (( "${#_uuid_hashmode}" == 0 )); then
    printf -- 'uuid_hash: %s\n' "A hashmode must be selected: 'md5' or 'sha1'" >&2
    return 1
  fi

  if (( "${#_uuid_namespace}" == 0 )); then
    printf -- 'uuid_hash: %s\n' "A namespace must be selected: '@dns', '@url', '@oid', '@x500' or '@custom" >&2
    return 1
  fi

  if (( "${#_uuid_name}" == 0 )); then
    printf -- 'uuid_hash: %s\n' "A unique name must be provided" >&2
    return 1
  fi
  
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen --"${_uuid_hashmode}" --namespace "${_uuid_namespace}" --name "${_uuid_name}"
    return 0
  fi

  # Per RFC 4122: hash the namespace UUID as 16 raw bytes followed by the name
  # as UTF-8 octets. _uuid_hex_to_bytes strips hyphens and emits binary bytes.
  case "${_uuid_hashmode}" in
    (md5)
      { _uuid_hex_to_bytes "${_uuid_namespace}"; printf -- '%s' "${_uuid_name}"; } |
        md5sum |
        awk '{print $1}' |
        fold -w 1 |
        _uuid_format 3
    ;;
    (sha1)
      { _uuid_hex_to_bytes "${_uuid_namespace}"; printf -- '%s' "${_uuid_name}"; } |
        sha1sum |
        awk '{print $1}' |
        fold -w 1 |
        _uuid_format 5
    ;;
  esac
}

# @description Return the RFC4122 nil UUID (all zeros).
#
# @stdout 00000000-0000-0000-0000-000000000000
# @exitcode 0 Always
uuid_nil() {
  printf -- '%s\n' "00000000-0000-0000-0000-000000000000"
}

# @description Generate a version 1 (time-based, MAC address) UUID.
#   Uses uuidgen --time if available, otherwise generates from scratch.
#
# @stdout A version 1 UUID string
# @exitcode 0 Always
uuid_v1() {
  local _uuid_i
  local _uuid_char
  local _uuid_time
  local _uuid_node

  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen --time
    return 0
  fi

  # If we get to this point, we're generating one from scratch
  # UUIDv1's have the following requirements:
  # adc763c3-e5cb-13bd-a0ae-5d11615562bf
  # Must be '1' --^    ^    ^^-- Must be '17' if user generated
  #                    ^-- Must be '8', '9', 'a' or 'b'.
  _uuid_time=$(_uuid_gettime)
  # Run _uuid_clockseq to set/update UUID_CLOCK env var
  _uuid_clockseq
  [[ -z "${UUID_NODE}" ]] && _uuid_getnode
  _uuid_node="${UUID_NODE}"

  printf -- '%s\n' "${_uuid_time}${UUID_CLOCK}${_uuid_node}" | 
    fold -w 1 | 
    _uuid_format v1
}

# @description Generate a version 2 (DCE Security) UUID.
#   UUIDv2 is not implemented. The DCE Security UUID specification was never
#   made public, implementations are incompatible, and the format is effectively
#   defunct. Use uuid_v1 for time-based UUIDs or uuid_v4 for random UUIDs.
#
# @exitcode 1 Always
uuid_v2() {
  printf -- 'uuid_v2: %s\n' "UUIDv2 (DCE Security) is not supported. Use uuid_v1 or uuid_v4 instead." >&2
  return 1
}

# @description Generate a version 3 (MD5 namespace-based) UUID.
#   Alias for: uuid_hash v3 namespace name
#
# @arg $1 string Namespace: @dns, @url, @oid, @x500, or @custom
# @arg $2 string Name
#
# @stdout A version 3 UUID string
# @exitcode 0 Success
# @exitcode 1 Missing namespace or name
uuid_v3() {
  uuid_hash v3 "${@}"
}

# @description Generate a version 4 (fully random) UUID.
#   Uses uuidgen --random, /proc/sys/kernel/random/uuid, or a bash-native fallback.
#
# @stdout A version 4 UUID string
# @exitcode 0 Always
uuid_v4() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen --random
    return 0
  fi
  
  # Linux already does this for us, if it's here, just cat it
  if [[ -r /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
    return 0
  fi

  # As above but for FreeBSD + Linux compat
  if [[ -r /compat/linux/proc/sys/kernel/random/uuid ]]; then
    cat /compat/linux/proc/sys/kernel/random/uuid
    return 0
  fi

  # If we get to this point, we're generating one from scratch
  # This is bash native, based on libuuid's __uuid_generate_random()
  printf -- '%04x%04x-%04x-%04x-%04x-%04x%04x%04x\n' \
    "$(( ${SRANDOM:-$RANDOM} & 0xffff ))" \
    "$(( ${SRANDOM:-$RANDOM} & 0xffff ))" \
    "$(( ${SRANDOM:-$RANDOM} & 0xffff ))" \
    "$(( ${SRANDOM:-$RANDOM} & 0x0fff | 0x4000 ))" \
    "$(( ${SRANDOM:-$RANDOM} & 0x3fff | 0x8000 ))" \
    "$(( ${SRANDOM:-$RANDOM} & 0xffff ))" \
    "$(( ${SRANDOM:-$RANDOM} & 0xffff ))" \
    "$(( ${SRANDOM:-$RANDOM} & 0xffff ))"
}

# @description Generate a version 5 (SHA-1 namespace-based) UUID.
#   Alias for: uuid_hash v5 namespace name
#
# @arg $1 string Namespace: @dns, @url, @oid, @x500, or @custom
# @arg $2 string Name
#
# @stdout A version 5 UUID string
# @exitcode 0 Success
# @exitcode 1 Missing namespace or name
uuid_v5() {
  uuid_hash v5 "${@}"
}

# @description Generate a version 6 (reordered time) UUID.
#   Functionally equivalent to v1 but with timestamp bits stored MSB-first,
#   making v6 UUIDs lexicographically sortable. Prefer v6 over v1 for new work.
#
# @stdout A version 6 UUID string
# @exitcode 0 Always
uuid_v6() {
  local _ts_raw
  local _time_high
  local _time_mid
  local _time_low_bits
  local _clock_seq_hi
  local _clock_seq_lo
  local _node
  local _clock_int

  # _uuid_gettime returns printf '1%x' of the raw 60-bit timestamp integer.
  # That integer is MSB-first, which is exactly the field order v6 needs for
  # lexicographic sorting — so we just strip the literal '1' prefix and
  # zero-pad to 15 hex chars to get the three timestamp fields directly.
  _ts_raw="$(_uuid_gettime)"
  _ts_raw="${_ts_raw#1}"
  _ts_raw="$(printf -- '%015s' "${_ts_raw}" | tr ' ' '0')"

  _time_high="${_ts_raw:0:8}"
  _time_mid="${_ts_raw:8:4}"
  _time_low_bits="${_ts_raw:12:3}"

  _uuid_clockseq
  # Apply RFC 4122 variant bits (10xxxxxx) to clock_seq_hi by arithmetic,
  # avoiding fragile positional slicing of UUID_CLOCK
  _clock_int=$(( 16#${UUID_CLOCK} ))
  _clock_seq_hi="$(printf -- '%02x' $(( 0x80 | (_clock_int >> 8) & 0x3f )))"
  _clock_seq_lo="$(printf -- '%02x' $(( _clock_int & 0xff )))"

  [[ -z "${UUID_NODE}" ]] && _uuid_getnode
  _node="${UUID_NODE}"

  printf -- '%s-%s-6%s-%s%s-%s\n' \
    "${_time_high}" \
    "${_time_mid}" \
    "${_time_low_bits}" \
    "${_clock_seq_hi}" \
    "${_clock_seq_lo}" \
    "${_node}"
}

# @description Generate a version 7 (Unix timestamp + random) UUID.
#   Uses a 48-bit millisecond Unix timestamp followed by random bits, making
#   v7 UUIDs lexicographically sortable without requiring a MAC address.
#   Prefer v7 over v1/v6 for new work that doesn't need Gregorian-epoch time.
#
# @stdout A version 7 UUID string
# @exitcode 0 Always
uuid_v7() {
  local _ms_hex
  local _ms_high
  local _ms_low
  local _rand_a
  local _rand_b_hi
  local _rand_b_lo
  local _uuid_9th_byte

  # Derive milliseconds from the atomic nanosecond capture
  _uuid_now_ns
  _ms_hex="$(printf -- '%012x' "$(( UUID_EPOCH_NS / 1000000 ))")"
  _ms_high="${_ms_hex:0:8}"
  _ms_low="${_ms_hex:8:4}"

  # rand_a: 12 random bits (3 hex chars) filling the lower nibbles of field 3
  _rand_a="$(_uuid_randchars 3 | paste -sd '' -)"

  # rand_b: variant nibble + 62 random bits across fields 4 and 5
  _uuid_9th_byte=( 8 9 a b )
  _rand_b_hi="${_uuid_9th_byte[$((${SRANDOM:-$RANDOM}%4))]}$(_uuid_randchars 3 | paste -sd '' -)"
  _rand_b_lo="$(_uuid_randchars 12 | paste -sd '' -)"

  printf -- '%s-%s-7%s-%s-%s\n' \
    "${_ms_high}" \
    "${_ms_low}" \
    "${_rand_a}" \
    "${_rand_b_hi}" \
    "${_rand_b_lo}"
}

# @description Generate a version 8 (custom) UUID.
#   RFC 9562 mandates only the version and variant bits; the three custom fields
#   (custom_a 48-bit, custom_b 12-bit, custom_c 62-bit) are implementation-defined.
#   This implementation fills them with random data by default, producing a UUID
#   that is distinguishable from v4 by version number. Callers with a specific
#   encoding scheme can supply their own hex values for each field; any omitted
#   field is randomised.
#
# @arg --custom-a hex  48-bit custom field (up to 12 hex chars)
# @arg --custom-b hex  12-bit custom field (up to 3 hex chars)
# @arg --custom-c hex  62-bit custom field (up to 15 hex chars)
#
# @stdout A version 8 UUID string
# @exitcode 0 Success
# @exitcode 1 Invalid arguments
uuid_v8() {
  local _custom_a
  local _custom_b
  local _custom_c
  local _custom_a_hi
  local _custom_a_lo
  local _custom_c_hi
  local _custom_c_lo
  local _uuid_9th_byte

  while (( "${#}" > 0 )); do
    case "${1}" in
      (--custom-a)
        _custom_a="${2:?uuid_v8: --custom-a requires a hex value}"
        shift
      ;;
      (--custom-b)
        _custom_b="${2:?uuid_v8: --custom-b requires a hex value}"
        shift
      ;;
      (--custom-c)
        _custom_c="${2:?uuid_v8: --custom-c requires a hex value}"
        shift
      ;;
      (*)
        printf -- 'uuid_v8: unknown option: %s\n' "${1}" >&2
        return 1
      ;;
    esac
    shift
  done

  # Pad or truncate each custom field to its correct width, randomising if absent
  : "${_custom_a:=$(_uuid_randchars 12 | paste -sd '' -)}"
  : "${_custom_b:=$(_uuid_randchars 3  | paste -sd '' -)}"
  : "${_custom_c:=$(_uuid_randchars 15 | paste -sd '' -)}"
  _custom_a="$(printf -- '%012s' "${_custom_a:0:12}" | tr ' ' '0')"
  _custom_b="$(printf -- '%03s'  "${_custom_b:0:3}"  | tr ' ' '0')"
  _custom_c="$(printf -- '%015s' "${_custom_c:0:15}" | tr ' ' '0')"

  _custom_a_hi="${_custom_a:0:8}"
  _custom_a_lo="${_custom_a:8:4}"

  # custom_c spans fields 4 and 5; field 4's first nibble carries the variant
  _uuid_9th_byte=( 8 9 a b )
  _custom_c_hi="${_uuid_9th_byte[$((${SRANDOM:-$RANDOM}%4))]}${_custom_c:0:3}"
  _custom_c_lo="${_custom_c:3:12}"

  printf -- '%s-%s-8%s-%s-%s\n' \
    "${_custom_a_hi}" \
    "${_custom_a_lo}" \
    "${_custom_b}" \
    "${_custom_c_hi}" \
    "${_custom_c_lo}"
}

# @description Generate a pseudo-UUID using od and /dev/urandom.
#   Not RFC4122 compliant; useful for quick non-critical identifiers.
#
# @stdout A pseudo-UUID string
# @exitcode 0 Always
uuid_pseudo() {
  dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -x | head -n 1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'
}

# @description Generate a UUID of the specified version (default: v4).
#
# @arg $1 string Optional: -0/-nil/-null, -1/--time, -2, -3/--md5, -4/-r/--random,
#   -5/--sha1, -6/--sortable, -7/--ms-time, -8/--custom, or --pseudo
#
# @stdout A UUID string
# @exitcode 0 Success
# @exitcode 1 Invalid arguments or unsupported version
uuid_gen() {
  local _uuid_stdout
  case "${1}" in
    (-0|-nil|-null)  _uuid_stdout="$(uuid_nil)" ;;
    (-1|--time)      _uuid_stdout="$(uuid_v1)" ;;
    (-2)             uuid_v2; return "${?}" ;;
    (-3|--md5)
      shift 1
      _uuid_stdout="$(uuid_v3 "${@}")"
    ;;
    (-4|-r|--random) _uuid_stdout="$(uuid_v4)" ;;
    (-5|--sha1)
      shift 1
      _uuid_stdout="$(uuid_v5 "${@}")"
    ;;
    (-6|--sortable)  _uuid_stdout="$(uuid_v6)" ;;
    (-7|--ms-time)   _uuid_stdout="$(uuid_v7)" ;;
    (-8|--custom)
      shift 1
      _uuid_stdout="$(uuid_v8 "${@}")"
    ;;
    (--pseudo)       _uuid_stdout="$(uuid_pseudo)" ;;
    ('')             _uuid_stdout="$(uuid_v4)" ;;
    (*)
      printf -- 'uuid_gen: unrecognised option: %s\n' "${1}" >&2
      return 1
    ;;
  esac
  printf -- '%s\n' "${_uuid_stdout}"
}

# @description Blindly convert a UUID between little-endian and mixed-endian (Microsoft) byte order.
#   The first three octets are byte-swapped; the remainder are unchanged.
#
# @arg $1 string A valid UUID string
#
# @stdout UUID with first three octets in reversed byte order
# @exitcode 0 Success
# @exitcode 1 No UUID supplied or invalid UUID structure/content
uuid_switch_endian() {
  local _uuid

  if (( ${#} == 0 )); then
    if [[ ! -t 0 ]]; then
      IFS= read -r _uuid
    else
      printf -- '%s\n' "uuid_switch_endian: No UUID supplied." >&2
      return 1
    fi
  else
    _uuid="${1}"
  fi

  # Next we try to validate that we're dealing with a UUID
  if command -v validate_uuid >/dev/null 2>&1; then
    if ! validate_uuid "${_uuid}" >/dev/null 2>&1; then
      printf -- 'uuid_switch_endian: Does not appear to be a valid UUID: %s\n' "${_uuid}" >&2
      return 1
    fi
  # If that function's not available, we just throw this cheap length check at it:
  elif (( ${#_uuid:-0} != 36 )); then
    printf -- 'uuid_switch_endian: Does not appear to be a valid UUID: %s\n' "${_uuid}" >&2
    return 1
  fi

  # We explode the UUID to its two-char hex bytes and assign it to a var
  _uuid="$(printf -- '%s\n' "${_uuid}" | tr -d '-' | fold -w 2 | paste -sd ' ' -)"

  # We want word splitting here
  # This assigns each space delimited hex byte to a position in the positional params array
  # shellcheck disable=SC2086
  set -- ${_uuid}

  # Now we simply print out the elements of the positional params array
  # We can see with the first three octets that the positions are rotated
  printf -- '%s-%s-%s-%s-%s\n' \
    "${4}${3}${2}${1}" \
    "${6}${5}" \
    "${8}${7}" \
    "${9}${10}" \
    "${11}${12}${13}${14}${15}${16}"
}

# @description Validate that a string is a structurally and content-valid UUID.
#   Checks the 8-4-4-4-12 structure and that all characters are hexadecimal.
#
# @arg $1 string The UUID string to validate
#
# @exitcode 0 Valid UUID
# @exitcode 1 Invalid structure or non-hex characters found
validate_uuid() {
  local _uuid_hex_char
  local _uuid_string
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _uuid_string
  else
    _uuid_string="${1:?No UUID provided}"
  fi

  # Nil UUID is valid by definition; fast exit avoids the loop entirely
  [[ "${_uuid_string}" = "00000000-0000-0000-0000-000000000000" ]] && return 0

  # Validate the structure
  # shellcheck disable=SC2046 # We want word splitting here
  set -- $(printf -- '%s\n' "${_uuid_string}" | tr '-' ' ')
  if (( ${#1} != 8 )) || (( ${#2} != 4 )) || (( ${#3} != 4 )) || (( ${#4} != 4 )) || (( ${#5} != 12 )); then
    printf -- '%s: invalid structure\n' "${_uuid_string}" >&2
    return 1
  fi

  # Validate the content — case matches all valid hex bytes cleanly,
  # no arithmetic needed and no bash error on invalid input
  while read -r _uuid_hex_char; do
    case "${_uuid_hex_char}" in
      ([0-9a-fA-F][0-9a-fA-F]) : ;;
      (*)
        printf -- '%s: non-hex chars found: %s\n' "${_uuid_string}" "${_uuid_hex_char}" >&2
        return 1
      ;;
    esac
  done < <(printf -- '%s\n' "${_uuid_string}" | tr -d '-' | fold -w 2)

  # No problems found?  Must be a legit UUID then!
  return 0
}
