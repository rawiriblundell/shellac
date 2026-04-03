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

[ -n "${_SHELLAC_LOADED_core_trap+x}" ] && return 0
_SHELLAC_LOADED_core_trap=1

# @description Make Ctrl+C a no-op to prevent it killing the script.
#
# @exitcode 0 Always
no_ctrl_c() {
    # @internal
    _no_ctrl_c() { :; }
    trap _no_ctrl_c INT
}

# @description Append a command to an existing trap rather than replacing it.
#   Allows multiple callers to register cleanup handlers on the same signal
#   without clobbering each other.
#
# @arg $1 string The command to add to the trap
# @arg $2 string The signal name (e.g. EXIT, INT, TERM)
#
# @example
#   trap_add 'rm -f "${tmpfile}"' EXIT
#   trap_add 'printf "caught INT\n" >&2' INT
#
# @exitcode 0 Always
trap_add() {
    local _new_cmd
    local _signal
    local _existing
    _new_cmd="${1:?No command given}"
    _signal="${2:?No signal given}"
    _existing=$(trap -p "${_signal}" | awk -F"'" '{print $2}')
    if [ -n "${_existing}" ]; then
        trap -- "${_existing}; ${_new_cmd}" "${_signal}"
    else
        trap -- "${_new_cmd}" "${_signal}"
    fi
}
