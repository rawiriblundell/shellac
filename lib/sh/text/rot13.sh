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

[ -n "${_SHELLAC_LOADED_text_rot13+x}" ] && return 0
_SHELLAC_LOADED_text_rot13=1

# @description Apply ROT13 encoding to text. Accepts a file path, string argument, or stdin.
#
# @arg $1 string Optional: file path, or string to encode
#
# @stdout ROT13-encoded text
# @exitcode 0 Success
# @exitcode 1 No input given
rot13 () {
  # If parameter is a readable file, use that
  if [[ -r "${1}" ]]; then
    tr a-zA-Z n-za-mN-ZA-M < "${1}"
  # If a non-empty parameter is given, rot13 it as a string
  elif [[ -n "${1}" ]]; then
    tr a-zA-Z n-za-mN-ZA-M <<< "$*"
  # If stdin is piped, use that
  elif [[ ! -t 0 ]]; then
    tr a-zA-Z n-za-mN-ZA-M
  # Otherwise print usage
  else
    printf -- '%s\n' "Usage: rot13 [FILE|STDIN|STRING]"
    return 1
  fi
}
