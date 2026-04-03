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
# Provenance: https://github.com/rawiriblundell/shellac
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_core_debug+x}" ] && return 0
_SHELLAC_LOADED_core_debug=1

# https://www.reddit.com/r/bash/comments/g1yjfo/debugging_bash_scripts/
# https://johannes.truschnigg.info/writing/2021-12_colodebug/

# @description Enable ERR trap to call debug_err_handler on any error.
#
# @exitcode 0 Always
debug_trap_err() {
    set -o errtrace
    trap 'debug_err_handler ${?}' ERR
}

# @description Handle ERR trap: print a stack trace and exit.
#   Uses the portable caller(1) builtin for the stack trace.
#   Bash users can get richer output (function names, formatted frames) by
#   loading core/stacktrace before enabling this trap — stacktrace() will
#   then be available as an alternative to the caller loop below.
#
# @arg $1 int The exit code from the failing command
#
# @stderr Stack trace and error exit code
# @exitcode Propagates the original error exit code
debug_err_handler() {
    local _frame
    local _exit_code
    trap - ERR
    _frame=0
    _exit_code="${1}"
    printf -- '%s\n' "Aborting on error ${_exit_code}:" \
        "--------------------" >&2
    while caller "${_frame}" >&2; do
        : $(( _frame += 1 ))
    done
    exit "${_exit_code}"
}

# @description Emit a debug trace when debug_mode is true.
#   Uses the no-op colon builtin so output appears only in xtrace (-x) output.
#
# @exitcode 0 Always
debug() {
    [[ "${debug_mode}" = "true" ]] || return 0
    : [DEBUG] "${*}"
    : ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
}

# @description Like debug(), but pauses for a keypress before continuing.
#
# @exitcode 0 Always
debug_step() {
    [[ "${debug_mode}" = "true" ]] || return 0
    : [DEBUG] "${*}"
    : ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    read -n 1 -s -r -p "Press any key to continue"
}

# Check whether the sourcing script was invoked with -d/--debug and enable
# debug mode if so. Intentionally runs at source time.
case "${1}" in
    (-d|--debug)
        set -xv
        export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
        readonly debug_mode=true
        trap 'set +x' EXIT
    ;;
esac

# @description Drop into an interactive debug REPL at the call site.
#   Keys: o=options, p=parameters, a=indexed arrays, A=assoc arrays,
#   x=enable xtrace, X=disable xtrace, q=quit.
#
# @exitcode 0 Always
debug_breakpoint() {
    local REPLY
    printf -- '%s\n' 'Breakpoint hit. [opaAxXq]'
    while read -r -n 1 REPLY; do
        case "${REPLY}" in
            (o) shopt -s; set -o ;;
            (p) declare -p | less ;;
            (a) declare -a ;;
            (A) declare -A ;;
            (x) set -x ;;
            (X) set +x ;;
            (q) return ;;
            (*) ;;
        esac
    done
}
