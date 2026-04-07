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

[ -n "${_SHELLAC_LOADED_array_set+x}" ] && return 0
_SHELLAC_LOADED_array_set=1
requires BASH43

# @description Print elements present in arr_a but not in arr_b.
#
# @arg $1 string Name of the first array variable.
# @arg $2 string Name of the second array variable.
#
# @example
#   arr1=( a b c d )
#   arr2=( b d e )
#   array_diff arr1 arr2
#   # => a
#   # => c
#
# @stdout Elements from arr_a not in arr_b, one per line.
# @exitcode 0 Always
array_diff() {
  local -n _arr_a="${1:?No first array name given}"
  local -n _arr_b="${2:?No second array name given}"
  local -A _seen
  local _item
  _seen=()
  for _item in "${_arr_b[@]}"; do
    _seen["${_item}"]=1
  done
  for _item in "${_arr_a[@]}"; do
    [[ -z "${_seen[${_item}]+x}" ]] && printf -- '%s\n' "${_item}"
  done
  return 0
}

# @description Print elements present in both arr_a and arr_b.
#
# @arg $1 string Name of the first array variable.
# @arg $2 string Name of the second array variable.
#
# @example
#   arr1=( a b c d )
#   arr2=( b d e )
#   array_intersect arr1 arr2
#   # => b
#   # => d
#
# @stdout Elements common to both arrays, one per line.
# @exitcode 0 Always
array_intersect() {
  local -n _arr_a="${1:?No first array name given}"
  local -n _arr_b="${2:?No second array name given}"
  local -A _seen
  local _item
  _seen=()
  for _item in "${_arr_b[@]}"; do
    _seen["${_item}"]=1
  done
  for _item in "${_arr_a[@]}"; do
    [[ -n "${_seen[${_item}]+x}" ]] && printf -- '%s\n' "${_item}"
  done
  return 0
}

# @description Print all unique elements from both arrays (set union).
#
# @arg $1 string Name of the first array variable.
# @arg $2 string Name of the second array variable.
#
# @example
#   arr1=( a b c )
#   arr2=( b c d e )
#   array_union arr1 arr2
#   # => a
#   # => b
#   # => c
#   # => d
#   # => e
#
# @stdout All unique elements from both arrays, one per line.
# @exitcode 0 Always
array_union() {
  local -n _arr_a="${1:?No first array name given}"
  local -n _arr_b="${2:?No second array name given}"
  local -A _seen
  local _item
  _seen=()
  for _item in "${_arr_a[@]}" "${_arr_b[@]}"; do
    if [[ -z "${_seen[${_item}]+x}" ]]; then
      _seen["${_item}"]=1
      printf -- '%s\n' "${_item}"
    fi
  done
}

# @description Remove duplicate elements from a named array in place, preserving order.
#
# @arg $1 string Name of the array variable.
#
# @example
#   myarr=( a b a c b d )
#   array_unique myarr
#   printf '%s\n' "${myarr[@]}"
#   # => a
#   # => b
#   # => c
#   # => d
#
# @exitcode 0 Always
array_unique() {
  local -n _arr="${1:?No array name given}"
  local -A _seen
  local -a _new_arr
  local _item
  _seen=()
  _new_arr=()
  for _item in "${_arr[@]}"; do
    if [[ -z "${_seen[${_item}]+x}" ]]; then
      _seen["${_item}"]=1
      _new_arr+=( "${_item}" )
    fi
  done
  _arr=( "${_new_arr[@]}" )
}
