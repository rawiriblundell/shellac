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

[ -n "${_SHELLAC_LOADED_sys_sleep+x}" ] && return 0
_SHELLAC_LOADED_sys_sleep=1
requires BASH4

# @description Sleep for a given duration without calling the external sleep(1) command.
#   Uses read's -t timeout against a process-substituted null command, which keeps
#   the file descriptor alive for the full duration (unlike /dev/null which may
#   return EOF immediately).  Supports fractional seconds where bash does.
#
# @arg $1 number Duration in seconds (integer or decimal, e.g. 1, 0.5, 2.5)
#
# @exitcode 0 Always (read timeout is an expected non-zero exit; it is suppressed)
#
# @example
#   sys_sleep 1
#   sys_sleep 0.2
#   sys_sleep 30
sys_sleep() {
    read -rt "${1:?sys_sleep: duration required}" <> <(:) || :
}
