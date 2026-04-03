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

[ -n "${_SHELLAC_LOADED_text_substr+x}" ] && return 0
_SHELLAC_LOADED_text_substr=1

# @description Return the portion of a string before the first occurrence
#   of a delimiter. If the delimiter is not found, the whole string is returned.
#
# @arg $1 string The string to process
# @arg $2 string The delimiter to search for
#
# @example
#   str_before "foo:bar:baz" ":"   # => foo
#   str_before "foobar" ":"        # => foobar
#
# @stdout Substring before the first delimiter
# @exitcode 0 Always
str_before() {
  local _str _delim
  _str="${1:?No string given}"
  _delim="${2:?No delimiter given}"
  printf -- '%s\n' "${_str%%"${_delim}"*}"
}

# @description Return the portion of a string after the first occurrence
#   of a delimiter. If the delimiter is not found, an empty string is returned.
#
# @arg $1 string The string to process
# @arg $2 string The delimiter to search for
#
# @example
#   str_after "foo:bar:baz" ":"   # => bar:baz
#   str_after "foobar" ":"        # => (empty)
#
# @stdout Substring after the first delimiter
# @exitcode 0 Always
str_after() {
  local _str _delim
  _str="${1:?No string given}"
  _delim="${2:?No delimiter given}"
  printf -- '%s\n' "${_str#*"${_delim}"}"
}

# @description Extract a substring by zero-based start index and optional length.
#   Wraps bash's ${string:start:length} parameter expansion.
#
# @arg $1 string The string to extract from
# @arg $2 int    Zero-based start index (negative counts from end)
# @arg $3 int    Optional: number of characters to extract
#
# @example
#   str_substr "hello world" 6       # => world
#   str_substr "hello world" 0 5     # => hello
#   str_substr "hello world" -5      # => world
#
# @stdout Extracted substring
# @exitcode 0 Always
str_substr() {
  local _str _start _length
  _str="${1:?No string given}"
  _start="${2:?No start index given}"
  _length="${3}"
  if [[ -n "${_length}" ]]; then
    printf -- '%s\n' "${_str:${_start}:${_length}}"
  else
    printf -- '%s\n' "${_str:${_start}}"
  fi
}

# @description Remove characters from the start or end of a string.
#
# @arg $1 string The string to process
# @arg $2 int    Number of characters to remove
# @arg $3 string Optional: 'start' (default) or 'end'
#
# @example
#   str_cut "foobar" 3         # => bar
#   str_cut "foobar" 3 end     # => foo
#   str_cut "foobar" 2 start   # => obar
#
# @stdout String with characters removed
# @exitcode 0 Always
# @exitcode 1 Unknown direction argument
str_cut() {
  local _str _n _from
  _str="${1:?No string given}"
  _n="${2:?No count given}"
  _from="${3:-start}"
  case "${_from}" in
    (start)
      printf -- '%s\n' "${_str:${_n}}"
    ;;
    (end)
      printf -- '%s\n' "${_str:0:$(( ${#_str} - _n ))}"
    ;;
    (*)
      printf -- '%s\n' "str_cut: unknown direction '${_from}' (use 'start' or 'end')" >&2
      return 1
    ;;
  esac
}
