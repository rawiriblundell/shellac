# shellcheck shell=bash

# Copyright 2023 Rawiri Blundell
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

[ -n "${_SHELLAC_LOADED_sys_cpuhogs+x}" ] && return 0
_SHELLAC_LOADED_sys_cpuhogs=1

# List processes by cpu usage
# This is usually better handled by tools like top and sar

# With inspiration from https://gist.github.com/mlgill/b08b18fc1de2086d9c20

# @internal
_cpuhogs_print_fmt() {
    local _print_fmt _wrap_limit

    case "${1}" in
        (green)  _print_fmt='\e[1;32m%s\t%4.2f%%\t%-s\e[0m\n'; shift 1 ;;
        (yellow) _print_fmt='\e[1;33m%s\t%4.2f%%\t%s\e[0m\n'; shift 1 ;;
        (red)    _print_fmt='\e[1;31m%s\t%4.2f%%\t%s\e[0m\n'; shift 1 ;;
        (*)      _print_fmt='%s\t%4.2f%%\t%s\n' ;;
    esac

    # Override if we're not being run interactively
    [[ -t 1 ]] || _print_fmt='%s\t%4.2f%%\t%s\n'

    # Print using the format that we've settled on
    # shellcheck disable=SC2059
    printf -- "${_print_fmt}" "${@}"
}

# @description List processes sorted by CPU usage, colour-coded by percentage.
#   Output is colour-coded: green (<10%), yellow (>=10%), red (>=20%).
#   Colours are suppressed when not running interactively.
#
# @arg $1 int Optional: number of processes to show (default: 10). Accepts bare
#   integer or '-n N' form.
#
# @stdout Table of PID, CPU%, and command name
# @exitcode 0 Always
cpuhogs() {
    local _wrap_limit _pid _cpu _cmd _lines _cpu_use
    # Capture the width of the terminal window
    _wrap_limit="${COLUMNS:-$(tput cols)}"
    # If we still don't have an answer, default to 80 columns
    _wrap_limit="${_wrap_limit:-80}"
    # Subtract plenty of space for the pid and percentage output
    _wrap_limit="$(( _wrap_limit - 26 ))"

    # Try to factor for a line count similar to 'head' or 'tail'
    case "${1}" in
    (-n)
        printf -- '%d' "${2}" >/dev/null 2>&1 && _lines="${2}"
    ;;
    (*)
        printf -- '%d' "${1}" >/dev/null 2>&1 && _lines="${1}"
    ;;
    esac

    # Loop through and parse the output of 'ps'
    while read -r _pid _cpu _cmd; do
        # Truncate $cmd so that it doesn't wrap multiple lines
        (( ${#_cmd} > _wrap_limit )) && _cmd="${_cmd:0:$_wrap_limit}..."

        # Truncate the float so that we have an integer to compare to
        _cpu_use="${_cpu%%.*}"
        # If we're over 20%, then print in red
        if (( _cpu_use >= 20 )); then
            _cpuhogs_print_fmt red "${_pid}" "${_cpu}" "${_cmd}"
        # Likewise, if we're over 10%, then print in yellow
        elif (( _cpu_use >= 10 )); then
            _cpuhogs_print_fmt yellow "${_pid}" "${_cpu}" "${_cmd}"
        # Otherwise, print in green
        else
            _cpuhogs_print_fmt green "${_pid}" "${_cpu}" "${_cmd}"
        fi
    done < <(ps -eo _pid,%_cpu,_cmd --sort=%_cpu | tail -n +2 | tail -n "${_lines:-10}")
}
