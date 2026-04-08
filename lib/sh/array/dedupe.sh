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

[ -n "${_SHELLAC_LOADED_array_dedupe+x}" ] && return 0
_SHELLAC_LOADED_array_dedupe=1
requires BASH4

# @description Print array elements with duplicates removed, preserving order.
#
# @arg $@ any Array elements passed as arguments
#
# @stdout Each unique element on its own line, in first-seen order
# @exitcode 0 Always
#
# @example
#   array_dedup 1 1 2 2 3 3 3
#   # => 1 2 3 (one per line)
#
#   arr=(red red green blue blue)
#   array_dedup "${arr[@]}"
#   # => red green blue (one per line)
array_dedup() {
    local -A _seen
    local _element
    for _element in "${@}"; do
        [[ -n "${_seen[${_element}]+x}" ]] && continue
        _seen["${_element}"]=1
        printf -- '%s\n' "${_element}"
    done
}
