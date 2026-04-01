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

[ -n "${_SHELLAC_LOADED_line_indent+x}" ] && return 0
_SHELLAC_LOADED_line_indent=1

# @description Indent each line of input by n spaces (default: 2).
#   Reads from a file path or stdin.
#
# @arg $1 int Optional: number of spaces to indent (default: 2)
# @arg $2 string Optional: file path (default: stdin)
#
# @stdout Indented text
# @exitcode 0 Always
line_indent() {
  local _n _pad
  _n="${1:-2}"
  shift
  _pad="$(printf -- '%*s' "${_n}" '')"
  if [[ -r "${1}" ]]; then
    sed "s/^/${_pad}/" "${1}"
  else
    sed "s/^/${_pad}/"
  fi
}

# @description Alias for line_indent.
indent() {
  line_indent "${@}"
}

# @description Alias for line_indent.
str_indent() {
  line_indent "${@}"
}

# @description Alias for line_indent.
text_indent() {
  line_indent "${@}"
}
