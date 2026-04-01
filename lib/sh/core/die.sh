# shellcheck shell=ksh

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

[ -n "${_SHELLAC_LOADED_core_die+x}" ] && return 0
_SHELLAC_LOADED_core_die=1

# Get the top level PID and setup a trap so that we can call die() within subshells
trap "exit 1" TERM
_self_pid="${$}"
export _self_pid

# @description Print a formatted error message and terminate the script by
#   sending SIGTERM to the top-level PID. Safe to call from subshells.
#   Uses colour when stderr is a terminal.
#
# @arg $@ string Error message text
#
# @stderr Formatted error message prefixed with script name and line number
# @exitcode 1 Always (via SIGTERM trap)
cmd_die() {
    if [ -t 2 ]; then
        printf '\e[31;1m====>%s\e[0m\n' "${0}:(${LINENO}): ${*}" >&2
    else
        printf -- '====>%s\n' "${0}:(${LINENO}): ${*}" >&2
    fi
    kill -s TERM "${_self_pid}"
}

# @description Alias for cmd_die.
die() { cmd_die "${@}"; }

# @description Print a formatted warning message to stderr and return (non-fatal).
#   Uses colour when stderr is a terminal.
#
# @arg $@ string Warning message text
#
# @stderr Formatted warning message prefixed with script name and line number
# @exitcode 0 Always
cmd_warn() {
    if [ -t 2 ]; then
        printf '\e[33;1m====>%s\e[0m\n' "${0}:(${LINENO}): ${*}" >&2
    else
        printf -- '====>%s\n' "${0}:(${LINENO}): ${*}" >&2
    fi
}

# @description Alias for cmd_warn.
warn() { cmd_warn "${@}"; }

# @description Run a command and die with a descriptive message if it fails.
#   A lightweight alternative to cmd_exec() for critical one-liners.
#
# @arg $@ string The command and its arguments to execute
#
# @exitcode 0 Command succeeded
# @exitcode 1 Command failed (via cmd_die())
cmd_try() {
    "${@}" || cmd_die "cannot ${*}"
}

# @description Alias for cmd_try.
try() { cmd_try "${@}"; }

# @description Run a command up to N times until it succeeds.
#   Prints a dot to stderr for each failed attempt.
#   Optionally sleeps between attempts with -s.
#
# @arg $1 string Optional: '-m N' max attempts (default: 3)
# @arg $2 string Optional: '-s N' sleep seconds between attempts (default: 0)
# @arg $@ string The command and its arguments to execute
#
# @stderr A dot per failed attempt, then a newline; error message if exhausted
# @exitcode 0 Command succeeded within the allowed attempts
# @exitcode 1 All attempts exhausted
cmd_retry() {
    local _attempts
    local _count
    local _opt
    local _sleep
    local OPTIND
    OPTIND=1
    while getopts ":m:s:" _opt; do
        case "${_opt}" in
            (m) _attempts="${OPTARG}" ;;
            (s) _sleep="${OPTARG}" ;;
            (*) : ;;
        esac
    done
    shift "$(( OPTIND - 1 ))"
    _attempts="${_attempts:-3}"
    _sleep="${_sleep:-0}"
    _count=0
    until "${@}"; do
        : $(( _count += 1 ))
        printf -- '%s' "." >&2
        if (( _count >= _attempts )); then
            printf -- '\n' >&2
            printf -- 'cmd_retry: %s\n' "command failed after ${_attempts} attempt(s): ${*}" >&2
            return 1
        fi
        (( _sleep > 0 )) && sleep "${_sleep}"
    done
    (( _count > 0 )) && printf -- '\n' >&2
    return 0
}
