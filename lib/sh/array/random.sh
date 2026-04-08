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
# Adapted from dylanaraps/pure-bash-bible (MIT) https://github.com/dylanaraps/pure-bash-bible

[ -n "${_SHELLAC_LOADED_array_random+x}" ] && return 0
_SHELLAC_LOADED_array_random=1

# @description Select a random element from an array.
#   Uses $RANDOM, which produces values 0–32767.  For arrays larger
#   than 32767 elements the distribution will be skewed; use a different
#   approach in that case.
#
# @arg $@ any Array elements passed as arguments
#
# @stdout One randomly selected element
# @exitcode 0 Always
# @exitcode 1 No arguments given
#
# @example
#   array_random_element red green blue yellow brown
#   # => yellow (random)
#
#   arr=(one two three)
#   array_random_element "${arr[@]}"
array_random_element() {
    if (( ${#} == 0 )); then
        printf -- '%s\n' "array_random_element: no arguments given" >&2
        return 1
    fi
    local -a _arr
    _arr=( "${@}" )
    printf -- '%s\n' "${_arr[RANDOM % ${#_arr[@]}]}"
}
