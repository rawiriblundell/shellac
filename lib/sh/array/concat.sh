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

[ -n "${_SHELLAC_LOADED_array_concat+x}" ] && return 0
_SHELLAC_LOADED_array_concat=1
requires BASH43

# @description Copy a named array to another named array.
#
# @arg $1 string Name of the source array variable.
# @arg $2 string Name of the destination array variable.
#
# @example
#   myarr=( a b c )
#   array_copy myarr copy
#   printf '%s\n' "${copy[@]}"
#   # => a
#   # => b
#   # => c
#
# @exitcode 0 Always
array_copy() {
  local -n _src="${1:?No source array name given}"
  local -n _dst="${2:?No destination array name given}"
  _dst=( "${_src[@]}" )
}

# @description Concatenate one or more named arrays into a destination named array.
#
# @arg $1 string Name of the destination array variable.
# @arg $@ string Names of one or more source array variables to concatenate in.
#
# @example
#   arr1=( a b c )
#   arr2=( d e f )
#   array_concat arr1 arr2
#   printf '%s\n' "${arr1[@]}"
#   # => a
#   # => b
#   # => c
#   # => d
#   # => e
#   # => f
#
# @exitcode 0 Always
array_concat() {
  local -n _dst="${1:?No destination array name given}"
  local _src_name
  shift
  for _src_name in "${@}"; do
    local -n _src="${_src_name}"
    _dst+=( "${_src[@]}" )
    unset -n _src
  done
}

# @description Append one or more elements to a named array.
#
# @arg $1 string Name of the array variable.
# @arg $@ string One or more elements to append.
#
# @example
#   myarr=( a b c )
#   array_append myarr d e
#   printf '%s\n' "${myarr[@]}"
#   # => a b c d e
#
# @exitcode 0 Always
array_append() {
  local -n _arr="${1:?No array name given}"
  shift
  _arr+=( "${@}" )
}

# @description Prepend one or more elements to the front of a named array.
#
# @arg $1 string Name of the array variable.
# @arg $@ string One or more elements to prepend.
#
# @example
#   myarr=( c d e )
#   array_prepend myarr a b
#   printf '%s\n' "${myarr[@]}"
#   # => a b c d e
#
# @exitcode 0 Always
array_prepend() {
  local -n _arr="${1:?No array name given}"
  shift
  _arr=( "${@}" "${_arr[@]}" )
}

# @description Interleave elements from two arrays, pairing by index.
#   Stops at the shorter array's length.
#
# @arg $1 string Name of the first array variable.
# @arg $2 string Name of the second array variable.
#
# @example
#   keys=( a b c )
#   vals=( 1 2 3 )
#   array_zip keys vals
#   # => a 1
#   # => b 2
#   # => c 3
#
# @stdout Paired elements as space-separated lines.
# @exitcode 0 Always
array_zip() {
  local -n _arr_a="${1:?No first array name given}"
  local -n _arr_b="${2:?No second array name given}"
  local _i _len
  _len="${#_arr_a[@]}"
  (( ${#_arr_b[@]} < _len )) && _len="${#_arr_b[@]}"
  for (( _i = 0; _i < _len; _i++ )); do
    printf -- '%s %s\n' "${_arr_a[_i]}" "${_arr_b[_i]}"
  done
}
