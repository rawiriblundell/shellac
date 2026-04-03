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
# Adapted from dolpa/dolpa-bash-utils (Unlicense) https://github.com/dolpa/dolpa-bash-utils

[ -n "${_SHELLAC_LOADED_time_duration+x}" ] && return 0
_SHELLAC_LOADED_time_duration=1

# @description Convert a count of seconds into a human-readable duration string.
#   e.g. "1d 4h 3m 22s".  Seconds always shown; higher units shown only when non-zero.
#   With --compact, spaces between units are omitted: "1d4h3m22s".
#
# @arg $1 string Optional: --compact to omit spaces between units
# @arg $1 int    Seconds (non-negative integer)
#
# @example
#   time_duration 90               # => "1m 30s"
#   time_duration 3661             # => "1h 1m 1s"
#   time_duration 90061            # => "1d 1h 1m 1s"
#   time_duration --compact 3661   # => "1h1m1s"
#
# @stdout Human-readable duration string
# @exitcode 0 Always
time_duration() {
  local secs days hours mins sep
  sep=" "
  if [[ "${1:-}" = "--compact" ]]; then
    sep=""
    shift
  fi
  secs="${1:-0}"
  days=$(( secs / 86400 ))
  secs=$(( secs % 86400 ))
  hours=$(( secs / 3600 ))
  secs=$(( secs % 3600 ))
  mins=$(( secs / 60 ))
  secs=$(( secs % 60 ))

  if (( days > 0 )); then
    printf -- "%dd${sep}%dh${sep}%dm${sep}%ds\n" "${days}" "${hours}" "${mins}" "${secs}"
  elif (( hours > 0 )); then
    printf -- "%dh${sep}%dm${sep}%ds\n" "${hours}" "${mins}" "${secs}"
  elif (( mins > 0 )); then
    printf -- "%dm${sep}%ds\n" "${mins}" "${secs}"
  else
    printf -- '%ds\n' "${secs}"
  fi
}

# @description Compute elapsed seconds between two epoch timestamps, or between
#   a given epoch and now if only one argument is provided.
#   Result is always non-negative (absolute difference).
#
# @arg $1 int Start epoch (seconds since Unix epoch)
# @arg $2 int End epoch (default: current time)
#
# @example
#   time_diff_seconds 1700000000 1700003661   # => 3661
#   time_diff_seconds 1700000000              # => (seconds since that epoch)
#
# @stdout Elapsed seconds
# @exitcode 0 Always
time_diff_seconds() {
  local start end diff
  start="${1:?time_diff_seconds: missing start epoch}"
  end="${2:-$(date +%s)}"
  diff=$(( end - start ))
  (( diff < 0 )) && diff=$(( -diff ))
  printf -- '%d\n' "${diff}"
}
