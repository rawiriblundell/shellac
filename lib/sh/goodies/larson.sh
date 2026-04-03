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

[ -n "${_SHELLAC_LOADED_goodies_larson+x}" ] && return 0
_SHELLAC_LOADED_goodies_larson=1

# @internal
_larson_reset() {
  tput sgr0     # Unset as many things that we've set as possible
  tput cnorm    # Display the cursor again
  printf '%s\n' ""
  exit 0
}

# Try to set things back the way they were, however we exit
trap _larson_reset HUP INT QUIT TERM EXIT

# @description Display a Larson scanner animation that sweeps left to right only,
#   then resets to the left. Width and speed are configurable. Loops until interrupted.
#   Named for Glen A. Larson, who developed this visual effect for the Cylons in
#   Battlestar Galactica and for KITT in Knight Rider.
#
# @arg $1 int Optional: number of characters wide (default: 3)
#
# @exitcode 0 Always (loops indefinitely until killed)
half_larson() {
  local _prog_width _sleep_time
  _prog_width="${1:-3}"
  _sleep_time="0.2"

  # GNU sleep can handle fractional seconds, non-GNU cannot
  # so we default to 1 second resolution in that scenario
  if ! sleep "${_sleep_time}" >/dev/null 2>&1; then
    _sleep_time=1
  fi

  tput sc                                      # Capture position
  tput civis                                   # Hide cursor
  tput dim                                     # Set base emphasis
  printf '%*s' "${_prog_width}" | tr ' ' "*"   # Setup base char width
  while true; do                               # Infinite loop
    tput rc                                    # Return to saved position
    for ((i=0;i<_prog_width;i++)); do          # Iterate horizontally
      for em in dim sgr0 bold sgr0 dim; do     # Emphasis sequence
        printf -- '%s' "$(tput "${em}")*"      # Output emphasised char
        sleep "${_sleep_time}"                 # Pause for effect
        tput cub1                              # Move left one char
      done
      tput cuf1                                # Move right one char
    done
  done
}

# @description Display a full Larson scanner animation that sweeps left to right
#   then right to left, continuously. Width and speed are configurable.
#
# @arg $1 int Optional: number of characters wide (default: 3)
#
# @exitcode 0 Always (loops indefinitely until killed)
full_larson() {
  local _prog_width _sleep_time
  _prog_width="${1:-3}"
  _sleep_time="0.2"

  # GNU sleep can handle fractional seconds, non-GNU cannot
  # so we default to 1 second resolution in that scenario
  if ! sleep "${_sleep_time}" >/dev/null 2>&1; then
    _sleep_time=1
  fi

  tput sc                                      # Capture position
  tput civis                                   # Hide cursor
  tput dim                                     # Set base emphasis
  printf '%*s' "${_prog_width}" | tr ' ' "*"   # Setup base char width
  while true; do                               # Infinite loop
    tput rc                                    # Return to saved position
    for ((i=0;i<_prog_width;i++)); do          # Iterate horizontally
      for em in dim sgr0 bold sgr0 dim; do     # Emphasis sequence
        printf -- '%s' "$(tput "${em}")*"      # Output emphasised char
        sleep "${_sleep_time}"                 # Pause for effect
        tput cub1                              # Move left one char
      done
      tput cuf1                                # Move right one char
    done
    tput cub1
    for ((i=_prog_width;i>0;i--)); do
      for em in dim sgr0 bold sgr0 dim; do
        printf -- '%s' "$(tput "${em}")*"
        sleep "${_sleep_time}"
        tput cub1
      done
      tput cub1
    done
  done
}
