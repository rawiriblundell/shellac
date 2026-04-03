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
# @arg $3 string Value to set (omit to read the current value)
# @arg $4 string Optional inline comment for a new entry
#
# @example
#   fs_ini_val /etc/myapp.ini database.host localhost
#   fs_ini_val /etc/myapp.ini database.host   # => localhost
#
# @stdout Current value when reading
# @exitcode 0 Success; 2 Missing arguments
fs_ini_val() {
  local file sectionkey val comment delim comment_delim section key
  local current current_comment ret_str

  (( ${#} < 2 )) && {
    printf -- '%s\n' "fs_ini_val: requires at least 2 arguments (file, section.key)" >&2
    return 2
  }

  file="${1}"
  sectionkey="${2}"
  val="${3:-}"
  comment="${4:-}"
  delim="="
  comment_delim=";"

  [[ -f "${file}" ]] || touch "${file}"

  # Split section.key — if no dot, treat input as key in the default section
  IFS='.' read -r section key <<< "${sectionkey}"
  if [[ -z "${key}" ]]; then
    key="${section}"
    section="default"
  fi

  current="$(sed -En "/^\[/{h;d;};G;s/^${key}([[:blank:]]*)${delim}(.*)\n\[${section}\]$/\2/p" \
    "${file}" | awk '{$1=$1};1')"
  current_comment="$(sed -En \
    "/^\[${section}\]/,/^\[.*\]/ s|^(${comment_delim}\[${key}\])(.*)|\2|p" \
    "${file}" | awk '{$1=$1};1')"

  if ! grep -q "\[${section}\]" "${file}"; then
    printf -- '\n[%s]\n' "${section}" >> "${file}"
  fi

  if [[ -z "${val}" ]]; then
    printf -- '%s\n' "${current}"
    return 0
  fi

  [[ -z "${comment}" ]] && comment="${current_comment}"

  # Remove old comment and value for this key in this section, then strip blank lines
  sed -i.bak \
    "/^\[${section}\]/,/^\[.*\]/ s|^\(${comment_delim}\[${key}\] \).*$||" "${file}"
  sed -i.bak \
    "/^\[${section}\]/,/^\[.*\]/ s|^\(${key}=\).*$||" "${file}"
  sed -i.bak '/^[[:space:]]*$/d' "${file}"
  # Add a blank line before each section header for readability
  sed -i.bak $'s/^\\[/\\\n\\[/g' "${file}"

  if [[ -z "${comment}" ]]; then
    ret_str="/\\[${section}\\]/a\\
${key}${delim}${val}"
  else
    ret_str="/\\[${section}\\]/a\\
${comment_delim}[${key}] ${comment}\\
${key}${delim}${val}"
  fi

  sed -i.bak -e "${ret_str}" "${file}"
  rm -f "${file}.bak"
}
