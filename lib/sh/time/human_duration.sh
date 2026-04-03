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
# Adapted from labbots/bash-utility (MIT) https://github.com/labbots/bash-utility

[ -n "${_SHELLAC_LOADED_time_human_duration+x}" ] && return 0
_SHELLAC_LOADED_time_human_duration=1

# @description Format a number of seconds as a human-readable duration string.
#
# @arg $1 int Number of seconds
#
# @example
#   time_human_duration 90061   # => "1 days 1 hours 1 minute(s) and 1 seconds"
#   time_human_duration 65      # => "1 minute(s) and 5 seconds"
#   time_human_duration 30      # => "30 seconds"
#
# @stdout Human-readable duration
# @exitcode 0 Success; 2 Missing argument
time_human_duration() {
  local _total_secs day hr min sec
  (( ${#} == 0 )) && { printf -- '%s\n' "time_human_duration: missing argument" >&2; return 2; }
  _total_secs="${1}"
  day="$(( _total_secs / 60 / 60 / 24 ))"
  hr="$(( _total_secs / 60 / 60 % 24 ))"
  min="$(( _total_secs / 60 % 60 ))"
  sec="$(( _total_secs % 60 ))"
  (( day > 0 )) && printf -- '%d days ' "${day}"
  (( hr > 0  )) && printf -- '%d hours ' "${hr}"
  (( min > 0 )) && printf -- '%d minute(s) ' "${min}"
  (( day > 0 || hr > 0 || min > 0 )) && printf -- 'and '
  printf -- '%d seconds\n' "${sec}"
}
