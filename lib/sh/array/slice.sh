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

[ -n "${_SHELLAC_LOADED_array_slice+x}" ] && return 0
_SHELLAC_LOADED_array_slice=1
requires BASH43

# @description Print a slice of array elements using Python-style index notation.
#   Supports single index, range, and step variants.
#
# @arg $1 string Slice specifier: n, :n, ::n, x:y, or x:y:z
# @arg $2 string Name of the array variable (passed by name, not value).
#
# @example
#   array_slice 2 myarr        # prints element at index 2
#   array_slice :3 myarr       # prints elements at indices 0, 1, 2
#   array_slice ::2 myarr      # prints every 2nd element from index 0
#   array_slice 1:4 myarr      # prints elements at indices 1, 2, 3
#   array_slice 0:6:2 myarr    # prints every 2nd element between indices 0 and 6
#
# @stdout Matching elements, one per line.
# @exitcode 0 Always
array_slice() {
  local _slice_mode _slice_start _slice_end _slice_incr
  _slice_mode=''
  until (( "${#_slice_mode}" > 0 )); do
    if printf -- '%s\n' "${1}" | grep -E -- "^-?[0-9]+$" >/dev/null 2>&1; then
      _slice_mode="single"
      break
    fi
    if printf -- '%s\n' "${1}" | grep -E -- "^:-?[0-9]+$" >/dev/null 2>&1; then
      _slice_mode="inclusive"
      break
    fi
    if printf -- '%s\n' "${1}" | grep -E -- "^::-?[0-9]+$" >/dev/null 2>&1; then
      _slice_mode="inclusive_increment"
      break
    fi
    if printf -- '%s\n' "${1}" | grep -E -- "^-?[0-9]+:-?[0-9]+$" >/dev/null 2>&1; then
      _slice_mode="range"
      break
    fi
    if printf -- '%s\n' "${1}" | grep -E -- "^-?[0-9]+:-?[0-9]+:-?[0-9]+$" >/dev/null 2>&1; then
      _slice_mode="increment"
      break
    fi
    # If there's no matches, we dump the whole array.  Should probably error out instead...
    _slice_mode="all"
  done

  # Nameref into the caller's array — no eval needed (requires bash 4.3+,
  # which is already assumed by the rest of this file's use of local -n).
  local -n _slice_ref="${2:?No array name given}"

  case "${_slice_mode}" in
    (single)
      printf -- '%s\n' "${_slice_ref[$1]}"
    ;;
    (inclusive)
      for (( i=0; i<"${1/:/}"; i++ )); do
        printf -- '%s\n' "${_slice_ref[i]}"
      done
    ;;
    (range)
      _slice_start="${1%:*}"
      _slice_end="${1#*:}"
      for (( i=_slice_start; i<_slice_end; i++ )); do
        printf -- '%s\n' "${_slice_ref[i]}"
      done
    ;;
    (inclusive_increment)
      _slice_incr="${1/::/}"
      i=0
      while (( i < "${#_slice_ref[@]}" )); do
        printf -- '%s\n' "${_slice_ref[i]}"
        i=$(( i + _slice_incr ))
      done
    ;;
    (increment)
      _slice_var1="${1%:*}"
      _slice_var2="${1#*:}"
      i="${_slice_var1%:*}"
      _slice_end="${_slice_var1#*:}"
      _slice_incr="${_slice_var2#*:}"
      while (( i <= _slice_end )); do
        printf -- '%s\n' "${_slice_ref[i]}"
        i=$(( i + _slice_incr ))
      done
    ;;
    (all)
      printf -- '%s\n' "${_slice_ref[@]}"
    ;;
  esac
}

# @description Print the element at index n in a named array.
#   Supports negative indices (from end). Pass --random to select a random element.
#
# @arg $1 string Name of the array variable.
# @arg $2 string Index (supports negative), or --random for a random element.
#
# @example
#   myarr=( a b c d e )
#   array_at myarr -1     # => e
#   array_at myarr --random  # => (random element)
#
# @stdout The element at the given index.
# @exitcode 0 Always
array_at() {
  local -n _arr="${1:?No array name given}"
  local _idx
  case "${2:?No index given}" in
    (--random) (( _idx = RANDOM % ${#_arr[@]} )) ;;
    (*)        _idx="${2}" ;;
  esac
  printf -- '%s\n' "${_arr[${_idx}]}"
}

# @description Print the first n elements of a named array.
#
# @arg $1 string Name of the array variable.
# @arg $2 int Number of elements to print from the start (default: 1).
#
# @stdout The first n elements, one per line.
# @exitcode 0 Always
array_head() {
  local -n _arr="${1:?No array name given}"
  local _n _i
  _n="${2:-1}"
  for (( _i = 0; _i < _n && _i < ${#_arr[@]}; _i++ )); do
    printf -- '%s\n' "${_arr[_i]}"
  done
}

# @description Print the last n elements of a named array.
#
# @arg $1 string Name of the array variable.
# @arg $2 int Number of elements to print from the end (default: 1).
#
# @stdout The last n elements, one per line.
# @exitcode 0 Always
array_tail() {
  local -n _arr="${1:?No array name given}"
  local _n _start _i
  _n="${2:-1}"
  (( _start = ${#_arr[@]} - _n ))
  (( _start < 0 )) && _start=0
  for (( _i = _start; _i < ${#_arr[@]}; _i++ )); do
    printf -- '%s\n' "${_arr[_i]}"
  done
}
