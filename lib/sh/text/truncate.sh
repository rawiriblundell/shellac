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
# Adapted from elibs/ebash (Apache-2.0) https://github.com/elibs/ebash
# Original author: Marshall McMullen <marshall.mcmullen@gmail.com>

[ -n "${_SHELLAC_LOADED_text_truncate+x}" ] && return 0
_SHELLAC_LOADED_text_truncate=1

# @description Truncate a string to fit within a maximum character length.
#   With -e, appends "..." and still fits within the specified length.
#   Pure parameter expansion — no subshells.
#
# @arg $1 string [-e] Optional flag to append ellipsis for truncated strings
# @arg $2 int    Maximum length (or $1 if no flag given)
# @arg $@ string Text to truncate
#
# @example
#   str_truncate 10 "Hello, World!"        # => "Hello, Wor"
#   str_truncate -e 10 "Hello, World!"     # => "Hello, ..."
#   str_truncate 5 "Hi"                    # => "Hi"
#
# @stdout Truncated string (no trailing newline)
# @exitcode 0 Always
str_truncate() {
  local _ellipsis
  local _length
  local _text
  _ellipsis=0
  if [[ "${1:-}" = "-e" ]]; then
    _ellipsis=1
    shift
  fi
  _length="${1}"
  shift
  _text="$*"
  if (( ${#_text} > _length && _ellipsis == 1 )); then
    printf -- '%s' "${_text:0:$(( _length - 3 ))}..."
  else
    printf -- '%s' "${_text:0:${_length}}"
  fi
}
text_truncate() { str_truncate "${@}"; }
