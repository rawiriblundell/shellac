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
# Provenance: https://github.com/rawiriblundell/sh_libpath
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_text_replace+x}" ] && return 0
_SHELLAC_LOADED_text_replace=1


# @description Replace occurrences of a pattern in a string.
#   Replaces all occurrences by default; pass a count to limit replacements.
#   The '/' sed delimiter is automatically escaped in match and replacement,
#   so literal '/' characters in either argument are handled correctly.
#
# @arg $1 string The input string
# @arg $2 string The pattern to search for (sed-compatible regex)
# @arg $3 string The replacement string
# @arg $4 int Optional: maximum number of replacements (default: all)
#
# @stdout String with replacements applied
# @exitcode 0 Success
# @exitcode 1 Count is not a positive integer
str_replace() {
  local _str_replace_string _str_replace_match
  local _str_replace_replacement _str_replace_count _str_replace_i
  _str_replace_string="${1}"
  _str_replace_match="${2}"
  _str_replace_replacement="${3}"
  _str_replace_count="${4}"

  # Validate count before escaping so the error shows the original value
  case "${_str_replace_count}" in
    ('') : ;;
    (*[!0-9]* | 0)
      printf -- 'str_replace: count must be a positive integer, got: %s\n' "${_str_replace_count}" >&2
      return 1
    ;;
  esac

  # Escape the sed delimiter in match; other metacharacters are intentional regex
  _str_replace_match="${_str_replace_match//\//\\/}"

  # Escape \, &, and / in replacement — in that order to avoid double-escaping
  _str_replace_replacement="${_str_replace_replacement//\\/\\\\}"
  _str_replace_replacement="${_str_replace_replacement//&/\\&}"
  _str_replace_replacement="${_str_replace_replacement//\//\\/}"

  case "${_str_replace_count}" in
    ('')
      printf -- '%s\n' "${_str_replace_string}" |
        sed "s/${_str_replace_match}/${_str_replace_replacement}/g"
    ;;
    (*)
      _str_replace_i=0
      until (( _str_replace_i == _str_replace_count )); do
        (( _str_replace_i++ ))
        _str_replace_string=$(printf -- '%s\n' "${_str_replace_string}" |
          sed "s/${_str_replace_match}/${_str_replace_replacement}/")
      done
      printf -- '%s\n' "${_str_replace_string}"
    ;;
  esac
}
