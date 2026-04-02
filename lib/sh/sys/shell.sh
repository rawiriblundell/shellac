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
  local _sys_shell_cmd
  if [ -r "/proc/$$/cmdline" ]; then
    # Convert NUL-separated cmdline to spaces; awk extracts the last non-empty
    # slash-or-space-delimited token, which is the shell name regardless of
    # whether the path is absolute (/bin/bash), prefixed (busybox ash), or bare
    _sys_shell_cmd=$(tr '\0' ' ' <"/proc/$$/cmdline" | awk -F'[ /]' '{print $(NF-1)}')
  elif ps -fp "$$" >/dev/null 2>&1; then
    # -f (full format) expands CMD to the full command line so awk $NF
    # handles paths (/bin/bash -> bash) and multi-word names (busybox ash -> ash)
    _sys_shell_cmd=$(ps -fp "$$" | awk -F'[ \t/]' 'END {print $NF}')
  # ps -o comm= works well except for busybox
  elif ps -o comm= -p $$ >/dev/null 2>&1; then
    _sys_shell_cmd=$(ps -o comm= -p $$)
  elif ps -o pid,comm= >/dev/null 2>&1; then
    _sys_shell_cmd=$(ps -o pid,comm= | awk -v ppid="$$" '$1==ppid {print $2}')
  # FreeBSD, may require more parsing
  elif command -v procstat >/dev/null 2>&1; then
    _sys_shell_cmd=$(procstat -bh $$)
  else
    case "${BASH_VERSION}" in (*.*) printf -- '%s\n' "bash"; return 0 ;; esac
    case "${KSH_VERSION}" in (*.*) printf -- '%s\n' "ksh"; return 0 ;; esac
    case "${ZSH_VERSION}" in (*.*) printf -- '%s\n' "zsh"; return 0 ;; esac
    printf -- '%s\n' "Unable to find method to determine the shell" >&2
    return 1
  fi
  # Strip leading dash: login shells set argv[0] to '-bash', '-zsh' etc.
  _sys_shell_cmd="${_sys_shell_cmd#-}"
  # If we still have 'busybox', assume ash — it's the standard BusyBox shell
  [[ "${_sys_shell_cmd}" = "busybox" ]] && _sys_shell_cmd="ash"
  printf -- '%s\n' "${_sys_shell_cmd}"
}
