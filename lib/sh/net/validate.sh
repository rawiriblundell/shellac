# shellcheck shell=bash

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
# IPv6 validator adapted from labbots/bash-utility (MIT)
#   https://github.com/labbots/bash-utility

[ -n "${_SHELLAC_LOADED_net_validate+x}" ] && return 0
_SHELLAC_LOADED_net_validate=1

# @internal Validate an IPv4 address string.
#   Strips optional CIDR notation and double quotes before checking.
#   Runs in a subshell so IFS/set manipulation does not leak.
_net_validate_ipv4() {
  # Disable SC2086: word splitting on ${*%/*} is intentional here
  # shellcheck disable=SC2086
  (
    IFS=.; set -f; set -- ${*//\"/}; set -- ${*%/*}
    local _octet _count _errcount
    _count=0
    _errcount=0
    if (( "${#}" == 4 )); then
      for _octet in "${@}"; do
        (( ++_count ))
        case "${_octet}" in
          (""|*[!0-9]*)
            printf -- '%s\n' "Octet ${_count} appears to be empty or non-numeric" >&2
            (( ++_errcount ))
          ;;
          (*)
            if (( _octet > 255 )); then
              printf -- '%s\n' "Octet ${_count} appears to be invalid (>255)" >&2
              (( ++_errcount ))
            fi
          ;;
        esac
      done
      (( _errcount > 0 )) && return 1
    else
      printf -- '%s\n' "Input does not appear to be a valid IPv4 address" >&2
      return 1
    fi
    return 0
  )
}

# @internal Validate a CIDR prefix length, or full addr/prefix notation.
#   $1: protocol hint — '4' (max 32), '6' (max 128), or '' (max 128).
#   $2: value — a bare prefix (e.g. 24, /24, 62) or addr/prefix (e.g. 192.168.1.0/24).
#   For addr/prefix form the address is validated and the protocol is inferred from it.
_net_validate_cidr() {
  local _proto _input _addr _prefix _max
  _proto="${1}"
  _input="${2}"

  if [[ "${_input}" = /* ]]; then
    # Leading slash only: bare prefix e.g. /24
    _prefix="${_input#/}"
    case "${_proto}" in
      (4) _max=32  ;;
      (*) _max=128 ;;
    esac
  elif [[ "${_input}" = */* ]]; then
    # Full addr/prefix notation e.g. 192.168.1.0/24 or 2001:db8::/32
    _addr="${_input%%/*}"
    _prefix="${_input##*/}"
    if [[ "${_addr}" = *:* ]]; then
      _net_validate_ipv6 "${_addr}" || return 1
      _max=128
    else
      _net_validate_ipv4 "${_addr}" || return 1
      _max=32
    fi
  else
    _prefix="${_input}"
    case "${_proto}" in
      (4) _max=32  ;;
      (*) _max=128 ;;
    esac
  fi

  printf -- '%d' "${_prefix}" >/dev/null 2>&1 || return 1
  (( _prefix >= 0 && _prefix <= _max ))
}

# @internal Validate a dotted-decimal IPv4 subnet mask.
#   A valid mask is a contiguous run of 1-bits followed by 0-bits.
#   Uses the identity: inv(mask) & (inv(mask) + 1) == 0.
_net_validate_subnet() {
  local _o1 _o2 _o3 _o4 _mask _inv
  _net_validate_ipv4 "${1}" || return 1
  IFS=. read -r _o1 _o2 _o3 _o4 <<< "${1%%/*}"
  (( _mask = (_o1 << 24) | (_o2 << 16) | (_o3 << 8) | _o4 ))
  (( _inv  = _mask ^ 0xFFFFFFFF ))
  (( (_inv & (_inv + 1)) == 0 ))
}

# @internal Validate an IPv6 address string via regex.
#   Handles full, compressed (::), link-local, IPv4-mapped, and zone-ID (%eth0) forms.
_net_validate_ipv6() {
  local _re
  _re="^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|"
  _re+="([0-9a-fA-F]{1,4}:){1,7}:|"
  _re+="([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|"
  _re+="([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|"
  _re+="([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|"
  _re+="([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|"
  _re+="([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|"
  _re+="[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|"
  _re+=":((:[0-9a-fA-F]{1,4}){1,7}|:)|"
  _re+="fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|"
  _re+="::(ffff(:0{1,4}){0,1}:){0,1}"
  _re+="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}"
  _re+="(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|"
  _re+="([0-9a-fA-F]{1,4}:){1,4}:"
  _re+="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}"
  _re+="(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$"
  [[ "${1}" =~ ${_re} ]]
}

# @description Validate a string as an IPv4 address, IPv6 address, CIDR prefix/notation,
#   or dotted-decimal subnet mask.
#
#   Protocol flags (-4, -6) act as hints that constrain or force the validator used.
#   Without a protocol flag, the type is detected heuristically:
#     ':' in input  →  IPv6
#     otherwise     →  IPv4
#
#   --cidr accepts:
#     A bare prefix length (e.g. 24, /24, 62).  Without -4/-6, accepts 0–128.
#     With -4, restricts to 0–32.  With -6, accepts 0–128.
#     Full addr/prefix notation (e.g. 192.168.1.0/24, 2001:db8::/32): validates
#     both the address and prefix; protocol is inferred from the address.
#
#   --subnet validates a dotted-decimal IPv4 subnet mask (e.g. 255.255.255.0).
#     The mask must be a contiguous run of 1-bits followed by 0-bits.
#
#   For email address validation, use str_is_email (text/predicates).
#
# @arg $1 string Protocol flag (optional): -4 or -6
# @arg $1 string Mode flag (optional): --cidr or --subnet
# @arg $@ string Value to validate
#
# @example
#   net_validate 192.168.1.1           # auto-detects IPv4        => exit 0
#   net_validate 2001:db8::1           # auto-detects IPv6        => exit 0
#   net_validate -4 192.168.1.1        # explicit IPv4            => exit 0
#   net_validate -6 ::1                # explicit IPv6            => exit 0
#   net_validate --cidr 24             # valid prefix (0-128)     => exit 0
#   net_validate -4 --cidr 24          # valid IPv4 prefix (0-32) => exit 0
#   net_validate -6 --cidr 62          # valid IPv6 prefix (0-128)=> exit 0
#   net_validate --cidr 192.168.1.0/24 # valid IPv4 CIDR          => exit 0
#   net_validate --cidr 2001:db8::/32  # valid IPv6 CIDR          => exit 0
#   net_validate --subnet 255.255.255.0 # valid subnet mask       => exit 0
#   net_validate --subnet 255.255.1.0   # non-contiguous mask     => exit 1
#
# @exitcode 0 Valid
# @exitcode 1 Invalid
# @exitcode 2 Missing argument or unknown flag
net_validate() {
  local _proto _mode _input
  _proto=""
  _mode=""

  while (( $# > 0 )); do
    case "${1}" in
      (-4)       _proto=4;      shift ;;
      (-6)       _proto=6;      shift ;;
      (--cidr)   _mode=cidr;    shift ;;
      (--subnet) _mode=subnet;  shift ;;
      (--)       shift; break ;;
      (-*)
        printf -- 'net_validate: unknown option: %s\n' "${1}" >&2
        return 2
      ;;
      (*) break ;;
    esac
  done

  if (( $# == 0 )); then
    printf -- '%s\n' "net_validate: missing argument" >&2
    return 2
  fi

  _input="${1}"

  case "${_mode}" in
    (cidr)
      _net_validate_cidr "${_proto}" "${_input}"
    ;;
    (subnet)
      _net_validate_subnet "${_input}"
    ;;
    ('')
      if [[ -z "${_proto}" ]]; then
        case "${_input}" in
          (*:*) _net_validate_ipv6 "${_input}" ;;
          (*)   _net_validate_ipv4 "${_input}" ;;
        esac
      elif [[ "${_proto}" = 4 ]]; then
        _net_validate_ipv4 "${_input}"
      else
        _net_validate_ipv6 "${_input}"
      fi
    ;;
  esac
}

# Backward-compat aliases
net_validate_ipv4()    { net_validate -4 "${@}"; }
net_validate_ipv6()    { net_validate -6 "${@}"; }
net_validate_address() { net_validate -4 "${@}"; }
