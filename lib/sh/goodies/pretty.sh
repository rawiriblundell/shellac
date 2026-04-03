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

[ -n "${_SHELLAC_LOADED_goodies_pretty+x}" ] && return 0
_SHELLAC_LOADED_goodies_pretty=1

# Source: https://gist.github.com/hypergig/ea6a60469ab4075b2310b56fa27bae55
# Define an array of color numbers for the colors that are hardest to see on
# either a black or white terminal background
_pretty_blocked_colors=(0 1 7 9 11 {15..18} {154..161} {190..197} {226..235} {250..255})

# Define another array that is an inversion of the above
mapfile -t _pretty_allowed_colors < <(printf -- '%d\n' {0..255} "${_pretty_blocked_colors[@]}" | sort -n | uniq -u)

# @internal
_pretty_select_random_color() {
  local _pretty_color
  # Define our initial color code
  _pretty_color=$(( RANDOM % 255 ))
  # Ensure that our color code is an allowed one.  If not, regenerate until it is.
  until printf -- '%d\n' "${_pretty_allowed_colors[@]}" | grep -xq "${_pretty_color}"; do
    _pretty_color=$(( RANDOM % 255 ))
  done
  # Emit our selected color number
  printf -- '%d\n' "${_pretty_color}"
}

# @description Print each line of input in a randomly selected visible color.
#   Only runs in interactive shells. Accepts a file path, string argument, or stdin.
#
# @arg $1 string Optional: file path or string to colorize
#
# @stdout Each line printed in a random 256-color foreground color
# @exitcode 0 Success
# @exitcode 1 Not running in an interactive shell
pretty () {
  # Check if we are in an interactive shell or not
  case "${-}" in
    (*i*) : ;;
    (*)   return 1 ;;
  esac

  # Check if we have any positional parameters
  if (( "${#}" > 0 )); then
    # If the first parameter is a readable file, process it line by line
    if [[ -r "${1}" ]]; then
      while read -r; do
        # shellcheck disable=SC2046
        printf -- "\033[38;5;%dm%s\033[0m\n" $(_pretty_select_random_color) "${REPLY}"
      done < "${1}"
      return 0
    # Otherwise, process the positional parameter(s) as a string
    else
      # shellcheck disable=SC2046
      printf -- "\033[38;5;%dm%s\033[0m\n" $(_pretty_select_random_color) "${*}"
      return 0
    fi
  fi

  # If we get to this point, then we're processing stdin line by line
  while read -r; do
    # shellcheck disable=SC2046
    printf -- "\033[38;5;%dm%s\033[0m\n" $(_pretty_select_random_color) "${REPLY}"
  done
  return 0
}
