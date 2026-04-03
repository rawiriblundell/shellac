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

[ -n "${_SHELLAC_LOADED_sys_cpu+x}" ] && return 0
_SHELLAC_LOADED_sys_cpu=1

# @description Print the number of physical CPU sockets.
#   Tries lscpu, then dmidecode, then /proc/cpuinfo; defaults to 1.
#   Note: /sys physical_package_id files are unreliable and are not used.
#
# @stdout Number of physical CPU sockets
# @exitcode 0 Always
sys_cpu_slots() {
  if command -v lscpu >/dev/null 2>&1; then
    lscpu | awk '/[Ss]ocket\(s\):/ { print $NF; exit }'
  elif dmidecode --type processor 2>/dev/null | grep -q "Status: Populated, Enabled"; then
    dmidecode --type processor | grep -c "Status: Populated, Enabled"
  elif grep -q "^physical id" /proc/cpuinfo; then
    grep "^physical id" /proc/cpuinfo | sort -u | wc -l
  else
    printf -- '1\n'
  fi
}

# @description Print the number of cores per socket.
#   Tries lscpu, then dmidecode, then /proc/cpuinfo; defaults to 1.
#   Note: /sys core_id files are unreliable and are not used.
#
# @stdout Number of cores per socket
# @exitcode 0 Always
sys_cpu_cores() {
  if command -v lscpu >/dev/null 2>&1; then
    lscpu | awk '/^Core\(s\) per socket:/ { print $NF; exit }'
  elif dmidecode --type processor 2>/dev/null | grep -q "Core Count"; then
    dmidecode --type processor | awk '/Core Count/ { print $NF; exit }'
  elif grep -q "cpu cores" /proc/cpuinfo; then
    awk '/cpu cores/ { print $NF; exit }' /proc/cpuinfo
  elif grep -q "^core id" /proc/cpuinfo; then
    grep "^core id" /proc/cpuinfo | sort -u | wc -l
  else
    printf -- '1\n'
  fi
}

# @description Print the number of enabled cores per socket, if determinable.
#   Only dmidecode exposes this detail; relevant for software licensed per enabled core.
#   Falls back to sys_cpu_cores when the information is unavailable.
#
# @stdout Number of enabled cores per socket
# @exitcode 0 Always
sys_cpu_cores_enabled() {
  if dmidecode --type processor 2>/dev/null | grep -q "Core Enabled"; then
    dmidecode --type processor | awk '/Core Enabled/ { print $NF; exit }'
  else
    sys_cpu_cores
  fi
}

# @description Print the number of hardware threads per core.
#   Tries lscpu, then /proc/cpuinfo thread/sibling counts, then /sys topology;
#   defaults to 1.
#
# @stdout Number of threads per core
# @exitcode 0 Always
sys_cpu_threads() {
  local sibling_count
  local core_count

  if command -v lscpu >/dev/null 2>&1 && lscpu 2>/dev/null | grep -q "^Thread(s) per core"; then
    lscpu | awk '/^Thread\(s\) per core:/ { print $NF; exit }'
  elif grep -q "Thread(s) per core:" /proc/cpuinfo; then
    awk '/Thread\(s\) per core:/ { print $NF; exit }' /proc/cpuinfo
  elif grep -q "siblings" /proc/cpuinfo; then
    sibling_count="$(awk '/siblings/ { print $NF; exit }' /proc/cpuinfo)"
    core_count="$(sys_cpu_cores)"
    if (( sibling_count > core_count )); then
      printf -- '%s\n' "$(( sibling_count / core_count ))"
    else
      printf -- '1\n'
    fi
  elif [[ -r /sys/devices/system/cpu/cpu0/topology/thread_siblings ]]; then
    sibling_count="$(awk -F ',' '{ printf NF; exit }' /sys/devices/system/cpu/cpu0/topology/thread_siblings)"
    core_count="$(sys_cpu_cores)"
    if (( sibling_count > core_count )); then
      printf -- '%s\n' "$(( sibling_count / core_count ))"
    else
      printf -- '1\n'
    fi
  else
    printf -- '1\n'
  fi
}

# @description Print the total vCPU count (slots x cores x threads).
#
# @stdout Total vCPU count
# @exitcode 0 Always
sys_cpu_count() {
  local slots
  local cores
  local threads
  slots="$(sys_cpu_slots)"
  cores="$(sys_cpu_cores)"
  threads="$(sys_cpu_threads)"
  printf -- '%s\n' "$(( slots * cores * threads ))"
}

# @description Print the CPU clock speed in MHz.
#   Tries lscpu, then /sys cpufreq, then parses the model name in /proc/cpuinfo.
#   Assumes all sockets run at the same speed.
#
# @stdout CPU speed in MHz (integer)
# @exitcode 0 Always
sys_cpu_mhz() {
  # Prefer static max frequency: cpufreq gives the rated max, not a scaled value.
  if [[ -r /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]]; then
    printf -- '%s\n' "$(( $(< /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq) / 1000 ))"
    return
  fi
  # Single pass through /proc/cpuinfo: try the embedded frequency in the model
  # name first (static), then fall back to the realtime 'cpu MHz' field.
  awk -F ': ' '
    /^model name/ {
      val = $NF
      if (val ~ /[0-9]GHz$/) { sub(/GHz$/, "", val); printf "%d\n", val * 1000; exit }
      if (val ~ /[0-9]MHz$/) { sub(/MHz$/, "", val); printf "%d\n", val;         exit }
    }
    /^cpu MHz/ { printf "%d\n", $NF; exit }
  ' /proc/cpuinfo
}

# @description Print the CPU vendor/manufacturer string from /proc/cpuinfo.
#   Assumes all sockets have the same vendor; only the first result is used.
#
# @stdout CPU vendor string, e.g. "GenuineIntel" or "AuthenticAMD"
# @exitcode 0 Always
sys_cpu_manufacturer() {
  if [[ -r /proc/cpuinfo ]]; then
    awk -F ': ' '/^vendor_id/ { print $2; exit }' /proc/cpuinfo
  fi
}

# @description Print the CPU model name string from /proc/cpuinfo.
#   Assumes all sockets have the same model; only the first result is used.
#
# @stdout CPU model name, e.g. "AMD Ryzen 7 PRO 6850U with Radeon Graphics"
# @exitcode 0 Always
sys_cpu_model() {
  if [[ -r /proc/cpuinfo ]]; then
    awk -F ': ' '/^model name/ { print $2; exit }' /proc/cpuinfo
  fi
}

# @description Dispatcher for CPU information sub-commands.
#   With no argument, prints a one-line summary.
#
# @arg $1 string Sub-command: slots, cores, cores-enabled, threads, count, mhz, manufacturer, model
# @stdout Requested value, or summary line
# @exitcode 0 Always
sys_cpu() {
  case "${1:-}" in
    (slots)         sys_cpu_slots ;;
    (cores)         sys_cpu_cores ;;
    (cores-enabled) sys_cpu_cores_enabled ;;
    (threads)       sys_cpu_threads ;;
    (count)         sys_cpu_count ;;
    (mhz)           sys_cpu_mhz ;;
    (manufacturer)  sys_cpu_manufacturer ;;
    (model)         sys_cpu_model ;;
    (*)
      printf -- '%s %s %sMHz (x%s)\n' \
        "$(sys_cpu_manufacturer)" \
        "$(sys_cpu_model)" \
        "$(sys_cpu_mhz)" \
        "$(sys_cpu_count)"
    ;;
  esac
}
