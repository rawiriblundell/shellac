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

[ -n "${_SHELLAC_LOADED_misc_brew+x}" ] && return 0
_SHELLAC_LOADED_misc_brew=1

# @description Check whether one or more Homebrew packages are installed.
#   Exits the process (exit 1) if brew itself is not found. Prints a status
#   line for each package and returns 1 if any package is missing.
#
# @arg $1 string One or more package names (space-separated or multiple args)
#
# @stdout One status line per package indicating installed or not
# @exitcode 0 All packages are installed
# @exitcode 1 One or more packages are not installed, or brew is not found
brew_is_installed() {
  local failcount
  failcount=0
  if ! command -v brew >/dev/null 2>&1; then
    printf -- '%s\n' "This script requires brew on a mac.  This wasn't found..." >&2
    return 1
  fi
  for brew_pkg in ${*:?Package unspecified}; do
    if brew list | grep -w "${brew_pkg}" >/dev/null 2>&1; then
      printf -- '%s\n' "${brew_pkg} appears to be installed"
    else
      printf -- '%s\n' "${brew_pkg} is not installed"
      (( failcount++ ))
    fi
  done
  (( failcount > 0 )) && return 1
}
