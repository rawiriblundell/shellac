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
# Provenance: https://github.com/rawiriblundell/sh_libpath
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_sys_sys_shell+x}" ] && return 0
_SHELLAC_LOADED_sys_sys_shell=1

# @description Print the name of the currently running shell.
#   Tries /proc/$$cmdline, then various 'ps' invocations, then procstat (FreeBSD),
#   then falls back to inspecting version variables. $SHELL is intentionally not
#   used as it reflects the login shell, not the running shell. Does not work for
#   fish shell, which requires non-Bourne-compatible introspection.
#
# @stdout Shell name, e.g. "bash", "ksh", "zsh"
# @exitcode 0 Success
# @exitcode 1 Unable to determine the running shell
sys_shell() {
  if [ -r "/proc/$$/cmdline" ]; then
    local _sys_shell_cmd
    # cmdline fields are NUL-separated; read -d '' gets the first field (executable path)
    IFS= read -r -d '' _sys_shell_cmd <"/proc/$$/cmdline" 2>/dev/null || true
    # Strip any leading path components
    _sys_shell_cmd="${_sys_shell_cmd##*/}"
    # BusyBox reports itself as 'busybox'; the actual shell is the second NUL-field
    if [ "${_sys_shell_cmd}" = "busybox" ]; then
      _sys_shell_cmd=$(tr '\0' '\n' <"/proc/$$/cmdline" | sed -n '2p')
    fi
    printf -- '%s\n' "${_sys_shell_cmd}"
  elif ps -p "$$" >/dev/null 2>&1; then
    ps -p "$$" | awk -F'[\t /]' 'END {print $NF}'
  # This one works well except for busybox
  elif ps -o comm= -p $$ >/dev/null 2>&1; then
    ps -o comm= -p $$
  elif ps -o pid,comm= >/dev/null 2>&1; then
    ps -o pid,comm= | awk -v ppid="$$" '$1==ppid {print $2}'
  # FreeBSD, may require more parsing
  elif command -v procstat >/dev/null 2>&1; then
    procstat -bh $$
  else
    case "${BASH_VERSION}" in (*.*) printf -- '%s\n' "bash"; return 0 ;; esac
    case "${KSH_VERSION}" in (*.*) printf -- '%s\n' "ksh"; return 0 ;; esac
    case "${ZSH_VERSION}" in (*.*) printf -- '%s\n' "zsh"; return 0 ;; esac
    # If we get to this point, fail out:
    printf -- '%s\n' "Unable to find method to determine the shell" >&2
    return 1
  fi
}
