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

[ -n "${_SHELLAC_LOADED_text_transform+x}" ] && return 0
_SHELLAC_LOADED_text_transform=1

# @description Collapse consecutive repeated characters into a single
#   occurrence. Defaults to squeezing spaces.
#
# @arg $1 string The string to process
# @arg $2 string Optional: character(s) to squeeze (default: space)
#
# @example
#   str_squeeze "hello   world"      # => hello world
#   str_squeeze "aabbccdd" "a-c"     # => abcdd
#
# @stdout String with repeated characters collapsed
# @exitcode 0 Always
str_squeeze() {
  local _str _char
  _str="${1:?No string given}"
  _char="${2:- }"
  printf -- '%s\n' "${_str}" | tr -s "${_char}"
}

# @description Delete all occurrences of specified characters from a string.
#
# @arg $1 string The string to process
# @arg $2 string Characters (or ranges) to delete, as accepted by tr -d
#
# @example
#   str_delete "hello world" "lo"   # => he wrd
#   str_delete "abc123" "0-9"       # => abc
#
# @stdout String with specified characters removed
# @exitcode 0 Always
str_delete() {
  local _str _chars
  _str="${1:?No string given}"
  _chars="${2:?No chars given}"
  printf -- '%s\n' "${_str}" | tr -d "${_chars}"
}

# @description Reverse the characters of a string.
#
# @arg $@ string The string to reverse
#
# @example
#   str_reverse "hello"         # => olleh
#   str_reverse "hello world"   # => dlrow olleh
#
# @stdout Reversed string
# @exitcode 0 Always
str_reverse() {
  local _input _reversed _i
  _input="${*}"
  _reversed=""
  for (( _i = ${#_input} - 1; _i >= 0; _i-- )); do
    _reversed+="${_input:_i:1}"
  done
  printf -- '%s\n' "${_reversed}"
}

# @description Truncate a string to a maximum length, appending an ellipsis
#   (or custom suffix) when truncation occurs. The total output length
#   (including suffix) will not exceed the specified maximum.
#
# @arg $1 string The string to abbreviate
# @arg $2 int    Maximum total length in characters
# @arg $3 string Optional: suffix to append when truncating (default: '...')
#
# @example
#   str_abbreviate "hello world" 8         # => hello...
#   str_abbreviate "hi" 10                 # => hi
#   str_abbreviate "hello world" 8 "…"    # => hello w…
#
# @stdout Abbreviated string
# @exitcode 0 Always
str_abbreviate() {
  local _str _len _suffix
  _str="${1:?No string given}"
  _len="${2:?No length given}"
  _suffix="${3:-...}"
  if (( ${#_str} > _len )); then
    printf -- '%s\n' "${_str:0:$(( _len - ${#_suffix} ))}${_suffix}"
  else
    printf -- '%s\n' "${_str}"
  fi
}

# @description Expand tab characters to spaces. Requires the expand command.
#
# @arg $1 string The string to process
# @arg $2 int    Optional: tab stop width (default: 8)
#
# @example
#   str_expand_tabs $'col1\tcol2'      # => col1    col2
#   str_expand_tabs $'a\tb' 4          # => a   b
#
# @stdout String with tabs replaced by spaces
# @exitcode 0 Always
str_expand_tabs() {
  local _str _tabsize
  _str="${1:?No string given}"
  _tabsize="${2:-8}"
  printf -- '%s\n' "${_str}" | expand -t "${_tabsize}"
}

# @description Split a string into chunks of a given size, printing each
#   chunk on a separate line.
#
# @arg $1 string The string to chunk
# @arg $2 int    Characters per chunk
#
# @example
#   str_chunk "abcdefgh" 3   # => abc
#                            #    def
#                            #    gh
#
# @stdout One chunk per line
# @exitcode 0 Always
str_chunk() {
  local _str _size _i
  _str="${1:?No string given}"
  _size="${2:?No chunk size given}"
  for (( _i = 0; _i < ${#_str}; _i += _size )); do
    printf -- '%s\n' "${_str:_i:_size}"
  done
}

# @description Split a string on a delimiter and return one or more fields.
#   Field numbering is 1-based. If no fields are specified, all fields are
#   printed, one per line.
#
# @arg $1 string The string to split
# @arg $2 string The delimiter character
# @arg $@ int    Optional: one or more 1-based field numbers to extract
#
# @example
#   str_fields "a:b:c" ":"       # => a
#                                #    b
#                                #    c
#   str_fields "a:b:c" ":" 2     # => b
#   str_fields "a:b:c" ":" 1 3   # => a
#                                #    c
#
# @stdout One field per line
# @exitcode 0 Always
str_fields() {
  local _str _delim _field
  _str="${1:?No string given}"
  _delim="${2:?No delimiter given}"
  shift 2
  local -a _parts
  IFS="${_delim}" read -r -a _parts <<< "${_str}"
  if (( ${#} == 0 )); then
    printf -- '%s\n' "${_parts[@]}"
  else
    for _field in "${@}"; do
      printf -- '%s\n' "${_parts[$(( _field - 1 ))]}"
    done
  fi
}

# @description Remove trailing newlines from a string and print the result.
#
# @arg $@ string The input string
#
# @stdout Input string with trailing newline stripped
# @exitcode 0 Always
str_chomp() {
  local _chomp_str
  _chomp_str="${*}"
  _chomp_str="${_chomp_str%$'\n'}"
  printf -- '%s\n' "${_chomp_str}"
}

# @description Alias for str_chomp.
chomp() {
  str_chomp "${@}"
}

# @description Remove the last n characters from a string.
#   Defaults to removing 1 character (Perl chop semantics).
#
# @arg $1 string Optional: -n followed by count of characters to remove
# @arg $@ string The input string
#
# @example
#   str_chop "hello,"        # => hello
#   str_chop -n 3 "hello..."  # => hello
#
# @stdout Input string with last n characters removed
# @exitcode 0 Always
str_chop() {
  local _n _input
  _n=1
  case "${1}" in
    (-n) _n="${2:?str_chop -n requires a count}"; shift 2 ;;
  esac
  _input="${*}"
  printf -- '%s\n' "${_input:0:$(( ${#_input} - _n ))}"
}

# @description Alias for str_chop.
chop() {
  str_chop "${@}"
}
