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
# Provenance: https://raw.githubusercontent.com/rawiriblundell/dotfiles/master/.bashrc
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_utils_repeat+x}" ] && return 0
_SHELLAC_LOADED_utils_repeat=1

# @description Execute a command a specified number of times.
#
# @arg $1 int Number of times to repeat the command
# @arg $2 string Command and arguments to execute
#
# @exitcode 0 All repetitions completed
# @exitcode 1 First argument is not a positive integer
repeat() {
  local _repeat_num
  # check that $1 is a digit, if not error out, if so, set the repeatNum variable
  case "${1}" in
    (*[!0-9]*|'') printf -- '%s\n' "[ERROR]: '${1}' is not a number.  Usage: 'repeat n command'"; return 1;;
    (*)           _repeat_num=$1;;
  esac
  # shift so that the rest of the line is the command to execute
  shift

  # Run the command in a while loop _repeat_num times
  for (( i=0; i<_repeat_num; i++ )); do
    "$@"
  done
}
