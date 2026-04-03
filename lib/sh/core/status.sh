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

[ -n "${_SHELLAC_LOADED_core_status+x}" ] && return 0
_SHELLAC_LOADED_core_status=1

# @description Test the exit status of the most recently run command against
#   a named or numeric expectation. Functionalises the common 'if [ $? = ... ]' idiom.
#
# @arg $1 string Expected result: y/yes/0/true for success, n/no/1/false for failure
#
# @example
#   somecommand
#   if status true; then
#
# @exitcode 0 Last command's status matches the expectation
# @exitcode 1 Last command's status does not match the expectation
cmd_status() {
    # shellcheck disable=SC2181
    case "${1}" in
        ([yY]*|0|true)  (( "${?}" == 0 )) ;;
        ([nN]*|1|false) (( "${?}" > 0 )) ;;
        (*)             return "${?}" ;;
    esac
}

# @description Return 0 if the last command succeeded (exit code 0). Alias shorthand for cmd_status().
#
# @exitcode 0 Last command succeeded
# @exitcode 1 Last command failed
cmd_status_true() {
    (( "${?}" == 0 ))
}

# @description Return 0 if the last command failed (exit code > 0). Alias shorthand for cmd_status().
#
# @exitcode 0 Last command failed
# @exitcode 1 Last command succeeded
cmd_status_false() {
    (( "${?}" > 0 ))
}
