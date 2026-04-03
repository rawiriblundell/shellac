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

[ -n "${_SHELLAC_LOADED_text_len+x}" ] && return 0
_SHELLAC_LOADED_text_len=1

# @description Return the character length of a string, file, or piped input.
#   With -b/--bytes, returns the byte length instead of character length.
#   With a file argument, prints length and content for each line.
#   With no arguments and no stdin, prints 0.
#
# @arg $1 string Optional: -b|--bytes for byte length, or a string/file path
#
# @stdout Length (and optionally content) of the input
# @exitcode 0 Always
str_len() {
  local str
  case "${1}" in
    (-b|--bytes)
      shift 1
      local _lang_orig _lc_all_orig
      _lang_orig="${LANG}"
      _lc_all_orig="${LC_ALL}"
      LANG=C
      LC_ALL=C
      str="${*}"
      printf -- '%d\n' "${#str}"
      LANG="${_lang_orig}"
      LC_ALL="${_lc_all_orig}"
    ;;
    ('')
      # No argument at all: check for piped input or return 0
      if (( $# == 0 )) && [[ ! -t 0 ]]; then
        while read -r; do
          printf -- '%s\n' "${#REPLY} ${REPLY}"
        done
      elif (( $# == 0 )); then
        # No arguments and no stdin: length of nothing is 0
        printf -- '%d\n' "0"
      else
        # Explicit empty string argument
        printf -- '%d\n' "0"
      fi
    ;;
    (*)
      # If the param is a readable file, we output a length for each line
      # Otherwise we treat the whole input as a string
      if [ -f "${1}" ] && [ -r "${1}" ]; then
        awk '{ print length, $0 }' "${1}"
      else
      str="${*}"
      printf -- '%d\n' "${#str}"
      fi
    ;;
  esac
}

# @description Alias for str_len.
strlen() {
  str_len "${@}"
}

# @description Alias for str_len.
len() {
  str_len "${@}"
}

# @description Count the number of non-overlapping occurrences of a substring
#   within a string.
#
# @arg $1 string The string to search within
# @arg $2 string The substring to count
#
# @example
#   str_count "banana" "an"   # => 2
#   str_count "hello" "l"     # => 2
#
# @stdout Integer count of occurrences
# @exitcode 0 Always
str_count() {
  local _str _substr _stripped _count
  _str="${1:?No string given}"
  _substr="${2:?No substring given}"
  _stripped="${_str//"${_substr}"/}"
  _count=$(( (${#_str} - ${#_stripped}) / ${#_substr} ))
  printf -- '%d\n' "${_count}"
}

# @description Count the number of words in a string (split on whitespace).
#
# @arg $@ string The string to count words in
#
# @example
#   str_word_count "hello world foo"   # => 3
#   str_word_count "  spaced  out  "   # => 2
#
# @stdout Integer word count
# @exitcode 0 Always
str_word_count() {
  local _input
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  local -a _words
  # shellcheck disable=SC2206
  _words=( ${_input} )
  printf -- '%d\n' "${#_words[@]}"
}
