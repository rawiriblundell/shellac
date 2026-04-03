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

[ -n "${_SHELLAC_LOADED_text_sanitize+x}" ] && return 0
_SHELLAC_LOADED_text_sanitize=1

# @description Strip surrounding quotes, trailing ':' or '=' separators, and
#   leading/trailing whitespace from a string.
#   Accepts input as an argument or via stdin.
#   Note: '%%:*' and '%%=*' strip from the first delimiter onwards —
#   do not use on values that legitimately contain ':' or '=' (e.g. URLs).
#
# @arg $1 string Optional: the string to sanitise (reads stdin if omitted)
#
# @example
#   str_sanitise '"  Bytes:  "'   # => Bytes
#   printf '%s' '"key": ' | str_sanitise  # => key
#
# @stdout Sanitised string
# @exitcode 0 Always
str_sanitise() {
  local _input
  if [[ -n "${1}" ]]; then
    _input="${1}"
  else
    read -r _input
  fi

  # Strip surrounding double quotes
  _input="${_input%\"}"
  _input="${_input#\"}"

  # Strip surrounding single quotes
  _input="${_input%\'}"
  _input="${_input#\'}"

  # Strip trailing ':' and '=' separators and everything after them
  _input="${_input%%:*}"
  _input="${_input%%=*}"

  # Strip leading whitespace
  _input="${_input#"${_input%%[![:space:]]*}"}"

  # Strip trailing whitespace
  _input="${_input%"${_input##*[![:space:]]}"}"

  printf -- '%s\n' "${_input}"
}

# @description Alias for str_sanitise.
str_sanitize() {
  str_sanitise "${@}"
}
