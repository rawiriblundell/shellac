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

[ -n "${_SHELLAC_LOADED_text_chr+x}" ] && return 0
_SHELLAC_LOADED_text_chr=1

# @description Convert a decimal integer to its ASCII character.
#   Values below 32 are shifted up by 32; values above 126 are halved until in range.
#   See: https://www.ascii-code.com/
#
# @arg $1 int Decimal integer to convert
#
# @stdout The ASCII character corresponding to the integer
# @exitcode 0 Success
# @exitcode 1 Input is not an integer
chr() {
  local _int
  _int="${1:?No integer supplied}"
  # Ensure that we have an integer
  case "${_int}" in
    (*[!0-9]*) return 1 ;;
  esac
  
  # Ensure int is within the range 32-126
  # If it's less than 32, add 32 to bring it up into range
  (( _int < 32 )) && _int=$(( _int + 32 ))
  
  # If it's greater than 126, divide until it's in range
  if (( _int > 126 )); then
    until (( _int <= 126 )); do
      _int=$(( _int / 2 ))
    done
  fi

  # Finally, print our character
  # shellcheck disable=SC2059
  printf "\\$(printf -- '%03o' "${_int}")"
}

# @description Convert an ASCII character to its decimal value.
#
# @arg $1 string Single ASCII character to convert
#
# @stdout Decimal value of the character
# @exitcode 0 Always
ord() {
  printf -- '%d' "'${1}"
}
