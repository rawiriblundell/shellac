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
# Provenance: https://raw.githubusercontent.com/rawiriblundell/dotfiles/master/.bashrc
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_array_contains+x}" ] && return 0
_SHELLAC_LOADED_array_contains=1
requires BASH43

# Functions for searching and testing array membership

# @description Test if any element in the array matches a grep regex pattern.
#   Passes array elements by value (expand with "${arr[@]}").
#   For a nameref-based glob test, see array_some.
#   This function intentionally uses a subshell.
#
# @arg $1 string The grep regex pattern to search for.
# @arg $@ string Array elements passed by value.
#
# @example
#   array_grep '^foo' "${myarr[@]}"
#
# @exitcode 0 At least one element matched.
# @exitcode 1 No elements matched.
array_grep() (
  local _needle
  _needle="${1:?No search pattern provided}"
  shift 1
  printf -- '%s\n' "${@}" | grep "${_needle}" >/dev/null 2>&1
)

# @description Print the index of the first element that exactly matches a value.
#
# @arg $1 string Name of the array variable.
# @arg $2 string The value to search for.
#
# @example
#   myarr=( a b c )
#   array_index myarr b  # => 1
#
# @stdout The zero-based index of the first matching element.
# @exitcode 0 Element found.
# @exitcode 1 Element not found.
array_index() {
  local -n _arr="${1:?No array name given}"
  local _elem _i
  _elem="${2:?No element given}"
  for (( _i = 0; _i < ${#_arr[@]}; _i++ )); do
    if [[ "${_arr[_i]}" = "${_elem}" ]]; then
      printf -- '%s\n' "${_i}"
      return 0
    fi
  done
  return 1
}

# @description Return 0 if any element of a named array matches a glob pattern.
#
# @arg $1 string Name of the array variable.
# @arg $2 string Glob pattern to test against each element.
#
# @example
#   myarr=( apple banana cherry )
#   array_some myarr 'ban*'  # => 0
#
# @exitcode 0 At least one element matched.
# @exitcode 1 No elements matched.
array_some() {
  local -n _arr="${1:?No array name given}"
  local _pattern _item
  _pattern="${2:?No pattern given}"
  for _item in "${_arr[@]}"; do
    [[ "${_item}" = ${_pattern} ]] && return 0
  done
  return 1
}

# @description Return 0 if every element of a named array matches a glob pattern.
#
# @arg $1 string Name of the array variable.
# @arg $2 string Glob pattern that all elements must match.
#
# @example
#   myarr=( apple apricot avocado )
#   array_every myarr 'a*'  # => 0
#
# @exitcode 0 All elements matched.
# @exitcode 1 At least one element did not match.
array_every() {
  local -n _arr="${1:?No array name given}"
  local _pattern _item
  _pattern="${2:?No pattern given}"
  for _item in "${_arr[@]}"; do
    [[ "${_item}" = ${_pattern} ]] || return 1
  done
  return 0
}

# @description Print the last index of an element that exactly matches a value.
#
# @arg $1 string Name of the array variable.
# @arg $2 string The value to search for.
#
# @example
#   myarr=( a b c b d )
#   array_last_index myarr b  # => 3
#
# @stdout The zero-based index of the last matching element.
# @exitcode 0 Element found.
# @exitcode 1 Element not found.
array_last_index() {
  local -n _arr="${1:?No array name given}"
  local _elem _i _last
  _elem="${2:?No element given}"
  _last=-1
  for (( _i = 0; _i < ${#_arr[@]}; _i++ )); do
    [[ "${_arr[_i]}" = "${_elem}" ]] && _last="${_i}"
  done
  (( _last >= 0 )) || return 1
  printf -- '%s\n' "${_last}"
}

# @description Print the first element matching a glob pattern.
#
# @arg $1 string Name of the array variable.
# @arg $2 string Glob pattern to match against.
#
# @example
#   myarr=( apple banana cherry )
#   array_find myarr 'b*'  # => banana
#
# @stdout The first matching element.
# @exitcode 0 A match was found.
# @exitcode 1 No match found.
array_find() {
  local -n _arr="${1:?No array name given}"
  local _pattern _item
  _pattern="${2:?No pattern given}"
  for _item in "${_arr[@]}"; do
    if [[ "${_item}" = ${_pattern} ]]; then
      printf -- '%s\n' "${_item}"
      return 0
    fi
  done
  return 1
}

# @description Print the last element matching a glob pattern.
#
# @arg $1 string Name of the array variable.
# @arg $2 string Glob pattern to match against.
#
# @example
#   myarr=( apple banana cherry apricot )
#   array_find_last myarr 'a*'  # => apricot
#
# @stdout The last matching element.
# @exitcode 0 A match was found.
# @exitcode 1 No match found.
array_find_last() {
  local -n _arr="${1:?No array name given}"
  local _pattern _item _last _found
  _pattern="${2:?No pattern given}"
  _last=''
  _found=0
  for _item in "${_arr[@]}"; do
    if [[ "${_item}" = ${_pattern} ]]; then
      _last="${_item}"
      _found=1
    fi
  done
  (( _found )) || return 1
  printf -- '%s\n' "${_last}"
}


