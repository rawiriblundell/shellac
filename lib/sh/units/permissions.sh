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

[ -n "${_SHELLAC_LOADED_units_permissions+x}" ] && return 0
_SHELLAC_LOADED_units_permissions=1

# @internal
_perm_digit_to_rwx() {
  case "${1}" in
    (7) printf -- '%s' 'rwx' ;;
    (6) printf -- '%s' 'rw-' ;;
    (5) printf -- '%s' 'r-x' ;;
    (4) printf -- '%s' 'r--' ;;
    (3) printf -- '%s' '-wx' ;;
    (2) printf -- '%s' '-w-' ;;
    (1) printf -- '%s' '--x' ;;
    (0) printf -- '%s' '---' ;;
    (*) printf -- 'permissions: %s\n' "Invalid octal digit: ${1}" >&2; return 1 ;;
  esac
}

# @description Convert an octal permission mode to symbolic rwx notation.
#   Accepts 3-digit (755) or 4-digit (4755) modes; strips a leading zero if present.
#   Handles setuid (s/S), setgid (s/S), and sticky (t/T) bits.
#
# @arg $1 string Octal permission mode (3 or 4 digits)
#
# @example
#   octal_to_rwx 755    # => rwxr-xr-x
#   octal_to_rwx 4755   # => rwsr-xr-x
#   octal_to_rwx 1777   # => rwxrwxrwt
#
# @stdout 9-character symbolic permission string
# @exitcode 0 Success
# @exitcode 1 Invalid input
octal_to_rwx() {
  local _octal _special _owner _group _other
  _octal="${1:?No octal mode given}"

  # Strip a leading zero from 4-digit input (0755 -> 755)
  case "${_octal}" in (0[0-7][0-7][0-7]) _octal="${_octal:1}" ;; esac

  case "${#_octal}" in
    (4)
      _special="${_octal:0:1}"
      _owner="$(_perm_digit_to_rwx "${_octal:1:1}")" || return 1
      _group="$(_perm_digit_to_rwx "${_octal:2:1}")" || return 1
      _other="$(_perm_digit_to_rwx "${_octal:3:1}")" || return 1
      # setuid (bit 4)
      if (( _special & 4 )); then
        case "${_owner:2:1}" in
          (x) _owner="${_owner:0:2}s" ;;
          (-) _owner="${_owner:0:2}S" ;;
        esac
      fi
      # setgid (bit 2)
      if (( _special & 2 )); then
        case "${_group:2:1}" in
          (x) _group="${_group:0:2}s" ;;
          (-) _group="${_group:0:2}S" ;;
        esac
      fi
      # sticky (bit 1)
      if (( _special & 1 )); then
        case "${_other:2:1}" in
          (x) _other="${_other:0:2}t" ;;
          (-) _other="${_other:0:2}T" ;;
        esac
      fi
    ;;
    (3)
      _owner="$(_perm_digit_to_rwx "${_octal:0:1}")" || return 1
      _group="$(_perm_digit_to_rwx "${_octal:1:1}")" || return 1
      _other="$(_perm_digit_to_rwx "${_octal:2:1}")" || return 1
    ;;
    (*)
      printf -- 'octal_to_rwx: %s\n' "Expected 3 or 4 digit octal mode, got: ${1}" >&2
      return 1
    ;;
  esac
  printf -- '%s\n' "${_owner}${_group}${_other}"
}

# @description Convert a symbolic rwx permission string to its octal representation.
#   Accepts 9-char (rwxr-xr-x) or 10-char (-rwxr-xr-x) input.
#   Handles setuid (s/S), setgid (s/S), and sticky (t/T) bits.
#
# @arg $1 string Symbolic permission string (9 or 10 characters)
#
# @example
#   rwx_to_octal rwxr-xr-x    # => 755
#   rwx_to_octal rwsr-xr-x    # => 4755
#   rwx_to_octal -rwxr-xr-x   # => 755
#
# @stdout Octal permission string (3 or 4 digits)
# @exitcode 0 Success
# @exitcode 1 Invalid input
rwx_to_octal() {
  local _sym _special _owner _group _other
  _sym="${1:?No symbolic mode given}"

  # Strip the file type character if present (10-char input)
  (( ${#_sym} == 10 )) && _sym="${_sym:1}"

  if (( ${#_sym} != 9 )); then
    printf -- 'rwx_to_octal: %s\n' "Expected 9 or 10 character symbolic mode, got: ${1}" >&2
    return 1
  fi

  _special=0
  _owner=0
  _group=0
  _other=0

  # Owner (chars 1-3)
  [[ "${_sym:0:1}" = 'r' ]] && (( _owner += 4 ))
  [[ "${_sym:1:1}" = 'w' ]] && (( _owner += 2 ))
  case "${_sym:2:1}" in
    (x) (( _owner += 1 )) ;;
    (s) (( _owner += 1 )); (( _special += 4 )) ;;
    (S) (( _special += 4 )) ;;
  esac

  # Group (chars 4-6)
  [[ "${_sym:3:1}" = 'r' ]] && (( _group += 4 ))
  [[ "${_sym:4:1}" = 'w' ]] && (( _group += 2 ))
  case "${_sym:5:1}" in
    (x) (( _group += 1 )) ;;
    (s) (( _group += 1 )); (( _special += 2 )) ;;
    (S) (( _special += 2 )) ;;
  esac

  # Other (chars 7-9)
  [[ "${_sym:6:1}" = 'r' ]] && (( _other += 4 ))
  [[ "${_sym:7:1}" = 'w' ]] && (( _other += 2 ))
  case "${_sym:8:1}" in
    (x) (( _other += 1 )) ;;
    (t) (( _other += 1 )); (( _special += 1 )) ;;
    (T) (( _special += 1 )) ;;
  esac

  if (( _special > 0 )); then
    printf -- '%s\n' "${_special}${_owner}${_group}${_other}"
  else
    printf -- '%s\n' "${_owner}${_group}${_other}"
  fi
}

# @description Auto-detect and convert between octal and symbolic permission modes.
#   Delegates to octal_to_rwx() or rwx_to_octal() based on the input format.
#
# @arg $1 string Octal mode or symbolic permission string
#
# @example
#   permissions_convert 755         # => rwxr-xr-x
#   permissions_convert rwxr-xr-x   # => 755
#
# @stdout Converted permission representation
# @exitcode 0 Success
# @exitcode 1 Invalid input
permissions_convert() {
  local _mode
  _mode="${1:?No permission mode given}"
  case "${_mode}" in
    ([0-9]*) octal_to_rwx "${_mode}" ;;
    (*)      rwx_to_octal "${_mode}" ;;
  esac
}
