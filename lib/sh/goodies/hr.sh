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

[ -n "${_SHELLAC_LOADED_goodies_hr+x}" ] && return 0
_SHELLAC_LOADED_goodies_hr=1

# @internal
_hr_width_helper() {
  local _hr_width
  _hr_width="${COLUMNS:-$(tput cols)}"
  (( _hr_width > 0 )) || _hr_width=60
  printf -- '%d\n' "${_hr_width}"
}

# @description Write a horizontal line using any character.
#   In an interactive shell, defaults to the full terminal width.
#   Otherwise defaults to 60 columns. Characters with special shell meaning
#   must be escaped (e.g. 'hr 40 \&').
#
# @arg $1 int Optional: line width in columns (default: terminal width or 60)
# @arg $2 string Optional: fill character (default: #)
#
# @stdout A horizontal line of the specified character and width
# @exitcode 0 Always
hr() {
  local _hr_width
  case "${-}" in
    (*i*) _hr_width="$(_hr_width_helper)" ;;
  esac

  : "${_hr_width:=60}"

  # shellcheck disable=SC2183
  printf -- '%*s\n' "${1:-${_hr_width}}" | tr ' ' "${2:-#}"
}

# @internal
# Source: https://gist.github.com/hypergig/ea6a60469ab4075b2310b56fa27bae55
_select_random_color() {
  local -a _blocked_colors
  local -a _allowed_colors
  local _color_n

  _blocked_colors=(0 1 7 9 11 {15..18} {154..161} {190..197} {226..235} {250..255})

  _allowed_colors=()
  while IFS= read -r _color_n; do
    _allowed_colors+=( "${_color_n}" )
  done < <(printf -- '%d\n' {0..255} "${_blocked_colors[@]}" | sort -n | uniq -u)

  printf -- '%d\n' "${_allowed_colors[$(( RANDOM % ${#_allowed_colors[@]} ))]}"
}

# @description Print a colored block-character horizontal rule, suitable for PS1 prompts.
#   Uses a randomly selected visible color and Unicode block characters.
#
# @stdout A colored horizontal rule spanning the terminal width minus 6 columns
# @exitcode 0 Always
hrps1() {
  local _color _width
  local _block_asc _block100 _block_dwn

  _block_asc="$(printf -- '%b' '\xe2\x96\x91\xe2\x96\x92\xe2\x96\x93')"
  _block100="$(printf -- '%b' '\xe2\x96\x88')"
  _block_dwn="$(printf -- '%b' '\xe2\x96\x93\xe2\x96\x92\xe2\x96\x91')"

  _width="$(( $(_hr_width_helper) - 6 ))"
  _color="$(_select_random_color)"

  tput setaf "${_color}"
  printf -- '%s' "${_block_asc}"
  for (( i=1; i<=_width; ++i )); do
    printf -- '%b' "${_block100}"
  done
  printf -- '%s\n' "${_block_dwn}"
  tput sgr0
}
