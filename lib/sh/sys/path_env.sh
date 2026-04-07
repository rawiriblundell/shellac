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
  local _dir
  _dir="${1:?sys_path_contains: missing directory}"
  case ":${PATH}:" in
    (*":${_dir}:"*) return 0 ;;
    (*)            return 1 ;;
  esac
}

# @description Prepend a directory to PATH if it is not already present.
#
# @arg $1 string Directory to prepend
#
# @exitcode 0 Always
sys_path_prepend() {
  local _dir
  _dir="${1:?sys_path_prepend: missing directory}"
  sys_path_contains "${_dir}" && return 0
  PATH="${_dir}:${PATH}"
  export PATH
}

# @description Append a directory to PATH if it is not already present.
#
# @arg $1 string Directory to append
#
# @exitcode 0 Always
sys_path_append() {
  local _dir
  _dir="${1:?sys_path_append: missing directory}"
  sys_path_contains "${_dir}" && return 0
  PATH="${PATH}:${_dir}"
  export PATH
}

# @description Remove all occurrences of a directory from PATH.
#
# @arg $1 string Directory to remove
#
# @exitcode 0 Always
sys_path_remove() {
  local _dir _new_path _old_path _component
  _dir="${1:?sys_path_remove: missing directory}"
  _old_path="${PATH}"
  _new_path=
  while IFS= read -r -d ':' _component; do
    [[ "${_component}" == "${_dir}" ]] && continue
    [[ -z "${_new_path}" ]] && _new_path="${_component}" || _new_path="${_new_path}:${_component}"
  done <<< "${_old_path}:"
  PATH="${_new_path}"
  export PATH
}

# @description Deduplicate PATH entries, preserving first-occurrence order.
#
# @exitcode 0 Always
sys_path_dedup() {
  local _new_path _component
  _new_path=
  while IFS= read -r -d ':' _component; do
    [[ -z "${_component}" ]] && continue
    case ":${_new_path}:" in
      (*":${_component}:"*) continue ;;
    esac
    [[ -z "${_new_path}" ]] && _new_path="${_component}" || _new_path="${_new_path}:${_component}"
  done <<< "${PATH}:"
  PATH="${_new_path}"
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
  local _dir
  local -a dirs
  IFS=: read -r -a dirs <<< "${PATH}"
  for _dir in "${dirs[@]}"; do
    printf -- '%s\n' "${_dir}"
  done
}

# @description Remove the directory containing the current script from PATH
#   to prevent infinite recursion when a script shadows a system command.
#
# @exitcode 0 Always
sys_path_derecurse() {
  local _curdir
  local _element
  local _new_path
  local _old_ifs
  _curdir=$(cd -P -- "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && printf -- '%s' "${PWD}")
  _new_path=
  _old_ifs="${IFS}"
  IFS=:
  for _element in ${PATH}; do
    [ "${_element}" = "${_curdir}" ] && continue
    _new_path="${_new_path:+${_new_path}:}${_element}"
  done
  IFS="${_old_ifs}"
  export PATH="${_new_path}"
}
