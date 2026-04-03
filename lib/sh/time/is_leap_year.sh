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
# Adapted from aks/bash-lib (MIT) https://github.com/aks/bash-lib
# Original author: Alan K. Stebbens <aks@stebbens.org>

[ -n "${_SHELLAC_LOADED_time_is_leap_year+x}" ] && return 0
_SHELLAC_LOADED_time_is_leap_year=1

# @description Test whether a given year is a leap year.
#   A year is a leap year if divisible by 4, except century years,
#   which must be divisible by 400.
#
# @arg $1 int Four-digit year
#
# @example
#   time_is_leap_year 2000  # => exit 0 (leap)
#   time_is_leap_year 1900  # => exit 1 (not leap)
#   time_is_leap_year 2024  # => exit 0 (leap)
#
# @exitcode 0 Is a leap year
# @exitcode 1 Not a leap year
# @exitcode 2 Missing argument
time_is_leap_year() {
  local _year
  (( ${#} == 0 )) && { printf -- '%s\n' "time_is_leap_year: missing argument" >&2; return 2; }
  _year="$(( 10#${1} ))"
  if (( _year % 4 == 0 && ( _year % 100 != 0 || _year % 400 == 0 ) )); then
    return 0
  fi
  return 1
}
