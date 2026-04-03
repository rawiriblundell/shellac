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

[ -n "${_SHELLAC_LOADED_text_split+x}" ] && return 0
_SHELLAC_LOADED_text_split=1

# @description Split a string on a delimiter and store the result in the STR_SPLIT array.
#   Defaults to whitespace splitting when no delimiter is given.
#   Uses portable read loop instead of readarray/mapfile.
#
# @arg $1 string Optional: -d|--delimiter followed by delimiter character
# @arg $@ string The string to split
#
# @exitcode 0 Always
str_split() {
  local _str_split_delim _str_split_counter

  STR_SPLIT=()
  case "${1}" in
    (-d|--delimiter)
      _str_split_delim="${2}"
      shift 2
      _str_split_counter=0
      while read -r _str_split_line; do
        STR_SPLIT[$_str_split_counter]="${_str_split_line}"
        _str_split_counter=$(( _str_split_counter + 1 ))
      done < <(printf -- '%s\n' "${*}" | tr "${_str_split_delim}" "\n")
    ;;
    (*) STR_SPLIT=( "${@}" ) ;;
  esac
}
