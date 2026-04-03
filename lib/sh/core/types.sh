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

[ -n "${_SHELLAC_LOADED_core_types+x}" ] && return 0
_SHELLAC_LOADED_core_types=1

# @description Detect the apparent type of a value.
#   Classification order (most to least specific): empty, integer, float, bool, string.
#   Note: 0 and 1 classify as integer, not bool.
#
# @arg $1 string Value to classify
#
# @example
#   case "$(detect_type "${var}")" in
#     (integer) ...;;
#     (float)   ...;;
#     (bool)    ...;;
#     (empty)   ...;;
#     (string)  ...;;
#   esac
#
# @stdout One of: empty, integer, float, bool, string
# @exitcode 0 Always
detect_type() {
    [ -z "${1:-}" ] && { printf -- '%s\n' "empty"; return 0; }
    printf -- '%d' "${1}" >/dev/null 2>&1 && { printf -- '%s\n' "integer"; return 0; }
    printf -- '%f' "${1}" >/dev/null 2>&1 && { printf -- '%s\n' "float"; return 0; }
    case "${1}" in
        ([tT][rR][uU][eE]|[fF][aA][lL][sS][eE]|[yY][eE][sS]|[nN][oO]|[oO][nN]|[oO][fF][fF])
            printf -- '%s\n' "bool"; return 0 ;;
    esac
    printf -- '%s\n' "string"
}
