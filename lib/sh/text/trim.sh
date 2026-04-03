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

[ -n "${_SHELLAC_LOADED_text_trim+x}" ] && return 0
_SHELLAC_LOADED_text_trim=1

# @description Strip leading and trailing whitespace from a string and print the result.
#
# @arg $@ string The input string
#
# @stdout Input string with leading and trailing whitespace removed
# @exitcode 0 Always
str_trim() {
  LC_CTYPE=C
  local _trim_str _trim_tmp
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _trim_str
  else
    _trim_str="${*}"
  fi
  while true; do
    _trim_tmp="${_trim_str#[[:space:]]}"   # Strip whitespace to the left
    _trim_tmp="${_trim_tmp%[[:space:]]}"   # Strip whitespace to the right
    [[ "${_trim_tmp}" = "${_trim_str}" ]] && break
    _trim_str="${_trim_tmp}"
  done
  printf -- '%s\n' "${_trim_str}"
}

# @description Alias for str_trim.
trim() {
  str_trim "${@}"
}

# @description Alias for str_trim.
str_strip() {
  str_trim "${@}"
}

# @description Alias for str_trim.
strip() {
  str_trim "${@}"
}

# @description Strip leading whitespace from a string and print the result.
#
# @arg $@ string The input string
#
# @stdout Input string with leading whitespace removed
# @exitcode 0 Always
str_ltrim() {
  LC_CTYPE=C
  local _ltrim_str _ltrim_tmp
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _ltrim_str
  else
    _ltrim_str="${*}"
  fi
  while true; do
    _ltrim_tmp="${_ltrim_str#[[:space:]]}"
    [[ "${_ltrim_tmp}" = "${_ltrim_str}" ]] && break
    _ltrim_str="${_ltrim_tmp}"
  done
  printf -- '%s\n' "${_ltrim_str}"
}

# @description Alias for str_ltrim.
ltrim() {
  str_ltrim "${@}"
}

# @description Strip leading and trailing whitespace and compact internal spaces,
#   printing the result to stdout.
#
# @arg $@ string The input string
#
# @stdout Trimmed and compacted string
# @exitcode 0 Always
str_ntrim() {
  LC_CTYPE=C
  local _ntrim_str
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    _ntrim_str=$(xargs)
  else
    _ntrim_str=$(printf -- '%s' "${*}" | xargs)
  fi
  printf -- '%s\n' "${_ntrim_str}"
}

# @description Alias for str_ntrim.
ntrim() {
  str_ntrim "${@}"
}

# @description Strip trailing whitespace from a string and print the result.
#
# @arg $@ string The input string
#
# @stdout Input string with trailing whitespace removed
# @exitcode 0 Always
str_rtrim() {
  LC_CTYPE=C
  local _rtrim_str _rtrim_tmp
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _rtrim_str
  else
    _rtrim_str="${*}"
  fi
  while true; do
    _rtrim_tmp="${_rtrim_str%[[:space:]]}"
    [[ "${_rtrim_tmp}" = "${_rtrim_str}" ]] && break
    _rtrim_str="${_rtrim_tmp}"
  done
  printf -- '%s\n' "${_rtrim_str}"
}

# @description Alias for str_rtrim.
rtrim() {
  str_rtrim "${@}"
}
