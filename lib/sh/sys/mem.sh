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

[ -n "${_SHELLAC_LOADED_sys_mem+x}" ] && return 0
_SHELLAC_LOADED_sys_mem=1

# @description Read a named field from /proc/meminfo and print its value in kB.
#
# @arg $1 string Field name (e.g. MemTotal, MemAvailable, SwapTotal)
# @stdout Value in kB
# @exitcode 0 Field found
# @exitcode 1 /proc/meminfo not readable
_mem_read() {
  local field
  field="${1:?No field specified}"
  if [[ ! -r /proc/meminfo ]]; then
    printf -- 'mem: /proc/meminfo not readable\n' >&2
    return 1
  fi
  awk -v f="${field}:" '$1 == f { print $2; exit }' /proc/meminfo
}

# @description Convert a kB value to the requested unit and print it.
#   With no flag, passes through kB unchanged.
#
# @arg $1 integer Value in kB
# @arg $2 string  Optional unit flag: -K/--kb, -M/--mb, -G/--gb
# @stdout Converted integer value
_mem_convert_kb() {
  local value
  local flag
  value="${1:?No value provided}"
  flag="${2:-}"
  case "${flag}" in
    (-K|--kb) printf -- '%s\n' "${value}" ;;
    (-M|--mb) printf -- '%s\n' "$(( value / 1024 ))" ;;
    (-G|--gb) printf -- '%s\n' "$(( value / 1024 / 1024 ))" ;;
    (*)       printf -- '%s\n' "${value}" ;;
  esac
}

# @description Print total physical RAM.
#
# @arg $1 string Optional unit flag: -K/--kb (default), -M/--mb, -G/--gb
# @stdout RAM total in the requested unit
# @exitcode 0 Success
# @exitcode 1 /proc/meminfo not readable
sys_mem_total() {
  local value
  value="$(_mem_read MemTotal)" || return 1
  _mem_convert_kb "${value}" "${1:-}"
}

# @description Print available RAM. Uses MemAvailable (kernel 3.14+), which
#   accounts for reclaimable pages and is more useful than MemFree for
#   "can I allocate more?" queries. Falls back to MemFree on older kernels.
#
# @arg $1 string Optional unit flag
# @stdout Available RAM in the requested unit
# @exitcode 0 Success
# @exitcode 1 /proc/meminfo not readable
sys_mem_available() {
  local value
  value="$(_mem_read MemAvailable)"
  if [[ -z "${value}" ]]; then
    value="$(_mem_read MemFree)" || return 1
  fi
  _mem_convert_kb "${value}" "${1:-}"
}

# @description Print used RAM (MemTotal - MemAvailable).
#
# @arg $1 string Optional unit flag
# @stdout Used RAM in the requested unit
# @exitcode 0 Success
# @exitcode 1 /proc/meminfo not readable
sys_mem_used() {
  local total
  local available
  total="$(_mem_read MemTotal)" || return 1
  available="$(_mem_read MemAvailable)"
  if [[ -z "${available}" ]]; then
    available="$(_mem_read MemFree)" || return 1
  fi
  _mem_convert_kb "$(( total - available ))" "${1:-}"
}

# @description Print free RAM (MemFree — genuinely unused pages).
#   Note: MemFree is typically much lower than MemAvailable; see sys_mem_available.
#
# @arg $1 string Optional unit flag
# @stdout Free RAM in the requested unit
# @exitcode 0 Success
# @exitcode 1 /proc/meminfo not readable
sys_mem_free() {
  local value
  value="$(_mem_read MemFree)" || return 1
  _mem_convert_kb "${value}" "${1:-}"
}

