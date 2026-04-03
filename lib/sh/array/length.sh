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

[ -n "${_SHELLAC_LOADED_array_length+x}" ] && return 0
_SHELLAC_LOADED_array_length=1

# @description Print the number of elements in a named array.
#
# @arg $1 string Name of the array variable.
#
# @example
#   myarr=( a b c )
#   array_length myarr  # => 3
#
# @stdout The element count.
# @exitcode 0 Always
array_length() {
  local -n _arr="${1:?No array name given}"
  printf -- '%s\n' "${#_arr[@]}"
}

# @description Count occurrences of a value in a named array.
#
# @arg $1 string Name of the array variable.
# @arg $2 string The value to count.
#
# @example
#   myarr=( a b a c a )
#   array_count myarr a  # => 3
#
# @stdout The number of times the value appears.
# @exitcode 0 Always
array_count() {
  local -n _arr="${1:?No array name given}"
  local _elem _item _count
  _elem="${2:?No element given}"
  _count=0
  for _item in "${_arr[@]}"; do
    [[ "${_item}" = "${_elem}" ]] && (( _count++ ))
  done
  printf -- '%s\n' "${_count}"
}

# @description Print the indices of a named array.
#
# @arg $1 string Name of the array variable.
#
# @example
#   myarr=( a b c )
#   array_keys myarr
#   # => 0
#   # => 1
#   # => 2
#
# @stdout Each index on its own line.
# @exitcode 0 Always
array_keys() {
  local -n _arr="${1:?No array name given}"
  local _i
  for _i in "${!_arr[@]}"; do
    printf -- '%s\n' "${_i}"
  done
}

# @description Print index:value pairs for all elements in a named array.
#
# @arg $1 string Name of the array variable.
#
# @example
#   myarr=( a b c )
#   array_entries myarr
#   # => 0:a
#   # => 1:b
#   # => 2:c
#
# @stdout Each index:value pair on its own line.
# @exitcode 0 Always
array_entries() {
  local -n _arr="${1:?No array name given}"
  local _i
  for _i in "${!_arr[@]}"; do
    printf -- '%s:%s\n' "${_i}" "${_arr[${_i}]}"
  done
}

# @description Print an array's contents in "index: value" format.
#   Works for both indexed and associative arrays.
#   Requires bash 4.3+ for namerefs.
#
# @arg $1 string Name of the array variable.
#
# @example
#   declare -a fruits=( apple banana cherry )
#   array_print fruits
#   # 0: apple
#   # 1: banana
#   # 2: cherry
#
#   declare -A colours=( [red]="#ff0000" [blue]="#0000ff" )
#   array_print colours
#   # red: #ff0000
#   # blue: #0000ff
#
# @stdout "key: value" lines
# @exitcode 0 Always; 1 Missing argument
array_print() {
  local -n _ap_arr="${1:?array_print: missing array name argument}"
  local _key
  for _key in "${!_ap_arr[@]}"; do
    printf -- '%s: %s\n' "${_key}" "${_ap_arr[${_key}]}"
  done
}

# @description Return 0 if an associative array contains the given key.
#   Requires bash 4.3+ for namerefs.
#
# @arg $1 string Name of the associative array variable.
# @arg $2 string Key to test.
#
# @example
#   declare -A colours=( [red]="#ff0000" )
#   array_has_key colours red     # 0
#   array_has_key colours blue    # 1
#
# @exitcode 0 Key present; 1 Key absent; 2 Missing argument
array_has_key() {
  local -n _ahk_arr="${1:?array_has_key: missing array name argument}"
  local _key
  _key="${2:?array_has_key: missing key argument}"
  [[ -n "${_ahk_arr[${_key}]+x}" ]]
}
