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
# Provenance: https://github.com/rawiriblundell/shellac
# SPDX-License-Identifier: Apache-2.0
# Adapted from hastec-fr/apash (Apache-2.0) https://github.com/hastec-fr/apash

[ -n "${_SHELLAC_LOADED_text_rotate+x}" ] && return 0
_SHELLAC_LOADED_text_rotate=1

# @description Circular-shift a string by N character positions.
#   Positive N shifts right (tail wraps to front); negative N shifts left.
#   A shift of 0 or a magnitude equal to string length is a no-op.
#   Note: rot13 is a specific case of str_rotate with N=13 over the alphabet;
#   str_rotate works on the full string character positions.
#
# @arg $1 string String to rotate
# @arg $2 int   Number of positions to shift (default: 0; negative = left shift)
#
# @example
#   str_rotate "abcdefg"  2    # => "fgabcde"
#   str_rotate "abcdefg" -2    # => "cdefgab"
#   str_rotate "abcdefg"  7    # => "abcdefg"
#
# @stdout Rotated string
# @exitcode 0 Always; 1 Non-integer shift value
str_rotate() {
  local str n len idx
  str="${1:-}"
  n="${2:-0}"
  [[ -z "${n}" ]] && n=0
  if ! printf -- '%d' "${n}" >/dev/null 2>&1; then
    printf -- '%s\n' "str_rotate: shift must be an integer" >&2
    return 1
  fi
  len="${#str}"
  (( len == 0 )) && return 0
  n=$(( n % len ))
  (( n < 0 )) && n=$(( n + len ))
  if (( n == 0 )); then
    printf -- '%s\n' "${str}"
  else
    idx=$(( len - n ))
    printf -- '%s\n' "${str:${idx}}${str:0:${idx}}"
  fi
}
