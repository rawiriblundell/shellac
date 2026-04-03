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
# Adapted from kvz/bash3boilerplate (MIT) https://github.com/kvz/bash3boilerplate
# Original author: Kevin van Zonneveld

[ -n "${_SHELLAC_LOADED_fs_ini_val+x}" ] && return 0
_SHELLAC_LOADED_fs_ini_val=1

# @description Read or write a value in an INI-style config file.
#   Key is specified as "section.key". If no dot is present, uses "default" as the section.
#   Read:  fs_ini_val file section.key
#   Write: fs_ini_val file section.key value [comment]
#   The file is created if it does not exist.
#
# @arg $1 string Path to .ini file
# @arg $2 string Key in "section.key" form (or just "key" for the default section)
# @arg $3 string Value to set (omit to read the _current value)
# @arg $4 string Optional inline comment for a new entry
#
# @example
#   fs_ini_val /etc/myapp.ini database.host localhost
#   fs_ini_val /etc/myapp.ini database.host   # => localhost
#
# @stdout Current value when reading
# @exitcode 0 Success; 2 Missing arguments
fs_ini_val() {
  local _file _sectionkey _val _comment _delim _comment_delim _section _key
  local _current _current_comment _ret_str

  (( ${#} < 2 )) && {
    printf -- '%s\n' "fs_ini_val: requires at least 2 arguments (_file, _section._key)" >&2
    return 2
  }

  _file="${1}"
  _sectionkey="${2}"
  _val="${3:-}"
  _comment="${4:-}"
  _delim="="
  _comment_delim=";"

  [[ -f "${_file}" ]] || touch "${_file}"

  # Split section.key — if no dot, treat input as key in the default section
  IFS='.' read -r _section _key <<< "${_sectionkey}"
  if [[ -z "${_key}" ]]; then
    _key="${_section}"
    _section="default"
  fi

  _current="$(sed -En "/^\[/{h;d;};G;s/^${_key}([[:blank:]]*)${_delim}(.*)\n\[${_section}\]$/\2/p" \
    "${_file}" | awk '{$1=$1};1')"
  _current_comment="$(sed -En \
    "/^\[${_section}\]/,/^\[.*\]/ s|^(${_comment_delim}\[${_key}\])(.*)|\2|p" \
    "${_file}" | awk '{$1=$1};1')"

  if ! grep -q "\[${_section}\]" "${_file}"; then
    printf -- '\n[%s]\n' "${_section}" >> "${_file}"
  fi

  if [[ -z "${_val}" ]]; then
    printf -- '%s\n' "${_current}"
    return 0
  fi

  [[ -z "${_comment}" ]] && _comment="${_current_comment}"

  # Remove old comment and value for this key in this section, then strip blank lines
  sed -i.bak \
    "/^\[${_section}\]/,/^\[.*\]/ s|^\(${_comment_delim}\[${_key}\] \).*$||" "${_file}"
  sed -i.bak \
    "/^\[${_section}\]/,/^\[.*\]/ s|^\(${_key}=\).*$||" "${_file}"
  sed -i.bak '/^[[:space:]]*$/d' "${_file}"
  # Add a blank line before each section header for readability
  sed -i.bak $'s/^\\[/\\\n\\[/g' "${_file}"

  if [[ -z "${_comment}" ]]; then
    _ret_str="/\\[${_section}\\]/a\\
${_key}${_delim}${_val}"
  else
    _ret_str="/\\[${_section}\\]/a\\
${_comment_delim}[${_key}] ${_comment}\\
${_key}${_delim}${_val}"
  fi

  sed -i.bak -e "${_ret_str}" "${_file}"
  rm -f "${_file}.bak"
}
