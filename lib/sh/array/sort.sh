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

[ -n "${_SHELLAC_LOADED_array_sort+x}" ] && return 0
_SHELLAC_LOADED_array_sort=1

# @description Sort a named array in place using lexicographic order.
#
# @arg $1 string Name of the array variable.
#
# @example
#   myarr=( banana apple cherry )
#   array_sort myarr
#   printf '%s\n' "${myarr[@]}"
#   # => apple
#   # => banana
#   # => cherry
#
# @exitcode 0 Always
array_sort() {
  local -n _arr="${1:?No array name given}"
  local -a _sorted
  readarray -t _sorted < <(printf -- '%s\n' "${_arr[@]}" | sort)
  _arr=( "${_sorted[@]}" )
}

# @description Sort a named array in place using numeric order.
#
# @arg $1 string Name of the array variable.
#
# @exitcode 0 Always
array_sort_numeric() {
  local -n _arr="${1:?No array name given}"
  local -a _sorted
  readarray -t _sorted < <(printf -- '%s\n' "${_arr[@]}" | sort -n)
  _arr=( "${_sorted[@]}" )
}

# @description Sort a named array in place using natural (version) order.
#   Numbers embedded in strings are compared numerically, so file2 sorts
#   before file10 and v1.9 sorts before v1.10.
#   Requires GNU coreutils sort -V. If unavailable, falls back to standard
#   lexicographic sort and prints a warning to stderr.
#
# @arg $1 string Name of the array variable.
#
# @example
#   files=( file10.txt file2.txt file1.txt )
#   array_sort_natural files
#   printf '%s\n' "${files[@]}"
#   # => file1.txt
#   # => file2.txt
#   # => file10.txt
#
# @exitcode 0 Always
array_sort_natural() {
  local -n _arr="${1:?No array name given}"
  local -a _sorted
  if sort -V /dev/null 2>/dev/null; then
    readarray -t _sorted < <(printf -- '%s\n' "${_arr[@]}" | sort -V)
  else
    printf -- '%s\n' "array_sort_natural: sort -V unavailable, falling back to lexicographic sort" >&2
    readarray -t _sorted < <(printf -- '%s\n' "${_arr[@]}" | sort)
  fi
  _arr=( "${_sorted[@]}" )
}

# @description Reverse the order of elements in a named array in place.
#
# @arg $1 string Name of the array variable.
#
# @example
#   myarr=( a b c d e )
#   array_reverse myarr
#   printf '%s\n' "${myarr[@]}"
#   # => e
#   # => d
#   # => c
#   # => b
#   # => a
#
# @exitcode 0 Always
array_reverse() {
  local -n _arr="${1:?No array name given}"
  local _i _j _tmp
  _i=0
  _j=$(( ${#_arr[@]} - 1 ))
  while (( _i < _j )); do
    _tmp="${_arr[_i]}"
    _arr[_i]="${_arr[_j]}"
    _arr[_j]="${_tmp}"
    (( _i++ ))
    (( _j-- ))
  done
}

# @description Shuffle a named array in place using the Fisher-Yates algorithm.
#
# @arg $1 string Name of the array variable.
#
# @exitcode 0 Always
array_shuffle() {
  local -n _arr="${1:?No array name given}"
  local _i _j _tmp _len
  _len="${#_arr[@]}"
  for (( _i = _len - 1; _i > 0; _i-- )); do
    (( _j = RANDOM % (_i + 1) ))
    _tmp="${_arr[_i]}"
    _arr[_i]="${_arr[_j]}"
    _arr[_j]="${_tmp}"
  done
}
