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
# Adapted from timo-reymann/bash-tui-framework (Apache-2.0)
#   https://github.com/timo-reymann/bash-tui-framework

[ -n "${_SHELLAC_LOADED_goodies_tui_prompts+x}" ] && return 0
_SHELLAC_LOADED_goodies_tui_prompts=1

# @description Prompt the user for a line of text, with an optional default.
#
# @arg $1 string Prompt text
# @arg $2 string Default value (shown in brackets; used if input is empty)
#
# @example
#   name=$(tui_input "Your name" "Alice")
#
# @stdout User's input (or default)
# @exitcode 0 Always
tui_input() {
  local prompt default reply
  prompt="${1:-Input}"
  default="${2:-}"
  if [[ -n "${default}" ]]; then
    printf -- '%s [%s]: ' "${prompt}" "${default}" >&2
  else
    printf -- '%s: ' "${prompt}" >&2
  fi
  read -r reply
  printf -- '%s\n' "${reply:-${default}}"
}

# @description Prompt the user for a yes/no confirmation.
#   Returns 0 for yes, 1 for no.  Default is shown in brackets.
#
# @arg $1 string Question text
# @arg $2 string Default: "y" or "n" (default: "n")
#
# @example
#   if tui_confirm "Proceed?" y; then
#     do_the_thing
#   fi
#
# @exitcode 0 Yes; 1 No
tui_confirm() {
  local question default prompt reply
  question="${1:-Confirm?}"
  default="${2:-n}"
  case "${default,,}" in
    (y|yes) prompt="${question} [Y/n]: " ;;
    (*)     prompt="${question} [y/N]: " ;;
  esac
  printf -- '%s' "${prompt}" >&2
  read -r reply
  reply="${reply:-${default}}"
  case "${reply,,}" in
    (y|yes) return 0 ;;
    (*)     return 1 ;;
  esac
}

# @description Present a numbered list and prompt the user to choose one item.
#
# @arg $1 string Prompt text
# @arg $@ string List items (all arguments after $1)
#
# @example
#   colour=$(tui_list "Pick a colour" red green blue)
#
# @stdout The chosen item
# @exitcode 0 Valid choice made; 1 No items provided
tui_list() {
  local prompt choice num i
  prompt="${1:-Choose}"
  shift
  (( ${#} == 0 )) && { printf -- '%s\n' "tui_list: no items provided" >&2; return 1; }

  local -a items
  items=( "${@}" )
  local count="${#items[@]}"

  i=1
  for item in "${items[@]}"; do
    printf -- '  %d) %s\n' "${i}" "${item}" >&2
    (( i += 1 ))
  done

  while true; do
    printf -- '%s [1-%d]: ' "${prompt}" "${count}" >&2
    read -r choice
    printf -- '%d' "${choice}" >/dev/null 2>&1 || continue
    (( choice >= 1 && choice <= count )) || continue
    printf -- '%s\n' "${items[$(( choice - 1 ))]}"
    return 0
  done
}

# @description Present a checkbox list; user space-toggles items, Enter confirms.
#   Returns space-separated selected items on stdout.
#
# @arg $1 string Prompt text
# @arg $@ string List items
#
# @example
#   IFS=' ' read -r -a chosen <<< "$(tui_checkbox "Select features" auth logging metrics)"
#
# @stdout Space-separated selected items
# @exitcode 0 Always (empty string if nothing selected)
tui_checkbox() {
  local prompt i idx result
  prompt="${1:-Select (space to toggle, enter to confirm)}"
  shift
  (( ${#} == 0 )) && { printf -- '%s\n' "tui_checkbox: no items provided" >&2; return 1; }

  local -a items selected
  items=( "${@}" )
  # Initialise all to unchecked
  selected=()
  for (( i = 0; i < ${#items[@]}; i++ )); do
    selected+=( 0 )
  done

  while true; do
    # Redraw list
    printf -- '\n%s\n' "${prompt}" >&2
    for (( i = 0; i < ${#items[@]}; i++ )); do
      if (( selected[i] )); then
        printf -- '  [x] %d) %s\n' "$(( i + 1 ))" "${items[i]}" >&2
      else
        printf -- '  [ ] %d) %s\n' "$(( i + 1 ))" "${items[i]}" >&2
      fi
    done
    printf -- 'Number to toggle, or Enter to confirm: ' >&2
    read -r choice
    # Empty input = confirm
    [[ -z "${choice}" ]] && break
    printf -- '%d' "${choice}" >/dev/null 2>&1 || continue
    (( choice >= 1 && choice <= ${#items[@]} )) || continue
    idx=$(( choice - 1 ))
    if (( selected[idx] )); then
      selected[idx]=0
    else
      selected[idx]=1
    fi
  done

  result=''
  for (( i = 0; i < ${#items[@]}; i++ )); do
    (( selected[i] )) && result="${result:+${result} }${items[i]}"
  done
  printf -- '%s\n' "${result}"
}

# @description Prompt for a password (input hidden).
#
# @arg $1 string Prompt text (default: "Password")
#
# @stdout The entered password
# @exitcode 0 Always
tui_password() {
  local prompt reply
  prompt="${1:-Password}"
  printf -- '%s: ' "${prompt}" >&2
  read -r -s reply
  printf -- '\n' >&2
  printf -- '%s\n' "${reply}"
}

# @description Prompt for an integer within a range.
#
# @arg $1 string Prompt text
# @arg $2 int    Minimum value (default: 0)
# @arg $3 int    Maximum value (default: 100)
# @arg $4 int    Default value (default: minimum)
#
# @example
#   timeout=$(tui_range "Timeout seconds" 1 300 30)
#
# @stdout Chosen integer
# @exitcode 0 Always
tui_range() {
  local prompt lo hi default reply
  prompt="${1:-Enter a number}"
  lo="${2:-0}"
  hi="${3:-100}"
  default="${4:-${lo}}"

  while true; do
    printf -- '%s [%d-%d] (default %d): ' "${prompt}" "${lo}" "${hi}" "${default}" >&2
    read -r reply
    reply="${reply:-${default}}"
    printf -- '%d' "${reply}" >/dev/null 2>&1 || continue
    (( reply >= lo && reply <= hi )) && break
  done
  printf -- '%d\n' "${reply}"
}
