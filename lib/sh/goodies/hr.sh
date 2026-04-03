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
  local _hr_height _hr_width
  command -v sys_terminal_size >/dev/null 2>&1 || return
# heredocs can't be indented unless you use dirty hard tabs
IFS= read -r _hr_height _hr_width << EOF
$(sys_terminal_size)
EOF
  printf -- '%s\n' "${_hr_width}"
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
  # Figure out if we're in an interactive shell, then try to figure the width
  case "${-}" in
    (*i*) _hr_width="${COLUMNS:-$(_hr_width_helper)}" ;;
  esac

  # Default to 60 chars wide
  _hr_width="${_hr_width:-60}"

  # shellcheck disable=SC2183
  printf -- '%*s\n' "${1:-$_hr_width}" | tr ' ' "${2:-#}"
}

# hr() {
#   case "${1}" in
#     (bar)
#       local color width
#       # Figure out the width of the terminal window
#       width="$(( "${COLUMNS:-$(tput cols)}" - 6 ))"
#       # Define our initial color code
#       color="$(_select_random_color)"
#       tput setaf "${color}"               # Set our color
#       printf -- '%s' "${blockAsc}"        # Print the ascending block sequence
#       for (( i=1; i<=width; ++i )); do    # Fill the gap with hard blocks
#         printf -- '%b' "${block100}"
#       done
#       printf -- '%s\n' "${blockDwn}"      # Print our descending block sequence
#       tput sgr0                           # Unset our color
#     ;;
#     (nocolor)
#       shift 1
#       # shellcheck disable=SC2183
#       printf -- '%*s\n' "${1:-$COLUMNS}" | tr ' ' "${2:-#}"
#     ;;
#     (*)
#       color="$(_select_random_color)"
#       tput setaf "${color}"
#       # shellcheck disable=SC2183
#       printf -- '%*s\n' "${1:-$COLUMNS}" | tr ' ' "${2:-#}"
#       tput sgr0
#     ;;
#   esac
# }

# Map out some block characters
# shellcheck disable=SC2034
block100="\xe2\x96\x88"  # u2588\0xe2 0x96 0x88 Solid Block 100%
block75="\xe2\x96\x93"   # u2593\0xe2 0x96 0x93 Dark shade 75%
block50="\xe2\x96\x92"   # u2592\0xe2 0x96 0x92 Half shade 50%
block25="\xe2\x96\x91"   # u2591\0xe2 0x96 0x91 Light shade 25%

# Put those block characters in ascending and descending triplets
block_asc="$(printf -- '%b\n' "${block25}${block50}${block75}")"
block_dwn="$(printf -- '%b\n' "${block75}${block50}${block25}")"


# Source: https://gist.github.com/hypergig/ea6a60469ab4075b2310b56fa27bae55
# Define an array of color numbers for the colors that are hardest to see on
# either a black or white terminal background
BLOCKED_COLORS=(0 1 7 9 11 {15..18} {154..161} {190..197} {226..235} {250..255})

# Define another array that is an inversion of the above
mapfile -t ALLOWED_COLORS < <(printf -- '%d\n' {0..255} "${BLOCKED_COLORS[@]}" | sort -n | uniq -u)

# @internal
_select_random_color() {
  local color
  # Define our initial color code
  color=$(( RANDOM % 255 ))
  # Ensure that our color code is an allowed one.  If not, regenerate until it is.
  until printf -- '%d\n' "${ALLOWED_COLORS[@]}" | grep -xq "${color}"; do
    color=$(( RANDOM % 255 ))
  done
  # Emit our selected color number
  printf -- '%d\n' "${color}"
}

# @description Print a colored block-character horizontal rule, suitable for PS1 prompts.
#   Uses a randomly selected visible color and Unicode block characters.
#
# @stdout A colored horizontal rule spanning the terminal width minus 6 columns
# @exitcode 0 Always
hrps1(){
  local color width
  # Figure out the width of the terminal window
  width="$(( "${COLUMNS:-$(tput cols)}" - 6 ))"
  # Define our initial color code
  color="$(_select_random_color)"
  tput setaf "${color}"               # Set our color
  printf -- '%s' "${block_asc}"       # Print the ascending block sequence
  for (( i=1; i<=width; ++i )); do    # Fill the gap with hard blocks
    printf -- '%b' "${block100}"
  done
  printf -- '%s\n' "${block_dwn}"     # Print our descending block sequence
  tput sgr0                           # Unset our color
}
