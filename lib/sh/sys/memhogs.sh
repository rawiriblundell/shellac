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

[ -n "${_SHELLAC_LOADED_sys_memhogs+x}" ] && return 0
_SHELLAC_LOADED_sys_memhogs=1

# List processes by memory usage
# This is usually better handled by tools like top and sar

# With inspiration from https://gist.github.com/mlgill/b08b18fc1de2086d9c20

# @internal
_memhogs_print_fmt() {
    local print_fmt wrap_limit

    case "${1}" in
        (green)  print_fmt='\e[1;32m%s\t%4.2f%%\t%-s\e[0m\n'; shift 1 ;;
        (yellow) print_fmt='\e[1;33m%s\t%4.2f%%\t%s\e[0m\n'; shift 1 ;;
        (red)    print_fmt='\e[1;31m%s\t%4.2f%%\t%s\e[0m\n'; shift 1 ;;
        (*)      print_fmt='%s\t%4.2f%%\t%s\n' ;;
    esac

    # Override if we're not being run interactively
    [[ -t 1 ]] || print_fmt='%s\t%4.2f%%\t%s\n'

    # Print using the format that we've settled on
    # shellcheck disable=SC2059
    printf -- "${print_fmt}" "${@}"
}

# @description List processes sorted by memory usage, colour-coded by percentage.
#   Output is colour-coded: green (<10%), yellow (>=10%), red (>=20%).
#   Colours are suppressed when not running interactively.
#
# @arg $1 int Optional: number of processes to show (default: 10). Accepts bare
#   integer or '-n N' form.
#
# @stdout Table of PID, mem%, and command name
# @exitcode 0 Always
memhogs() {
    local wrap_limit pid mem cmd lines mem_use
    # Capture the width of the terminal window
    wrap_limit="${COLUMNS:-$(tput cols)}"
    # If we still don't have an answer, default to 80 columns
    wrap_limit="${wrap_limit:-80}"
    # Subtract plenty of space for the pid and percentage output
    wrap_limit="$(( wrap_limit - 26 ))"

    # Try to factor for a line count similar to 'head' or 'tail'
    case "${1}" in
    (-n)
        printf -- '%d' "${2}" >/dev/null 2>&1 && lines="${2}"
    ;;
    (*)
        printf -- '%d' "${1}" >/dev/null 2>&1 && lines="${1}"
    ;;
    esac

    # Loop through and parse the output of 'ps'
    while read -r pid mem cmd; do
        # Truncate $cmd so that it doesn't wrap multiple lines
        (( ${#cmd} > wrap_limit )) && cmd="${cmd:0:$wrap_limit}..."

        # Truncate the float so that we have an integer to compare to
        mem_use="${mem%%.*}"
        # If we're over 20%, then print in red
        if (( mem_use >= 20 )); then
            _memhogs_print_fmt red "${pid}" "${mem}" "${cmd}"
        # Likewise, if we're over 10%, then print in yellow
        elif (( mem_use >= 10 )); then
            _memhogs_print_fmt yellow "${pid}" "${mem}" "${cmd}"
        # Otherwise, print in green
        else
            _memhogs_print_fmt green "${pid}" "${mem}" "${cmd}"
        fi
    done < <(ps -eo pid,%mem,cmd --sort=%mem | tail -n +2 | tail -n "${lines:-10}")
}
