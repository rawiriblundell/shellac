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

[ -n "${_SHELLAC_LOADED_sys_hogs+x}" ] && return 0
_SHELLAC_LOADED_sys_hogs=1

include sys/cpuhogs
include sys/memhogs
include sys/swaphogs

# @description Show processes sorted by resource usage. With no argument, runs
#   all three reports (cpu, mem, swap) in sequence. Passes any trailing
#   arguments through to the underlying hog function (e.g. a line count).
#
# @arg $1 string Optional: cpu, mem, or swap to show a single report
# @arg $@ string Optional: arguments passed through to the hog function (e.g. 20)
#
# @example
#   sys_hogs          # all three reports
#   sys_hogs cpu      # CPU hogs only
#   sys_hogs mem 20   # top 20 memory hogs
#
# @stdout Tabular process list, colour-coded when stdout is a tty
# @exitcode 0 Always
# @exitcode 1 Unrecognised argument
sys_hogs() {
  case "${1:-}" in
    (cpu)  shift; cpuhogs "${@}" ;;
    (mem)  shift; memhogs "${@}" ;;
    (swap) shift; swaphogs "${@}" ;;
    ('')
      printf -- '%s\n' "CPU Hogs:"
      cpuhogs
      printf -- '\n'
      printf -- '%s\n' "Memory Hogs:"
      memhogs
      printf -- '\n'
      printf -- '%s\n' "Swap Hogs:"
      swaphogs
    ;;
    (*)
      printf -- 'Usage: sys_hogs [cpu|mem|swap] [count]\n' >&2
      return 1
    ;;
  esac
}
