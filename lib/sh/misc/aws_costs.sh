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

[ -n "${_SHELLAC_LOADED_misc_aws_costs+x}" ] && return 0
_SHELLAC_LOADED_misc_aws_costs=1

# Requires GNU date, aws-cli and jq

# @description Calculate the last day of the current month using GNU date.
#   Starts from the 27th of the current month and increments until the day
#   rolls over, then returns the last valid date. Requires GNU date.
#
# @stdout Last day of the current month in YYYY-MM-DD format
# @exitcode 0 Always
aws_month_end() {
    local _date_int
    _date_int=$(date +%Y%m27)
    for (( i=0; i<4; i++ )); do
        _date_int=$(( _date_int + 1 ))
        date -d "${_date_int}" "+%Y-%m-%d" 2>/dev/null
    done | tail -n 1
}

last_month_start="$(date -d "last month" '+%Y-%m-01')"
# Could be "$(printf '%(%Y-%m-01)T\n' -1)" to spare a fork
current_month_start="$(date '+%Y-%m-01')"
last_month_end="$(date -d "${current_month_start} -1 day" '+%Y-%m-%d')" 
current_month_end="$(aws_month_end)"
current_month_end_minus1="$(date -d "${current_month_end} -1 day" '+%Y-%m-%d')"

# @description Retrieve AWS cost and usage for last month, grouped by service.
#   Filters to services with non-zero blended cost and outputs JSON.
#   Requires aws-cli and jq.
#
# @stdout JSON object of service names to blended cost, sorted by amount
# @exitcode 0 Success
# @exitcode 1 aws-cli or jq failed
aws_cost_last_month() {
    aws ce get-cost-and-usage \
        --time-period Start="${last_month_start}",End="${last_month_end}" \
        --granularity MONTHLY \
        --metrics USAGE_QUANTITY BLENDED_COST \
        --group-by Type=DIMENSION,Key=SERVICE | 
            jq '[ .ResultsByTime[].Groups[] | 
                select(.Metrics.BlendedCost.Amount > "0") | 
                { (.Keys[0]): .Metrics.BlendedCost } ] 
                | sort_by(.Amount) 
                | add
            '
}

# @description Retrieve AWS cost and usage for the current month to date, grouped by service.
#   Filters to services with non-zero blended cost and outputs JSON.
#   Requires aws-cli and jq.
#
# @stdout JSON object of service names to blended cost, sorted by amount
# @exitcode 0 Success
# @exitcode 1 aws-cli or jq failed
aws_cost_this_month() {
    aws ce get-cost-and-usage \
        --time-period Start="${current_month_start}",End="${current_month_end}" \
        --granularity MONTHLY \
        --metrics USAGE_QUANTITY BLENDED_COST \
        --group-by Type=DIMENSION,Key=SERVICE | 
            jq '[ .ResultsByTime[].Groups[] | 
                select(.Metrics.BlendedCost.Amount > "0") | 
                { (.Keys[0]): .Metrics.BlendedCost } ] 
                | sort_by(.Amount) 
                | add
            '
}

# @description Retrieve the AWS cost forecast for the remainder of the current month.
#   Requires aws-cli and jq.
#
# @stdout JSON forecast object from the AWS Cost Explorer API
# @exitcode 0 Success
# @exitcode 1 aws-cli or jq failed
aws_cost_forecast() {
    aws ce get-cost-forecast \
        --time-period Start="${current_month_end_minus1}",End="${current_month_end}" \
        --granularity MONTHLY \
        --metric AMORTIZED_COST |
            jq '.'
}
