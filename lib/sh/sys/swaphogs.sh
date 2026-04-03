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

[ -n "${_SHELLAC_LOADED_sys_swaphogs+x}" ] && return 0
_SHELLAC_LOADED_sys_swaphogs=1

# List processes by swap usage

# Old version is short and sweet:
# {
#     for file in /proc/*/status; do
#       awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' "${file}" 2>/dev/null
#     done
# } | grep " kB$" | sort -k 2 -n | column -t
#
# The active code here is simply to align with memhogs and cpuhogs

# @internal
_swaphogs_get_proc_info() {
  local file
  {
      for file in /proc/*/status; do
        awk '/^Pid|VmSwap|Name/{printf $2 " "}END{ print ""}' "${file}" 2>/dev/null
      done
  } | sort -k 3 -n | tail -n "${1:-10}"
}

# @internal
_swaphogs_print_fmt() {
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

# @description List processes sorted by swap usage, colour-coded by percentage.
#   Reads from /proc/*/status. Output is colour-coded: green (<10%), yellow
#   (>=10%), red (>=20%). Colours are suppressed when not running interactively.
#
# @arg $1 int Optional: number of processes to show (default: 10). Accepts bare
#   integer or '-n N' form.
#
# @stdout Table of PID, swap%, and command name
# @exitcode 0 Always
swaphogs() {
  local wrap_limit swap swap_pct _swaphogs_swap_total lines swap_int cmd pid
  # Capture the width of the terminal window
  wrap_limit="${COLUMNS:-$(tput cols)}"
  # If we still don't have an answer, default to 80 columns
  wrap_limit="${wrap_limit:-80}"
  # Subtract plenty of space for the pid and percentage output
  wrap_limit="$(( wrap_limit - 26 ))"

  # Get our total swap
  _swaphogs_swap_total=$(
    awk '/SwapTotal/{print $2}' /proc/meminfo 2>/dev/null ||
      free | awk '/Swap:/{print $2}'
  )

  # Try to factor for a line count similar to 'head' or 'tail'
  case "${1}" in
    (-n)
      printf -- '%d' "${2}" >/dev/null 2>&1 && lines="${2}"
    ;;
    (*)
      printf -- '%d' "${1}" >/dev/null 2>&1 && lines="${1}"
    ;;
  esac

  while read -r cmd pid swap; do
    # Truncate $cmd so that it doesn't wrap multiple lines
    # /proc/*/status files almost always do this already FWIW
    (( ${#cmd} > wrap_limit )) && cmd="${cmd:0:$wrap_limit}..."

    # Calculate the percentage of swap being used
    # This case statement prevents divide-by-0
    case "${swap}" in
      ('') continue ;;
      (0)  swap_pct=0 ;;
      (*)  swap_pct="$(awk '{printf "%0.2f", ($1 / $2) * 100}' <<< "${swap} ${_swaphogs_swap_total}")" ;;
    esac

    # Truncate the float so that we have an integer to compare to
    swap_int="${swap_pct%%.*}"

    # If we're over 20%, then print in red
    if (( swap_int >= 20 )); then
        _swaphogs_print_fmt red "${pid}" "${swap_pct}" "${cmd}"
    # Likewise, if we're over 10%, then print in yellow
    elif (( swap_int >= 10 )); then
        _swaphogs_print_fmt yellow "${pid}" "${swap_pct}" "${cmd}"
    # Otherwise, print in green
    else
        _swaphogs_print_fmt green "${pid}" "${swap_pct}" "${cmd}"
    fi
  done < <(_swaphogs_get_proc_info "${lines}")
}
