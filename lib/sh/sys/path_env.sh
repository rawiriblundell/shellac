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
# Adapted from tomocafe/dotfiles (MIT) https://github.com/tomocafe/dotfiles
# Adapted from codeforester/base (MIT) https://github.com/codeforester/base

[ -n "${_SHELLAC_LOADED_sys_path_env+x}" ] && return 0
_SHELLAC_LOADED_sys_path_env=1

# @description Return 0 if the given directory is in PATH.
#
# @arg $1 string Directory to test
#
# @example
#   sys_path_contains /usr/local/bin   # 0 if present
#
# @exitcode 0 Present; 1 Not present
sys_path_contains() {
  local dir
  dir="${1:?sys_path_contains: missing directory}"
  case ":${PATH}:" in
    (*":${dir}:"*) return 0 ;;
    (*)            return 1 ;;
  esac
}

# @description Prepend a directory to PATH if it is not already present.
#
# @arg $1 string Directory to prepend
#
# @exitcode 0 Always
sys_path_prepend() {
  local dir
  dir="${1:?sys_path_prepend: missing directory}"
  sys_path_contains "${dir}" && return 0
  PATH="${dir}:${PATH}"
  export PATH
}

# @description Append a directory to PATH if it is not already present.
#
# @arg $1 string Directory to append
#
# @exitcode 0 Always
sys_path_append() {
  local dir
  dir="${1:?sys_path_append: missing directory}"
  sys_path_contains "${dir}" && return 0
  PATH="${PATH}:${dir}"
  export PATH
}

# @description Remove all occurrences of a directory from PATH.
#
# @arg $1 string Directory to remove
#
# @exitcode 0 Always
sys_path_remove() {
  local dir new_path old_path component
  dir="${1:?sys_path_remove: missing directory}"
  old_path="${PATH}"
  new_path=
  while IFS= read -r -d ':' component; do
    [[ "${component}" == "${dir}" ]] && continue
    [[ -z "${new_path}" ]] && new_path="${component}" || new_path="${new_path}:${component}"
  done <<< "${old_path}:"
  PATH="${new_path}"
  export PATH
}

# @description Deduplicate PATH entries, preserving first-occurrence order.
#
# @exitcode 0 Always
sys_path_dedup() {
  local new_path seen component
  new_path=
  declare -A seen
  while IFS= read -r -d ':' component; do
    [[ -z "${component}" ]] && continue
    [[ -n "${seen[${component}]+x}" ]] && continue
    seen["${component}"]=1
    [[ -z "${new_path}" ]] && new_path="${component}" || new_path="${new_path}:${component}"
  done <<< "${PATH}:"
  PATH="${new_path}"
  export PATH
}

# @description Print each directory in PATH on its own line.
#
# @example
#   sys_path_print | grep '/usr/local'
#
# @stdout One directory per line
# @exitcode 0 Always
sys_path_print() {
  local dir
  local -a dirs
  IFS=: read -r -a dirs <<< "${PATH}"
  for dir in "${dirs[@]}"; do
    printf -- '%s\n' "${dir}"
  done
}

# @description Remove the directory containing the current script from PATH
#   to prevent infinite recursion when a script shadows a system command.
#
# @exitcode 0 Always
sys_path_derecurse() {
  local curdir
  local _element
  local _new_path
  local _old_ifs
  curdir=$(cd -P -- "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && printf -- '%s' "${PWD}")
  _new_path=
  _old_ifs="${IFS}"
  IFS=:
  for _element in ${PATH}; do
    [ "${_element}" = "${curdir}" ] && continue
    _new_path="${_new_path:+${_new_path}:}${_element}"
  done
  IFS="${_old_ifs}"
  export PATH="${_new_path}"
}
