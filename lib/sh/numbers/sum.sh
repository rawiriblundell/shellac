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
# Provenance: https://raw.githubusercontent.com/rawiriblundell/dotfiles/master/.bashrc
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_numbers_sum+x}" ] && return 0
_SHELLAC_LOADED_numbers_sum=1

# @description Sum a sequence of integers from positional parameters or stdin.
#   Non-integer values are silently skipped.
#
# @arg $@ int Integers to sum, or pipe values via stdin
#
# @example
#   sum 1 2 3          # => 6
#   printf '%s\n' 1 2 3 | sum   # => 6
#
# @stdout Integer sum
# @exitcode 0 Always
sum() {
  local _param _total
  case "${1}" in
    (-h|--help|--usage)
      {
        printf -- '%s\n' "Usage: sum x y [..z], or pipeline | sum"
        printf -- '\t%s\n' \
          "sum a sequence of integers, input by either positional parameters or STDIN"
      } >&2
      return 0
    ;;
  esac
  if (( ${#} == 0 )) && [ ! -t 0 ]; then
    while read -r; do
      case "${REPLY}" in
        (*[!0-9]*) : ;;
        (*) _total=$(( _total + REPLY )) ;;
      esac
    done < "${1:-/dev/stdin}"
    printf -- '%d\n' "${_total}"
    return 0
  fi
  for _param in "${@}"; do
    case "${_param}" in
      (*[!0-9]*) : ;;
      (*) _total=$(( _total + _param )) ;;
    esac
  done
  printf -- '%d\n' "${_total}"
}

# @description Compute the arithmetic mean of numbers from stdin, a file, or positional parameters.
#   With no arguments reads from stdin. With one argument that is a readable file, averages its lines.
#   Otherwise averages the supplied parameters.
#
# @arg $@ number Optional numbers to average, or a single file path
#
# @stdout The average value
# @exitcode 0 Always
average() {
  case "${#}" in
    (0)
      awk '{ total += $1; count++ } END { print total/count }'
    ;;
    (1)
      if [ -r "${1}" ]; then
        awk '{ total += $1; count++ } END { print total/count }' "${1}"
      else
        printf -- '%s\n' "${1}"
      fi
    ;;
    (*)
      printf -- '%s\n' "${@}" | awk '{ total += $1; count++ } END { print total/count }'
    ;;
  esac
}
