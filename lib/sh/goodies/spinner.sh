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

[ -n "${_SHELLAC_LOADED_goodies_spinner+x}" ] && return 0
_SHELLAC_LOADED_goodies_spinner=1
#
# I believe I referenced this when creating this
# https://linuxgazette.net/168/misc/lg/two_cent_tip__bash_script_to_create_animated_rotating_mark.html

# @description Start an animated spinning cursor in the foreground (run in background
#   with &). Stores its PID in $SpinPID so end_spinner can stop it.
#
# @example
#   begin_spinner &
#   SpinPID="${!}"
#   some_long_task
#   end_spinner "$?"
#
# @exitcode 0 Always (loops indefinitely until killed)
begin_spinner() {
  local _spin_chars
  _spin_chars='/-\|'
  printf -- "%s" "Processing ${Host}, this might take a while... [ "
  tput sc
  while true; do
    printf -- '\b%.1s' "${_spin_chars}"
    _spin_chars=${_spin_chars#?}${_spin_chars%???}
    tput rc
    sleep 1
  done
}

# @description Stop the spinner started by begin_spinner and print a status message
#   based on the supplied exit code. Colour-coded if txtGrn/txtRed/txtRst are set.
#
# @arg $1 int Exit code from the task that was running: 0, 1, 2, 124, or other
#
# @exitcode 0 Always
end_spinner() {
  kill "${SpinPID}"
  wait "${SpinPID}" 2>/dev/null

  # Handle the task's exit code
  case "${1}" in
    (0)   printf -- '%s\n' "] ${txtGrn}Task finished successfully ${txtRst}" ;;
    (1)   printf -- '%s\n' "] ${txtRed}Task failed! ${txtRst}" ;;
    (2)   printf -- '%s\n' "] ${txtRed}Unable to connect! ${txtRst}" ;;
    (124) printf -- '%s\n' "] ${txtRed}Task timed out! ${txtRst}" ;;
    (*)   printf -- '%s\n' "] ${txtRed}Unknown failure encountered ${txtRst}" ;;
  esac
}
