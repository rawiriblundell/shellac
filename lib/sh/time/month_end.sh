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

[ -n "${_SHELLAC_LOADED_time_month_end+x}" ] && return 0
_SHELLAC_LOADED_time_month_end=1

# @description Calculate the last day of the current month using GNU date.
#   Starts from the 27th of the current month and increments until the day
#   rolls over, then returns the last valid date. Requires GNU date.
#
# @stdout Last day of the current month in YYYY-MM-DD format
# @exitcode 0 Always
time_month_end() {
    local _date_int
    _date_int=$(date +%Y%m27)
    for (( i=0; i<4; i++ )); do
        _date_int=$(( _date_int + 1 ))
        date -d "${_date_int}" "+%Y-%m-%d" 2>/dev/null
    done | tail -n 1
}
