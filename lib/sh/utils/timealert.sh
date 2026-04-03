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
# Adapted from SpicyLemon/SpicyLemon (MIT) https://github.com/SpicyLemon/SpicyLemon

[ -n "${_SHELLAC_LOADED_utils_timealert+x}" ] && return 0
_SHELLAC_LOADED_utils_timealert=1

# @description Run a command and print a completion notification to stderr showing
#   the elapsed wall-clock time.  Exit code of the command is preserved.
#   Useful for wrapping long-running commands in interactive shells.
#
# @arg $@ Command and its arguments
#
# @example
#   timealert sleep 5
#   # => [done] sleep 5  (5s)
#
#   timealert make all
#   # => [done] make all  (2m 34s)
#
# @exitcode Passthrough — the exit code of the wrapped command
timealert() {
  local _start _end _elapsed _rc _cmd_label
  (( ${#} == 0 )) && { printf -- '%s\n' "timealert: missing command" >&2; return 1; }
  _cmd_label="${*}"
  _start="$(date +%s)"
  "${@}"
  _rc=$?
  _end="$(date +%s)"
  _elapsed=$(( _end - _start ))
  local _days _hours _mins _secs _label
  _days=$(( _elapsed / 86400 ))
  _elapsed=$(( _elapsed % 86400 ))
  _hours=$(( _elapsed / 3600 ))
  _elapsed=$(( _elapsed % 3600 ))
  _mins=$(( _elapsed / 60 ))
  _secs=$(( _elapsed % 60 ))
  if (( _days > 0 )); then
    _label="${_days}d ${_hours}h ${_mins}m ${_secs}s"
  elif (( _hours > 0 )); then
    _label="${_hours}h ${_mins}m ${_secs}s"
  elif (( _mins > 0 )); then
    _label="${_mins}m ${_secs}s"
  else
    _label="${_secs}s"
  fi
  printf -- '[done] %s  (%s)\n' "${_cmd_label}" "${_label}" >&2
  return "${_rc}"
}
