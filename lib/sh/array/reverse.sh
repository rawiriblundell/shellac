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
# Inspired by dylanaraps/pure-bash-bible (MIT) https://github.com/dylanaraps/pure-bash-bible

[ -n "${_SHELLAC_LOADED_array_reverse+x}" ] && return 0
_SHELLAC_LOADED_array_reverse=1

# @description Print array elements in reverse order.
#
# @arg $@ any Array elements passed as arguments
#
# @stdout Each element on its own line, last to first
# @exitcode 0 Always
#
# @example
#   array_reverse 1 2 3 4 5
#   # => 5 4 3 2 1 (one per line)
#
#   arr=(red blue green)
#   array_reverse "${arr[@]}"
#   # => green blue red (one per line)
array_reverse() {
    local -a _arr
    local _idx
    _arr=( "${@}" )
    for (( _idx = ${#_arr[@]} - 1; _idx >= 0; _idx-- )); do
        printf -- '%s\n' "${_arr[${_idx}]}"
    done
}
