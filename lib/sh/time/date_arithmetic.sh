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
  local timestamp day
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_days: missing arguments" >&2; return 2; }
  timestamp="${1}"
  day="${2:-1}"
  printf -- '%s\n' "$(( timestamp + day * 86400 ))"
}

# @description Add N weeks to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of weeks to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_weeks() {
  local timestamp week
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_weeks: missing arguments" >&2; return 2; }
  timestamp="${1}"
  week="${2:-1}"
  printf -- '%s\n' "$(( timestamp + week * 604800 ))"
}

# @description Add N months to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of months to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_months() {
  local timestamp month new_timestamp
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_months: missing arguments" >&2; return 2; }
  timestamp="${1}"
  month="${2:-1}"
  new_timestamp="$(date -d "$(date -d "@${timestamp}" '+%F %T') +${month} month" +'%s')" || return 1
  printf -- '%s\n' "${new_timestamp}"
}

# @description Add N years to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of years to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_years() {
  local timestamp year new_timestamp
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_years: missing arguments" >&2; return 2; }
  timestamp="${1}"
  year="${2:-1}"
  new_timestamp="$(date -d "$(date -d "@${timestamp}" '+%F %T') +${year} year" +'%s')" || return 1
  printf -- '%s\n' "${new_timestamp}"
}

# @description Add N hours to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of hours to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_hours() {
  local timestamp hour
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_hours: missing arguments" >&2; return 2; }
  timestamp="${1}"
  hour="${2:-1}"
  printf -- '%s\n' "$(( timestamp + hour * 3600 ))"
}

# @description Add N minutes to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of minutes to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_minutes() {
  local timestamp minute
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_minutes: missing arguments" >&2; return 2; }
  timestamp="${1}"
  minute="${2:-1}"
  printf -- '%s\n' "$(( timestamp + minute * 60 ))"
}

# @description Add N seconds to a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of seconds to add (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_add_seconds() {
  local timestamp second
  (( ${#} == 0 )) && { printf -- '%s\n' "time_add_seconds: missing arguments" >&2; return 2; }
  timestamp="${1}"
  second="${2:-1}"
  printf -- '%s\n' "$(( timestamp + second ))"
}

# @description Subtract N days from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of days to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_days() {
  local timestamp day
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_days: missing arguments" >&2; return 2; }
  timestamp="${1}"
  day="${2:-1}"
  printf -- '%s\n' "$(( timestamp - day * 86400 ))"
}

# @description Subtract N weeks from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of weeks to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_weeks() {
  local timestamp week
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_weeks: missing arguments" >&2; return 2; }
  timestamp="${1}"
  week="${2:-1}"
  printf -- '%s\n' "$(( timestamp - week * 604800 ))"
}

# @description Subtract N months from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of months to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_months() {
  local timestamp month new_timestamp
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_months: missing arguments" >&2; return 2; }
  timestamp="${1}"
  month="${2:-1}"
  new_timestamp="$(date -d "$(date -d "@${timestamp}" '+%F %T') ${month} months ago" +'%s')" || return 1
  printf -- '%s\n' "${new_timestamp}"
}

# @description Subtract N years from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of years to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_years() {
  local timestamp year new_timestamp
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_years: missing arguments" >&2; return 2; }
  timestamp="${1}"
  year="${2:-1}"
  new_timestamp="$(date -d "$(date -d "@${timestamp}" '+%F %T') ${year} years ago" +'%s')" || return 1
  printf -- '%s\n' "${new_timestamp}"
}

# @description Subtract N hours from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of hours to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_hours() {
  local timestamp hour
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_hours: missing arguments" >&2; return 2; }
  timestamp="${1}"
  hour="${2:-1}"
  printf -- '%s\n' "$(( timestamp - hour * 3600 ))"
}

# @description Subtract N minutes from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of minutes to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_minutes() {
  local timestamp minute
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_minutes: missing arguments" >&2; return 2; }
  timestamp="${1}"
  minute="${2:-1}"
  printf -- '%s\n' "$(( timestamp - minute * 60 ))"
}

# @description Subtract N seconds from a Unix timestamp.
# @arg $1 int Unix timestamp
# @arg $2 int Number of seconds to subtract (default: 1)
# @stdout New Unix timestamp
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_sub_seconds() {
  local timestamp second
  (( ${#} == 0 )) && { printf -- '%s\n' "time_sub_seconds: missing arguments" >&2; return 2; }
  timestamp="${1}"
  second="${2:-1}"
  printf -- '%s\n' "$(( timestamp - second ))"
}

# @description Format a Unix timestamp as a human-readable string.
# @arg $1 int Unix timestamp
# @arg $2 string strftime format string (default: "%F %T")
# @stdout Formatted date string
# @exitcode 0 Success; 1 date error; 2 Missing arguments
time_format() {
  local timestamp format out
  (( ${#} == 0 )) && { printf -- '%s\n' "time_format: missing arguments" >&2; return 2; }
  timestamp="${1}"
  format="${2:-%F %T}"
  out="$(date -d "@${timestamp}" +"${format}")" || return 1
  printf -- '%s\n' "${out}"
}
