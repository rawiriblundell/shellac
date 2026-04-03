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

[ -n "${_SHELLAC_LOADED_time_date_arithmetic+x}" ] && return 0
_SHELLAC_LOADED_time_date_arithmetic=1

# @description Add N days to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of days to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_days() {
  local _timestamp _day
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_days: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _day="${2:-1}"
  printf -- '%s\n' "$(( _timestamp + _day * 86400 ))"
}

# @description Add N weeks to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of weeks to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_weeks() {
  local _timestamp _week
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_weeks: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _week="${2:-1}"
  printf -- '%s\n' "$(( _timestamp + _week * 604800 ))"
}

# @description Add N months to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of months to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_months() {
  local _timestamp _month _new_timestamp
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_months: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _month="${2:-1}"
  _new_timestamp="$(date -d "$(date -d "@${_timestamp}" '+%F %T') +${_month} month" +'%s')" || return 1
  printf -- '%s\n' "${_new_timestamp}"
}

# @description Add N years to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of years to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_years() {
  local _timestamp _year _new_timestamp
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_years: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _year="${2:-1}"
  _new_timestamp="$(date -d "$(date -d "@${_timestamp}" '+%F %T') +${_year} year" +'%s')" || return 1
  printf -- '%s\n' "${_new_timestamp}"
}

# @description Add N hours to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of hours to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_hours() {
  local _timestamp _hour
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_hours: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _hour="${2:-1}"
  printf -- '%s\n' "$(( _timestamp + _hour * 3600 ))"
}

# @description Add N minutes to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of minutes to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_minutes() {
  local _timestamp _minute
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_minutes: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _minute="${2:-1}"
  printf -- '%s\n' "$(( _timestamp + _minute * 60 ))"
}

# @description Add N seconds to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of seconds to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_seconds() {
  local _timestamp _second
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_seconds: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _second="${2:-1}"
  printf -- '%s\n' "$(( _timestamp + _second ))"
}

# @description Subtract N days from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of days to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_days() {
  local _timestamp _day
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_days: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _day="${2:-1}"
  printf -- '%s\n' "$(( _timestamp - _day * 86400 ))"
}

# @description Subtract N weeks from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of weeks to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_weeks() {
  local _timestamp _week
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_weeks: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _week="${2:-1}"
  printf -- '%s\n' "$(( _timestamp - _week * 604800 ))"
}

# @description Subtract N months from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of months to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_months() {
  local _timestamp _month _new_timestamp
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_months: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _month="${2:-1}"
  _new_timestamp="$(date -d "$(date -d "@${_timestamp}" '+%F %T') ${_month} months ago" +'%s')" || return 1
  printf -- '%s\n' "${_new_timestamp}"
}

# @description Subtract N years from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of years to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_years() {
  local _timestamp _year _new_timestamp
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_years: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _year="${2:-1}"
  _new_timestamp="$(date -d "$(date -d "@${_timestamp}" '+%F %T') ${_year} years ago" +'%s')" || return 1
  printf -- '%s\n' "${_new_timestamp}"
}

# @description Subtract N hours from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of hours to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_hours() {
  local _timestamp _hour
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_hours: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _hour="${2:-1}"
  printf -- '%s\n' "$(( _timestamp - _hour * 3600 ))"
}

# @description Subtract N minutes from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of minutes to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_minutes() {
  local _timestamp _minute
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_minutes: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _minute="${2:-1}"
  printf -- '%s\n' "$(( _timestamp - _minute * 60 ))"
}

# @description Subtract N seconds from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of seconds to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_seconds() {
  local _timestamp _second
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_seconds: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _second="${2:-1}"
  printf -- '%s\n' "$(( _timestamp - _second ))"
}

# @description Format a Unix timestamp as a human-readable string.
# @arg $1 int Unix timestamp
# @arg $2 string strftime format string (default: "%F %T")
# @stdout Formatted date string
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_format() {
  local _timestamp _format _out
  (( ${#} == 0 )) && { printf -- '%s\n' "time_format: missing arguments" >&2; return 2; }
  _timestamp="${1}"
  _format="${2:-%F %T}"
  _out="$(date -d "@${_timestamp}" +"${_format}")" || return 1
  printf -- '%s\n' "${_out}"
}
