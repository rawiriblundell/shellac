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

[ -n "${_SHELLAC_LOADED_line_scroll+x}" ] && return 0
_SHELLAC_LOADED_line_scroll=1

# @description Print piped input line by line with a configurable delay between lines.
#   Reads from stdin only. Default delay is 1 second.
#
# @arg $1 int Optional: delay in seconds between lines (default: 1)
#
# @stdout Input lines printed one at a time with delays
# @exitcode 0 Always
line_scroll() {
  # Check that stdin isn't empty
  if [[ -t 0 ]]; then
    printf -- '%s\n' "Usage:  pipe | to | scroll [n]" ""
    printf -- '\t%s\n'  "Increment line by line through the output of other commands" "" \
      "Delay between each increment can be defined.  Default is 1 second."
    return 0
  fi

  # Default the sleep time to 1 second
  local _sleep_time
  _sleep_time="${1:-1}"

  # Now we output line by line with a sleep in the middle
  while read -r; do
    printf -- '%s\n' "${REPLY}"
    sleep "${_sleep_time}" 2>/dev/null || sleep 1
  done
}
