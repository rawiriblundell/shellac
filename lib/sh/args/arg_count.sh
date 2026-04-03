# shellcheck shell=ksh

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

[ -n "${_SHELLAC_LOADED_args_arg_count+x}" ] && return 0
_SHELLAC_LOADED_args_arg_count=1

# @description Test whether the number of given parameters is correct.
#
# @arg $1 int Desired number of parameters
# @arg $2 int Actual number of parameters (usually "${#}")
#
# @exitcode 0 Correct number of parameters
# @exitcode 1 Wrong count or non-integer argument
arg_count() {
    local desired_count
    local actual_count

    if (( "${#}" != 2 )); then
        printf -- 'arg_count: %s\n' "requires exactly 2 arguments" >&2
        return 1
    fi

    desired_count="${1}"
    actual_count="${2}"

    case "${desired_count}" in
        (*[!0-9]*|'')
            printf -- 'arg_count: %s\n' "desired count '${desired_count}' is not a non-negative integer" >&2
            return 1
        ;;
    esac

    case "${actual_count}" in
        (*[!0-9]*|'')
            printf -- 'arg_count: %s\n' "actual count '${actual_count}' is not a non-negative integer" >&2
            return 1
        ;;
    esac

    if (( actual_count < desired_count )); then
        printf -- 'arg_count: %s\n' "not enough parameters supplied (got ${actual_count}, need ${desired_count})" >&2
        return 1
    fi

    if (( actual_count > desired_count )); then
        printf -- 'arg_count: %s\n' "too many parameters supplied (got ${actual_count}, need ${desired_count})" >&2
        return 1
    fi
}
