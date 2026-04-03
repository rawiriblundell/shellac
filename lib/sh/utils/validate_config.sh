
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

[ -n "${_SHELLAC_LOADED_utils_validate_config+x}" ] && return 0
_SHELLAC_LOADED_utils_validate_config=1

# @description Validate that a config file contains only shell-importable key=value
#   pairs. Blank lines and comment lines are ignored. Any line not in the form
#   'key=value' (alphanumeric characters only) causes a failure.
#
# @arg $1 string Path to the config file to validate
#
# @exitcode 0 All non-blank, non-comment lines are valid key=value pairs
# @exitcode 1 One or more invalid lines found
validate_config() {
  local _validate_config_file _validate_config_count

  _validate_config_file="${1:?No config file defined}"

  # Filter blank lines and comments
  # Then count lines that aren't in the x=y format
  _validate_config_count=$(
    grep -Ev "^#|^$" "${_validate_config_file}" |
      grep -Evc "^[a-zA-Z0-9]+={1}[a-zA-Z0-9]+$"
  )
  
  if (( _validate_config_count == 0 )); then
    return 0
  else
    return 1
  fi
}
