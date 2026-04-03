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
  local name bracket_pattern
  name="${1:?proc_running: missing process name}"
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -x "${name}" >/dev/null 2>&1
  else
    bracket_pattern="[${name:0:1}]${name:1}"
    ps -ef 2>/dev/null | awk -v pat="${bracket_pattern}" '$0 ~ pat' | grep -q .
  fi
}

# @description Return 0 if a PID is alive (process exists).
#
# @arg $1 int PID to test
#
# @exitcode 0 PID alive; 1 PID not found
proc_alive() {
  local pid
  pid="${1:?proc_alive: missing PID}"
  kill -0 "${pid}" 2>/dev/null
}

# @description Stop a process by PID gracefully.
#   Sends SIGTERM, waits up to $2 seconds (default 10), then sends SIGKILL.
#
# @arg $1 int  PID to stop
# @arg $2 int  Grace period in seconds before SIGKILL (default: 10)
#
# @exitcode 0 Process stopped; 1 PID not found initially
proc_stop() {
  local pid grace waited
  pid="${1:?proc_stop: missing PID}"
  grace="${2:-10}"
  waited=0

  proc_alive "${pid}" || return 1
  kill -TERM "${pid}" 2>/dev/null || true

  while proc_alive "${pid}" && (( waited < grace )); do
    sleep 1
    (( waited += 1 ))
  done

  if proc_alive "${pid}"; then
    kill -KILL "${pid}" 2>/dev/null || true
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
  local pattern bracket_pattern
  pattern="${1:?proc_pids_matching: missing pattern}"
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -f "${pattern}"
  else
    bracket_pattern="[${pattern:0:1}]${pattern:1}"
    ps -eo pid,args 2>/dev/null |
      awk -v pat="${bracket_pattern}" '$0 ~ pat {print $1}'
  fi
}

# @description Get the parent PID of a given PID.
#
# @arg $1 int PID (default: $$)
#
# @stdout Parent PID
# @exitcode 0 Always; 1 PID not found
proc_parent() {
  local pid ppid
  pid="${1:-$$}"
  if [ -r "/proc/${pid}/status" ]; then
    ppid="$(awk '/^PPid:/{print $2}' "/proc/${pid}/status")"
  else
    ppid="$(ps -o ppid= -p "${pid}" 2>/dev/null | tr -d ' ')"
  fi
  [[ -n "${ppid}" ]] || return 1
  printf -- '%d\n' "${ppid}"
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
  local term bracket_pattern header results
  term="${1:?proc_grep: missing pattern}"
  bracket_pattern="[${term:0:1}]${term:1}"
  header="$(ps auxf 2>/dev/null | head -1)"
  results="$(ps auxf 2>/dev/null | awk -v pat="${bracket_pattern}" '$0 ~ pat')"
  [[ -z "${results}" ]] && return 1
  printf -- '%s\n' "${header}"
  printf -- '%s\n' "${results}"
}

# @description List the PIDs of all direct child processes of a given parent PID.
#   Uses pgrep if available, otherwise falls back to parsing 'ps -e'.
#
# @arg $1 int Parent PID to query (default: $$)
#
# @stdout One PID per line
# @exitcode 0 Always
proc_children() {
  local ppid
  ppid="${1:-$$}"
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -P "${ppid}"
  else
    ps -e -o pid,ppid | awk -v ppid="${ppid}" '$2 == ppid {print $1}'
  fi
}
