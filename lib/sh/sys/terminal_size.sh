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

[ -n "${_SHELLAC_LOADED_sys_terminal_size+x}" ] && return 0
_SHELLAC_LOADED_sys_terminal_size=1

# @description Print the current terminal dimensions as rows and columns.
#   Tries $LINES/$COLUMNS, then tput, then stty, then a raw ANSI cursor probe
#   as a last resort.
#
# @stdout Two integers separated by a space: rows columns
# @exitcode 0 Always
sys_terminal_size() {
  local _rows _cols
  if (( ${#LINES} > 0 )) && (( ${#COLUMNS} > 0 )); then
    printf '%d %d\n' "${LINES}" "${COLUMNS}"
    return 0
  fi

  if command -v tput >/dev/null 2>&1; then
    _rows="$(tput lines 2>/dev/null || tput li)"
    _cols="$(tput cols 2>/dev/null || tput co)"
    printf -- '%d %d\n' "${_rows}" "${_cols}"
    return 0
  fi

  # I've looked at a few libraries in other languages
  # a number of them just shell-out to this!
  if command -v stty >/dev/null 2>&1; then
    stty size
    return 0
  fi

  # At this point, you're relegated to raw ANSI.
  # This is a best-efforts last-gasp method that maybe should kinda be right
  # '\e[6000;6000H' sets the cursor position to 6000,6000
  # i.e. some out of bounds position beyond the lower right
  # The cursor should find itself at the lowest right position
  # '\e[6n' performs a CPR (cursor position report)
  # This comes back like '^[[24;80R(PS1 printed here);80R' and isn't readily piped
  # We use IFS to strip '[' and ';' and split, delimit on 'R' and assign to our vars
  # May require a position save and restore to be added...
  # Note, also, that this isn't strict POSIX: POSIX read only specifies '-r'
  IFS='[;' read -p $'\e[6000;6000H\e[6n' -d R -rs _ _rows _cols _
  printf -- '%d %d\n' "${_rows}" "${_cols}"
}
