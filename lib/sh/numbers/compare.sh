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
# Adapted from elibs/ebash (Apache-2.0) https://github.com/elibs/ebash
# Adapted from labbots/bash-utility (MIT) https://github.com/labbots/bash-utility

[ -n "${_SHELLAC_LOADED_numbers_compare+x}" ] && return 0
_SHELLAC_LOADED_numbers_compare=1

# @description Compare two integers.
#   Mirrors the convention used in numbers/version_compare.sh:
#   exit 0 = equal, exit 1 = first greater, exit 2 = first less.
#   This makes it easy to use in case statements alongside version_compare.
#
# @arg $1 int First integer
# @arg $2 int Second integer
#
# @example
#   num_compare 5 3; echo $?    # => 1  (5 > 3)
#   num_compare 3 5; echo $?    # => 2  (3 < 5)
#   num_compare 4 4; echo $?    # => 0  (equal)
#
#   case "$(num_compare "${a}" "${b}"; echo $?)" in
#     0) echo equal ;;
#     1) echo "a is greater" ;;
#     2) echo "b is greater" ;;
#   esac
#
# @exitcode 0 Equal; 1 First > second; 2 First < second
num_compare() {
  local _lhs _rhs
  _lhs="${1:?num_compare: missing first integer}"
  _rhs="${2:?num_compare: missing second integer}"
  if (( _lhs == _rhs )); then
    return 0
  elif (( _lhs > _rhs )); then
    return 1
  else
    return 2
  fi
}

# @description Compare two floating-point numbers using awk (no bc dependency).
#   Returns the same exit code convention as num_compare.
#
# @arg $1 float First number
# @arg $2 float Second number
#
# @example
#   num_compare_float 3.14 2.72; echo $?    # => 1
#   num_compare_float 1.0  1.0;  echo $?    # => 0
#
# @exitcode 0 Equal; 1 First > second; 2 First < second
num_compare_float() {
  local _lhs _rhs
  _lhs="${1:?num_compare_float: missing first number}"
  _rhs="${2:?num_compare_float: missing second number}"
  awk -v a="${_lhs}" -v b="${_rhs}" 'BEGIN {
    if (a == b) { exit 0 }
    else if (a > b) { exit 1 }
    else { exit 2 }
  }'
}

# @description Compare two dot-separated version numbers.
#
# @arg $1 string Version A (e.g. "2.1.0")
# @arg $2 string Version B (e.g. "2.0.9")
#
# @example
#   numbers_version_compare "2.1.0" "2.0.9"  # => exit 1 (A > B)
#   numbers_version_compare "1.0" "1.0.0"    # => exit 0 (equal)
#   numbers_version_compare "1.0" "2.0"      # => exit 2 (A < B)
#
# @exitcode 0 A == B
# @exitcode 1 A > B
# @exitcode 2 A < B
# @exitcode 3 Missing arguments
# @exitcode 4 Invalid format (non-numeric segments)
numbers_version_compare() {
  local _regex _i
  declare -a ver1 ver2
  (( ${#} < 2 )) && {
    printf -- '%s\n' "numbers_version_compare: requires 2 arguments" >&2
    return 3
  }
  case "${1}" in
    (*[!0-9.]*|'')
      printf -- 'numbers_version_compare: invalid argument: %s\n' "${1}" >&2
      return 4
    ;;
  esac
  case "${2}" in
    (*[!0-9.]*|'')
      printf -- 'numbers_version_compare: invalid argument: %s\n' "${2}" >&2
      return 4
    ;;
  esac
  [[ "${1}" = "${2}" ]] && return 0
  IFS=. read -r -a ver1 <<< "${1}"
  IFS=. read -r -a ver2 <<< "${2}"
  for (( _i = ${#ver1[@]}; _i < ${#ver2[@]}; _i++ )); do
    ver1[_i]=0
  done
  for (( _i = 0; _i < ${#ver1[@]}; _i++ )); do
    [[ -z "${ver2[_i]}" ]] && ver2[_i]=0
    (( 10#${ver1[_i]} > 10#${ver2[_i]} )) && return 1
    (( 10#${ver1[_i]} < 10#${ver2[_i]} )) && return 2
  done
  return 0
}

# @description Convert a semantic version string to a zero-padded integer for numeric comparison.
#   Strips non-numeric/non-dot characters, then formats as MMMMNNPP (major, 2-digit minor, 2-digit patch).
#
# @arg $1 string Version string (e.g. "1.0.2k-fips" or "openssl 1.0.2")
#
# @example
#   semver_to_int "1.0.2k-fips"   # => 10002
#   semver_to_int "2.31.0"        # => 23100
#
# @stdout Integer representation of the version
# @exitcode 0 Always
semver_to_int() {
    local _sem_ver
    _sem_ver="${1:?No version number supplied}"

    if [ -n "${BASH_VERSION}" ]; then
        _sem_ver="${_sem_ver//[^0-9.]/}"
        # shellcheck disable=SC2086
        set -- ${_sem_ver//./ }
    else
        _sem_ver="$(printf -- '%s\n' "${_sem_ver}" | sed 's/[^0-9.]//g')"
        # shellcheck disable=SC2046
        set -- $(printf -- '%s\n' "${_sem_ver}" | tr '.' ' ')
    fi

    printf -- '%d%02d%02d' "${1}" "${2:-0}" "${3:-0}"
}
