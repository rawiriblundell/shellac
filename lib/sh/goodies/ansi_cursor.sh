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
# Adapted from fidian/ansi (MIT) https://github.com/fidian/ansi

[ -n "${_SHELLAC_LOADED_goodies_ansi_cursor+x}" ] && return 0
_SHELLAC_LOADED_goodies_ansi_cursor=1

# @description Return 0 if the terminal supports ANSI escape sequences.
#   Checks TERM, COLORTERM, and whether stdout is a tty.
# @exitcode 0 Supported; 1 Not supported
ansi_is_supported() {
  [[ -t 1 ]] || return 1
  case "${TERM:-}" in
    (dumb|unknown|'') return 1 ;;
  esac
  return 0
}

# @description Move cursor up N lines.
# @arg $1 int Lines (default: 1)
ansi_cursor_up() {
  printf -- '\033[%dA' "${1:-1}"
}

# @description Move cursor down N lines.
# @arg $1 int Lines (default: 1)
ansi_cursor_down() {
  printf -- '\033[%dB' "${1:-1}"
}

# @description Move cursor forward (right) N columns.
# @arg $1 int Columns (default: 1)
ansi_cursor_forward() {
  printf -- '\033[%dC' "${1:-1}"
}

# @description Move cursor backward (left) N columns.
# @arg $1 int Columns (default: 1)
ansi_cursor_backward() {
  printf -- '\033[%dD' "${1:-1}"
}

# @description Move cursor to an absolute position (1-based row, col).
# @arg $1 int Row (default: 1)
# @arg $2 int Column (default: 1)
ansi_cursor_position() {
  printf -- '\033[%d;%dH' "${1:-1}" "${2:-1}"
}

# @description Save current cursor position (DECSC).
ansi_cursor_save() {
  printf -- '\033[s'
}

# @description Restore saved cursor position (DECRC).
ansi_cursor_restore() {
  printf -- '\033[u'
}

# @description Hide the cursor.
ansi_cursor_hide() {
  printf -- '\033[?25l'
}

# @description Show the cursor.
ansi_cursor_show() {
  printf -- '\033[?25h'
}

# @description Erase from cursor to end of line.
ansi_erase_to_eol() {
  printf -- '\033[K'
}

# @description Erase the entire current line.
ansi_erase_line() {
  printf -- '\033[2K'
}

# @description Erase from cursor to end of screen.
ansi_erase_to_eos() {
  printf -- '\033[J'
}

# @description Erase the entire visible screen (cursor stays).
ansi_erase_screen() {
  printf -- '\033[2J'
}

# @description Scroll terminal up N lines (new blank lines at bottom).
# @arg $1 int Lines (default: 1)
ansi_scroll_up() {
  printf -- '\033[%dS' "${1:-1}"
}

# @description Scroll terminal down N lines (new blank lines at top).
# @arg $1 int Lines (default: 1)
ansi_scroll_down() {
  printf -- '\033[%dT' "${1:-1}"
}

# @description Set the terminal window title (xterm-compatible).
# @arg $1 string Title string
ansi_title() {
  printf -- '\033]0;%s\007' "${1:-}"
}

# @description Ring the terminal bell.
ansi_bell() {
  printf -- '\007'
}

# @description Full terminal reset (RIS — Return to Initial State).
ansi_reset() {
  printf -- '\033c'
}
