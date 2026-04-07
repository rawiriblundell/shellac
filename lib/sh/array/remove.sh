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

[ -n "${_SHELLAC_LOADED_array_remove+x}" ] && return 0
_SHELLAC_LOADED_array_remove=1
requires BASH43

# @description Empty a named array in place.
#
# @arg $1 string Name of the array variable.
#
# @exitcode 0 Always
array_clear() {
  local -n _arr="${1:?No array name given}"
  _arr=()
}

# @description Remove all elements matching a value from a named array and reindex.
#
# @arg $1 string Name of the array variable.
# @arg $2 string The value to remove.
#
# @example
#   myarr=( a b c b d )
#   array_remove myarr b
#   printf '%s\n' "${myarr[@]}"
#   # => a
#   # => c
#   # => d
#
# @exitcode 0 Always
array_remove() {
  local -n _arr="${1:?No array name given}"
  local _elem
  local -a _new_arr
  local _item
  _elem="${2:?No element given}"
  _new_arr=()
  for _item in "${_arr[@]}"; do
    [[ "${_item}" = "${_elem}" ]] || _new_arr+=( "${_item}" )
  done
  _arr=( "${_new_arr[@]}" )
}

# @description Remove only the first element matching a value from a named array and reindex.
#
# @arg $1 string Name of the array variable.
# @arg $2 string The value whose first occurrence to remove.
#
# @example
#   myarr=( a b c b d )
#   array_remove_first myarr b
#   printf '%s\n' "${myarr[@]}"
#   # => a
#   # => c
#   # => b
#   # => d
#
# @exitcode 0 Always
array_remove_first() {
  local -n _arr="${1:?No array name given}"
  local _elem
  local -a _new_arr
  local _item _done
  _elem="${2:?No element given}"
  _new_arr=()
  _done=0
  for _item in "${_arr[@]}"; do
    if (( ! _done )) && [[ "${_item}" = "${_elem}" ]]; then
      _done=1
    else
      _new_arr+=( "${_item}" )
    fi
  done
  _arr=( "${_new_arr[@]}" )
}

# @description Remove and print the last element of a named array.
#
# @arg $1 string Name of the array variable.
#
# @example
#   myarr=( a b c )
#   array_pop myarr
#   # => c
#   printf '%s\n' "${myarr[@]}"
#   # => a
#   # => b
#
# @stdout The removed last element.
# @exitcode 0 Always
array_pop() {
  local -n _arr="${1:?No array name given}"
  local _last
  _last="${_arr[-1]}"
  printf -- '%s\n' "${_last}"
  _arr=( "${_arr[@]:0:$(( ${#_arr[@]} - 1 ))}" )
}

# @description Insert one or more elements into a named array at a given index.
#   Existing elements at and after the index are shifted right.
#
# @arg $1 string Name of the array variable.
# @arg $2 int Zero-based index at which to insert.
# @arg $@ string One or more elements to insert.
#
# @example
#   myarr=( a b d e )
#   array_insert myarr 2 c
#   printf '%s\n' "${myarr[@]}"
#   # => a
#   # => b
#   # => c
#   # => d
#   # => e
#
# @exitcode 0 Always
array_insert() {
  local -n _arr="${1:?No array name given}"
  local _idx
  local -a _new_arr
  _idx="${2:?No index given}"
  shift 2
  _new_arr=(
    "${_arr[@]:0:${_idx}}"
    "${@}"
    "${_arr[@]:${_idx}}"
  )
  _arr=( "${_new_arr[@]}" )
}

# @description Remove elements from a named array at a given position, optionally inserting replacements.
#   Prints the removed elements, one per line.
#
# @arg $1 string Name of the array variable.
# @arg $2 int    Start index (supports negative indices from end).
# @arg $3 int    Number of elements to delete (default: all remaining from start index).
# @arg $@ string Optional replacement elements to insert at the start position.
#
# @example
#   myarr=( a b c d e )
#   array_splice myarr 1 2
#   # => b
#   # => c
#   printf '%s\n' "${myarr[@]}"
#   # => a
#   # => d
#   # => e
#
# @stdout The removed elements, one per line.
# @exitcode 0 Always
array_splice() {
  local -n _arr="${1:?No array name given}"
  local _start _count _i
  local -a _removed _inserts _new_arr
  _start="${2:?No start index given}"
  _count="${3:-${#_arr[@]}}"
  _inserts=()
  (( $# > 3 )) && _inserts=( "${@:4}" )

  (( _start < 0 )) && (( _start = ${#_arr[@]} + _start ))
  (( _start < 0 )) && _start=0
  (( _start > ${#_arr[@]} )) && _start=${#_arr[@]}
  (( _count < 0 )) && _count=0
  (( _start + _count > ${#_arr[@]} )) && (( _count = ${#_arr[@]} - _start ))

  _removed=()
  for (( _i = _start; _i < _start + _count; _i++ )); do
    _removed+=( "${_arr[_i]}" )
  done

  _new_arr=(
    "${_arr[@]:0:${_start}}"
    "${_inserts[@]+"${_inserts[@]}"}"
    "${_arr[@]:$(( _start + _count ))}"
  )
  _arr=( "${_new_arr[@]}" )
  printf -- '%s\n' "${_removed[@]+"${_removed[@]}"}"
}