# @description Print RAM usage as a percentage (used / total * 100).
#
# @stdout Percentage with one decimal place, e.g. "34.2"
# @exitcode 0 Success
# @exitcode 1 /proc/meminfo not readable
sys_mem_percent() {
  local total
  local available
  total="$(_mem_read MemTotal)" || return 1
  available="$(_mem_read MemAvailable)"
  if [[ -z "${available}" ]]; then
    available="$(_mem_read MemFree)" || return 1
  fi
  awk -v total="${total}" -v available="${available}" \
    'BEGIN { printf "%.1f\n", (total - available) / total * 100 }'
}

# @description Dispatcher for RAM information sub-commands.
#   With no argument, prints a one-line summary.
#
# @arg $1 string Sub-command: total, available, used, free, percent
# @arg $2 string Optional unit flag for numeric sub-commands: -K, -M, -G
# @stdout Requested value, or summary line
# @exitcode 0 Always
sys_mem() {
  case "${1:-}" in
    (total)     sys_mem_total     "${2:-}" ;;
    (available) sys_mem_available "${2:-}" ;;
    (used)      sys_mem_used      "${2:-}" ;;
    (free)      sys_mem_free      "${2:-}" ;;
    (percent)   sys_mem_percent ;;
    (*)
      printf -- 'RAM: %sM total, %sM available (%s%% used)\n' \
        "$(sys_mem_total -M)" \
        "$(sys_mem_available -M)" \
        "$(sys_mem_percent)"
    ;;
  esac
}

# @description Print total swap space.
#
# @arg $1 string Optional unit flag: -K/--kb (default), -M/--mb, -G/--gb
# @stdout Swap total in the requested unit
# @exitcode 0 Success
# @exitcode 1 /proc/meminfo not readable
sys_swap_total() {
  local value
  value="$(_mem_read SwapTotal)" || return 1
  _mem_convert_kb "${value}" "${1:-}"
}

# @description Print used swap space (SwapTotal - SwapFree).
#
# @arg $1 string Optional unit flag
# @stdout Used swap in the requested unit
# @exitcode 0 Success
# @exitcode 1 /proc/meminfo not readable
sys_swap_used() {
  local total
  local free
  total="$(_mem_read SwapTotal)" || return 1
  free="$(_mem_read SwapFree)" || return 1
  _mem_convert_kb "$(( total - free ))" "${1:-}"
}

# @description Print free swap space.
#
# @arg $1 string Optional unit flag
# @stdout Free swap in the requested unit
# @exitcode 0 Success
# @exitcode 1 /proc/meminfo not readable
sys_swap_free() {
  local value
  value="$(_mem_read SwapFree)" || return 1
  _mem_convert_kb "${value}" "${1:-}"
}

# @description Print swap usage as a percentage (used / total * 100).
#   Returns 0.0 if no swap is configured.
#
# @stdout Percentage with one decimal place, e.g. "12.5"
# @exitcode 0 Always
# @exitcode 1 /proc/meminfo not readable
sys_swap_percent() {
  local total
  local free
  total="$(_mem_read SwapTotal)" || return 1
  free="$(_mem_read SwapFree)" || return 1
  if (( total == 0 )); then
    printf -- '0.0\n'
    return 0
  fi
  awk -v total="${total}" -v free="${free}" \
    'BEGIN { printf "%.1f\n", (total - free) / total * 100 }'
}

# @description Dispatcher for swap information sub-commands.
#   With no argument, prints a one-line summary.
#
# @arg $1 string Sub-command: total, used, free, percent
# @arg $2 string Optional unit flag for numeric sub-commands: -K, -M, -G
# @stdout Requested value, or summary line
# @exitcode 0 Always
sys_swap() {
  case "${1:-}" in
    (total)   sys_swap_total   "${2:-}" ;;
    (used)    sys_swap_used    "${2:-}" ;;
    (free)    sys_swap_free    "${2:-}" ;;
    (percent) sys_swap_percent ;;
    (*)
      printf -- 'Swap: %sM total, %sM used (%s%%)\n' \
        "$(sys_swap_total -M)" \
        "$(sys_swap_used -M)" \
        "$(sys_swap_percent)"
    ;;
  esac
}
