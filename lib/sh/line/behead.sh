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

[ -n "${_SHELLAC_LOADED_line_behead+x}" ] && return 0
_SHELLAC_LOADED_line_behead=1

# @description Remove the first n lines from stdin (default: 1).
#   Good for stripping header lines from command output.
#
# @arg $1 int Optional: number of lines to remove (default: 1)
#
# @stdout Input with leading lines removed
# @exitcode 0 Always
behead() {
  awk -v head="${1:-1}" '{if (NR>head) {print}}'
}
