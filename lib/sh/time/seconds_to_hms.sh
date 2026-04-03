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
# Adapted from jmooring/bash-function-library (Apache-2.0) https://github.com/jmooring/bash-function-library
# Original author: Joe Mooring

[ -n "${_SHELLAC_LOADED_time_seconds_to_hms+x}" ] && return 0
_SHELLAC_LOADED_time_seconds_to_hms=1

# @description Convert a number of seconds to HH:MM:SS format.
# @arg $1 int Non-negative integer number of seconds
# @stdout HH:MM:SS string, e.g. "01:23:45"
# @exitcode 0 Success; 1 Invalid input
time_seconds_to_hms() {
  local _seconds
  (( ${#} == 0 )) && { printf -- '%s\n' "time_seconds_to_hms: missing argument" >&2; return 1; }
  _seconds="${1}"
  if ! printf -- '%d' "${_seconds}" >/dev/null 2>&1 || (( _seconds < 0 )); then
    printf -- 'time_seconds_to_hms: expected non-negative integer, got: %s\n' "${_seconds}" >&2
    return 1
  fi
  printf -- '%02d:%02d:%02d\n' \
    "$(( _seconds / 3600 ))" \
    "$(( _seconds % 3600 / 60 ))" \
    "$(( _seconds % 60 ))"
}
