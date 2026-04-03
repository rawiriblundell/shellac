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

[ -n "${_SHELLAC_LOADED_misc_greet+x}" ] && return 0
_SHELLAC_LOADED_misc_greet=1

# @description Print a time-appropriate greeting (morning, afternoon, or evening).
#   Uses the current hour from `date`, or the value of the $DayGreet variable if set.
#
# @stdout "Good morning!", "Good afternoon!", or "Good evening!"
# @exitcode 0 Always
greet() {
  local greet_moment
  if (( "${DayGreet:-$(date +%H)}" >= 18 )); then
    greet_moment="evening"
  elif (( "${DayGreet:-$(date +%H)}" >= 12 )); then
    greet_moment="afternoon"
  else
    greet_moment="morning"
  fi
  printf -- 'Good %s!\n' "${greet_moment}"
}
