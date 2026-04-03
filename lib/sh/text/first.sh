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

[ -n "${_SHELLAC_LOADED_text_first+x}" ] && return 0
_SHELLAC_LOADED_text_first=1

# @description Return the first character, column, or line of input.
#   Without a subcommand, returns the first line from stdin or a file.
#
# @arg $1 string Optional: 'char', 'col'/'column', or 'row'/'line' to select what to return
# @arg $2 string Optional: file path (for col/row modes)
#
# @stdout First character, column, or line of the input
# @exitcode 0 Always
first() {
  local _line
  case "${1}" in
    (char)       shift 1; read -r _line; printf -- '%.1s' "${_line}" ;;
    (col|column) shift 1; awk '{print $1}' "${@}" ;;
    (row|line)   shift 1; head -n 1 "${@}" ;;
    (*)          head -n 1 "${@}" ;;
  esac
}

# @description Alias for first().
str_first() {
  first "${@}"
}

# @description Return the last character, column, or line of input.
#   Without a subcommand, returns the last line from stdin or a file.
#
# @arg $1 string Optional: 'char', 'col'/'column', or 'row'/'line' to select what to return
# @arg $2 string Optional: file path (for col/row modes)
#
# @stdout Last character, column, or line of the input
# @exitcode 0 Always
last() {
  local _line
  case "${1}" in
    (char)       shift 1; read -r _line; printf -- '%s' "${_line#"${_line%?}"}" ;;
    (col|column) shift 1; awk '{print $NF}' "${@}" ;;
    (row|line)   shift 1; tail -n 1 "${@}" ;;
    (*)          tail -n 1 "${@}" ;;
  esac
}

# @description Alias for last().
str_last() {
  last "${@}"
}
