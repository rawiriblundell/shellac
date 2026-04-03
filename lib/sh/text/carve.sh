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

[ -n "${_SHELLAC_LOADED_text_carve+x}" ] && return 0
_SHELLAC_LOADED_text_carve=1

# @description Extract a substring between two delimiters by ordinal position.
#   Reads from stdin. Specify positions using short ordinals ('1st', '2nd', 'first', 'last')
#   and delimiters.
#
# @arg $@ string Parsing expression in the form: ORDINAL DELIM1 to ORDINAL DELIM2
#
# @example
#   printf '%s\n' "a/b:c/d:e" | carve 2nd '/' to 3rd ':'
#
# @stdout Carved substring
# @exitcode 0 Always
carve() {
  local _count1 _count2 _delim1 _delim2 _line _i
  read -r _count1 _delim1 _ _count2 _delim2 <<< "${@}"
  case "${_count1}" in
    ([0-9]*) _count1="${_count1//[!0-9]/}" ;;
    (first)  _count1="1" ;;
    (last)   _count1="last" ;;
    (''|*)
      printf -- '%s\n' \
        "Usage: carve SHORT_ORDINAL DELIM1 to SHORT_ORDINAL DELIM2" \
        "Example: carve 2nd '/' to 3rd ':'" \
        "'first' or 'last' can also be used in the short ordinal fields" >&2
    ;;
  esac
  case "${_count2}" in
    ([0-9]*) _count2="${_count2//[!0-9]/}" ;;
    (first)  _count2="1" ;;
    (last)   _count2="last" ;;
  esac
  while IFS= read -r; do
    case "${_count1}" in
      (first) _line="${REPLY#*${_delim1}}" ;;
      (last)  _line="${REPLY##*${_delim1}}" ;;
      (*)
        for (( _i=0; _i<_count1; _i++ )); do
          (( _i == 0 )) && _line="${REPLY#*${_delim1}}"
          (( _i >= 1 )) && _line="${_line#*${_delim1}}"
        done
      ;;
    esac
    case "${_count2}" in
      (first) _line="${_line%%${_delim2}*}" ;;
      (last)  _line="${_line%${_delim2}*}" ;;
      (*)
        for (( _i=0; _i<_count2; _i++ )); do
          _line="${_line%%${_delim2}*}"
        done
      ;;
    esac
    printf -- '%s\n' "${_line}"
  done
}
