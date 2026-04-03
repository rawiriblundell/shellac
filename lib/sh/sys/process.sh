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
# Adapted from kigster/bash-orb (MIT) https://github.com/kigster/bash-orb
# Adapted from SpicyLemon/SpicyLemon (MIT) https://github.com/SpicyLemon/SpicyLemon

[ -n "${_SHELLAC_LOADED_sys_process+x}" ] && return 0
_SHELLAC_LOADED_sys_process=1

# @description Return 0 if a process with the given name is currently running.
#   Uses pgrep when available, falls back to ps | grep.
#
# @arg $1 string Process name or pattern
#
# @example
#   proc_running sshd    # 0 if sshd is running
#
# @exitcode 0 Running; 1 Not running
proc_running() {
  local _name _bracket_pattern
  _name="${1:?proc_running: missing process _name}"
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -x "${_name}" >/dev/null 2>&1
  else
    _bracket_pattern="[${_name:0:1}]${_name:1}"
    ps -ef 2>/dev/null | awk -v pat="${_bracket_pattern}" '$0 ~ pat' | grep -q .
  fi
}

# @description Return 0 if a PID is alive (process exists).
#
# @arg $1 int PID to test
#
# @exitcode 0 PID alive; 1 PID not found
proc_alive() {
  local _pid
  _pid="${1:?proc_alive: missing PID}"
  kill -0 "${_pid}" 2>/dev/null
}

# @description Stop a process by PID gracefully.
#   Sends SIGTERM, waits up to $2 seconds (default 10), then sends SIGKILL.
#
# @arg $1 int  PID to stop
# @arg $2 int  Grace period in seconds before SIGKILL (default: 10)
#
# @exitcode 0 Process stopped; 1 PID not found initially
proc_stop() {
  local _pid _grace _waited
  _pid="${1:?proc_stop: missing PID}"
  _grace="${2:-10}"
  _waited=0

  proc_alive "${_pid}" || return 1
  kill -TERM "${_pid}" 2>/dev/null || true

  while proc_alive "${_pid}" && (( _waited < _grace )); do
    sleep 1
    (( _waited += 1 ))
  done

  if proc_alive "${_pid}"; then
    kill -KILL "${_pid}" 2>/dev/null || true
  fi

  return 0
}

# @description List PIDs for processes whose command line matches a pattern.
#   One PID per line.  Excludes the current process and grep itself.
#
# @arg $1 string Pattern to match against full command line
#
# @example
#   proc_pids_matching nginx    # prints each nginx worker PID
#
# @stdout PID list, one per line
# @exitcode 0 At least one match; 1 No matches
proc_pids_matching() {
  local _pattern _bracket_pattern
  _pattern="${1:?proc_pids_matching: missing _pattern}"
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -f "${_pattern}"
  else
    _bracket_pattern="[${_pattern:0:1}]${_pattern:1}"
    ps -eo _pid,args 2>/dev/null |
      awk -v pat="${_bracket_pattern}" '$0 ~ pat {print $1}'
  fi
}

# @description Get the parent PID of a given PID.
#
# @arg $1 int PID (default: $$)
#
# @stdout Parent PID
# @exitcode 0 Always; 1 PID not found
proc_parent() {
  local _pid _ppid
  _pid="${1:-$$}"
  if [ -r "/proc/${_pid}/status" ]; then
    _ppid="$(awk '/^PPid:/{print $2}' "/proc/${_pid}/status")"
  else
    _ppid="$(ps -o _ppid= -p "${_pid}" 2>/dev/null | tr -d ' ')"
  fi
  [[ -n "${_ppid}" ]] || return 1
  printf -- '%d\n' "${_ppid}"
}

# @description Show full ps output for processes matching a pattern.
#   Like pgrep but shows the full process table row.  Prints the header line
#   followed by matching rows.
#   Uses the [x]yyy bracket trick so the awk process never matches itself:
#   searching for "nginx" becomes the awk pattern "[n]ginx", which matches
#   "nginx" in ps output but not the literal string "[n]ginx" in awk's own
#   command line.
#
# @arg $1 string Pattern to search for
#
# @example
#   proc_grep nginx
#   proc_grep sshd
#
# @stdout ps header + matching process rows
# @exitcode 0 At least one match; 1 No matches
proc_grep() {
  local _term _bracket_pattern _header _results
  _term="${1:?proc_grep: missing _pattern}"
  _bracket_pattern="[${_term:0:1}]${_term:1}"
  _header="$(ps auxf 2>/dev/null | head -1)"
  _results="$(ps auxf 2>/dev/null | awk -v pat="${_bracket_pattern}" '$0 ~ pat')"
  [[ -z "${_results}" ]] && return 1
  printf -- '%s\n' "${_header}"
  printf -- '%s\n' "${_results}"
}

# @description List the PIDs of all direct child processes of a given parent PID.
#   Uses pgrep if available, otherwise falls back to parsing 'ps -e'.
#
# @arg $1 int Parent PID to query (default: $$)
#
# @stdout One PID per line
# @exitcode 0 Always
proc_children() {
  local _ppid
  _ppid="${1:-$$}"
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -P "${_ppid}"
  else
    ps -e -o _pid,_ppid | awk -v _ppid="${_ppid}" '$2 == _ppid {print $1}'
  fi
}
