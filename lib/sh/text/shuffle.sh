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

[ -n "${_SHELLAC_LOADED_text_shuffle+x}" ] && return 0
_SHELLAC_LOADED_text_shuffle=1

# @description Randomise the characters within each word of the input using a
#   Knuth-Fisher-Yates shuffle. Single-character words are passed through unchanged.
#   Note: Does not produce cryptographically secure output.
#
# @arg $@ string One or more words to shuffle
#
# @stdout Space-separated shuffled words followed by a newline
# @exitcode 0 Success
# @exitcode 1 Required dependencies (fold, paste, RANDOM) not found
str_shuffle() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    local _shuffle_input
    IFS= read -r _shuffle_input
    # shellcheck disable=SC2086
    set -- ${_shuffle_input}
  fi
  local _str_shuffle_missing _str_shuffle_dep
  local _str_shuffle_chars _str_shuffle_charcount _str_shuffle_randmax
  local _str_shuffle_chartmp _word _shuffled_word _rand _i
  # Ensure that our dependencies are present
  for _str_shuffle_dep in fold paste; do
    if ! command -v "${_str_shuffle_dep}" >/dev/null 2>&1; then
      _str_shuffle_missing="${_str_shuffle_missing},${_str_shuffle_dep}"
    fi
  done
  # We require RANDOM, any shell that we come across should have it
  # But we check for it, just in case...
  if (( "${RANDOM:-1}${RANDOM:-1}" == "${RANDOM:-1}${RANDOM:-1}" )); then
    _str_shuffle_missing="${_str_shuffle_missing},RANDOM shell function"
  fi
  if (( "${#_str_shuffle_missing}" > 0 )); then
    printf -- 'str_shuffle: %s\n' "The following requirements were not found in PATH" >&2
    printf -- '%s\n' "${_str_shuffle_missing/,/}" >&2
    return 1
  fi

  for _word in "${@}"; do
    case "${#_word}" in
      (1)
        # Don't go to the bother of shuffling single-char words like 'a'
        printf -- '%s ' "${_word}"
      ;;
      (*)
        # Initialise an array of all the characters from the word and get the array size
        # shellcheck disable=SC2207
        _str_shuffle_chars=( $(printf -- '%s' "${_word}" | fold -w 1 | paste -sd ' ') )
        _str_shuffle_charcount="${#_str_shuffle_chars[@]}"
        # $RANDOM % (i+1) is biased because of the limited range of $RANDOM
        # We compensate by using a range which is a multiple of the array size.
        _str_shuffle_randmax=$(( 32768 / _str_shuffle_charcount * _str_shuffle_charcount ))

        for (( _i=_str_shuffle_charcount-1; _i>0; _i-- )); do
          # Get a random modulo-able number within our range, then modulo it
          # shellcheck disable=SC2004
          while (( (_rand=${RANDOM}) >= _str_shuffle_randmax )); do :; done
          _rand=$(( _rand % (_i+1) ))

          # Swap the _i'th element with the _rand element
          _str_shuffle_chartmp="${_str_shuffle_chars[_i]}"
          _str_shuffle_chars[_i]="${_str_shuffle_chars[_rand]}"
          _str_shuffle_chars[_rand]="${_str_shuffle_chartmp}"
        done
        # Convert the array back to a string and strip out the spaces
        # This gives us our shuffled word, which we print out
        _shuffled_word="${_str_shuffle_chars[*]}"
        _shuffled_word="${_shuffled_word// /}"
        printf -- '%s ' "${_shuffled_word}"
      ;;
    esac
  done
  printf -- '%s\n' ""
}
