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

[ -n "${_SHELLAC_LOADED_text_puts+x}" ] && return 0
_SHELLAC_LOADED_text_puts=1

# @description Portable echo replacement that wraps printf. Supports a subset of
#   echo flags (-e for escape sequences, -E to suppress them, -n/-end to suppress
#   the trailing newline) plus -j to output a JSON key-value pair. Named 'puts'
#   rather than overriding 'echo' because some shells protect their builtins.
#
# @arg $1 string Optional flag: -e, -E, -j, -n/--end, -en, -En, -ne, -nE
# @arg $2 string Content to print (remaining args passed through)
#
# @stdout Formatted string per the selected mode
# @exitcode 0 Always
puts() {
    case "${1}" in
        (-e)
            case "${2}" in
                (-n|--end) shift 2; printf -- '%b' "${*}" ;;
                (*)        shift; printf -- '%b\n' "${*}" ;;
            esac
        ;;
        (-E)
            case "${2}" in
                (-n|--end) shift 2; printf -- '%s' "${*}" ;;
                (*)        shift; printf -- '%s\n' "${*}" ;;
            esac
        ;;
        (-j)               shift; printf -- '{"%s": "%s"}\n' "${1}" "${2}" ;;
        (-n|--end)
            case "${2}" in
                (-e)       shift 2; printf -- '%b' "${*}" ;;
                (-E)       shift 2; printf -- '%s' "${*}" ;;
                (*)        shift; printf -- '%s' "${*}" ;;
            esac
        ;;
        (-en|-ne)          shift; printf -- '%b' "${*}" ;;
        (-En|-nE)          shift; printf -- '%s' "${*}" ;;
        (*)                printf -- '%s\n' "${*}" ;;
    esac
}

# Alternative implementation:
# puts() {
#     while (( "${#}" > 1 )); do
#         case "${1}" in
#             (-e)        _puts_fmt='%b' ;;
#             (-E)        _puts_fmt='%s' ;;
#             (-j)        _puts_fmt='{"%s": "%s"}' ;;
#             (-n|--end)  _puts_newlines='' ;;
#             (-en|-ne)   _puts_fmt='%b'; _puts_newlines='' ;;
#             (-En|nE)    _puts_fmt='%s'; _puts_newlines='' ;;
#             (--|*)      break ;;
#         esac
#         shift 1
#     done

#     # shellcheck disable=SC2059
#     printf -- "${_puts_fmt:-%b}${_puts_newlines:-\n}" "${*}"
#
#     unset -v _puts_fmt _puts_newlines
# }
