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

[ -n "${_SHELLAC_LOADED_line_longest+x}" ] && return 0
_SHELLAC_LOADED_line_longest=1

# @description Return the longest line from stdin.
#
# @stdout The longest line read from stdin
# @exitcode 0 Always
longest() {
  local _lastreply
  _lastreply=''
  while read -r; do
    (( ${#REPLY} > ${#_lastreply} )) && _lastreply="${REPLY}"
  done
  printf -- '%s\n' "${_lastreply}"
}

