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

[ -n "${_SHELLAC_LOADED_array_join+x}" ] && return 0
_SHELLAC_LOADED_array_join=1
requires BASH43

# @description Split a string on a delimiter into a named array.
#   The delimiter must be a single character.
#
# @arg $1 string Name of the array variable.
# @arg $2 string Single-character delimiter.
# @arg $3 string The string to split.
#
# @example
#   array_split myarr , "a,b,c,d"
#   printf '%s\n' "${myarr[@]}"
#   # => a
#   # => b
#   # => c
#   # => d
#
# @exitcode 0 Always
array_split() {
  local -n _arr="${1:?No array name given}"
  local _delim
  local _str
  _delim="${2:?No delimiter given}"
  _str="${3:?No string given}"
  IFS="${_delim}" read -ra _arr <<< "${_str}"
}

# @description Join array elements with a delimiter and output a single string.
#
# @arg $1 string The delimiter string.
# @arg $@ string Elements to join, passed by value.
#
# @example
#   array_join '|' a b c d
#   # => a|b|c|d
#   array_join '||||' a b c d
#   # => a||||b||||c||||d
#   testarray=( a 'b c' d e )
#   array_join ',' "${testarray[@]}"
#   # => a,b c,d,e
#
# @stdout The joined string.
# @exitcode 0 Success
# @exitcode 1 No arguments given.
array_join() {
  ((${#})) || return 1
  local -- delim="${1}" str IFS=
  shift 1
  # Flatten the rest to a string, with our delimiter in front of every element
  # e.g ,a,b,c,d
  str="${*/#/${delim}}"
  # Print the string, stripping the leading delimiter
  # e.g. a,b,c,d
  printf -- '%s\n' "${str:${#delim}}"
}
