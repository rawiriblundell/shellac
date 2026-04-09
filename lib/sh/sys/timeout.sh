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

[ -n "${_SHELLAC_LOADED_sys_timeout+x}" ] && return 0
_SHELLAC_LOADED_sys_timeout=1

# @internal
# Convert a duration string with an optional unit suffix to seconds.
# Accepted suffixes: s (seconds, default), m (minutes), h (hours), d (days).
# Plain integers are treated as seconds.
_sys_timeout_parse_duration() {
  local _raw
  _raw="${1:?_sys_timeout_parse_duration: duration required}"
  case "${_raw}" in
    (*[!0-9smhd]*|'')
      printf -- '%s\n' "sys_timeout: invalid duration '${_raw}'" >&2
      return 1
    ;;
    (*m) printf -- '%d\n' "$(( ${_raw%m*} * 60 ))" ;;
    (*h) printf -- '%d\n' "$(( ${_raw%h*} * 60 * 60 ))" ;;
    (*d) printf -- '%d\n' "$(( ${_raw%d*} * 60 * 60 * 24 ))" ;;
    (*)  printf -- '%d\n' "${_raw%s*}" ;;
  esac
}

# @description Run a command with a time limit.
#   If the command does not finish within the given duration it is sent a signal
#   (default: TERM).  Mirrors the interface of GNU timeout(1).
#
#   The exit code follows the GNU convention: 124 if the command was killed by
#   the timeout, otherwise the command's own exit code.
#
#   Warning: long-running invocations are subject to PID reuse — if the command
#   exits and its PID is immediately reassigned, the watcher may signal the
#   wrong process.  This is an inherent limitation of shell-based timeout
#   implementations.
#
# @option -s string Signal name or number to send on timeout (default: TERM).
#   Accepted names: HUP INT QUIT ABRT KILL ALRM TERM (case-insensitive).
#   Accepted numbers: 1 2 3 6 9 14 15.
# @option -k string If the process is still running this long after the initial
#   signal, send KILL.  Accepts the same duration format as the main argument.
# @arg $1 string Duration with optional suffix: s (default), m, h, d
# @arg $@ string Command and arguments to execute
#
# @example
#   sys_timeout 5 sleep 30              # killed after 5s; returns 124
#   sys_timeout 1m long_running_task
#   sys_timeout -s HUP 10 some_daemon
#   sys_timeout -s TERM -k 5 30 stubborn_proc
#
# @stdout  Passthrough from the command
# @stderr  Passthrough from the command
# @exitcode 124 Command was still running when the timeout fired
# @exitcode 0   Command completed within the time limit with exit code 0
# @exitcode N   Command's own exit code if it completed within the time limit
sys_timeout() {
  local _sig_name _sig_num _kill_duration _duration _opt
  local _child _watcher_pid _exit_code
  _sig_name="TERM"
  _sig_num=15
  _kill_duration=""

  local OPTIND
  while getopts ":k:s:" _opt; do
    case "${_opt}" in
      (k)
        _kill_duration="$(_sys_timeout_parse_duration "${OPTARG}")" || return 1
      ;;
      (s)
        case "${OPTARG}" in
          (1|[hH][uU][pP])       _sig_name=HUP;  _sig_num=1  ;;
          (2|[iI][nN][tT])       _sig_name=INT;  _sig_num=2  ;;
          (3|[qQ][uU][iI][tT])   _sig_name=QUIT; _sig_num=3  ;;
          (6|[aA][bB][rR][tT])   _sig_name=ABRT; _sig_num=6  ;;
          (9|[kK][iI][lL][lL])   _sig_name=KILL; _sig_num=9  ;;
          (14|[aA][lL][rR][mM])  _sig_name=ALRM; _sig_num=14 ;;
          (15|[tT][eE][rR][mM])  _sig_name=TERM; _sig_num=15 ;;
          (*)
            printf -- '%s\n' "sys_timeout: unrecognised signal '${OPTARG}'" >&2
            return 1
          ;;
        esac
      ;;
      (\?|:)
        printf -- '%s\n' "sys_timeout: invalid option '-${OPTARG}'" >&2
        return 1
      ;;
    esac
  done
  shift "$(( OPTIND - 1 ))"

  _duration="$(_sys_timeout_parse_duration "${1:?sys_timeout: duration required}")" || return 1
  shift

  if (( ${#} == 0 )); then
    printf -- '%s\n' "sys_timeout: no command given" >&2
    return 1
  fi

  # Run in a subshell to suppress job-control messages
  (
    "${@}" &
    _child="${!}"

    # Suppress the default notification for our signal in this subshell
    trap -- "" "${_sig_name}"

    # Watcher: send the initial signal after the duration expires, then send
    # KILL after the kill-after period if -k was specified and the process
    # is still alive
    (
      sleep "${_duration}"
      kill -s "${_sig_name}" "${_child}" 2>/dev/null
      if [[ -n "${_kill_duration}" ]]; then
        sleep "${_kill_duration}"
        kill -9 "${_child}" 2>/dev/null
      fi
    ) 2>/dev/null &
    _watcher_pid="${!}"

    wait "${_child}"
    _exit_code="${?}"

    # Clean up the watcher if the command finished before it fired
    kill "${_watcher_pid}" 2>/dev/null
    wait "${_watcher_pid}" 2>/dev/null

    # Return 124 (GNU convention) if the command appears to have been killed
    # by the timeout signal rather than exiting normally
    if (( _exit_code == 128 + _sig_num )); then
      return 124
    fi
    return "${_exit_code}"
  )
}
