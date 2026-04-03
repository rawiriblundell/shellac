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
# Adapted from labbots/bash-utility (MIT) https://github.com/labbots/bash-utility
# and martinburger/bash-common-helpers (MIT) https://github.com/martinburger/bash-common-helpers

[ -n "${_SHELLAC_LOADED_utils_prompt+x}" ] && return 0
_SHELLAC_LOADED_utils_prompt=1

# @description Prompt the user for a text response, with an optional default value.
#   Loops until a non-empty response is given (or the default is accepted).
#   Pass "-" as the default to allow an explicitly empty response.
#
# @arg $1 string Prompt text
# @arg $2 string Default value (optional; use "-" to mean "empty is OK")
#
# @example
#   name=$(prompt_response "Enter your name" "World")
#   host=$(prompt_response "Hostname" "-")   # allows empty
#
# @stdout User's response (or default)
# @exitcode 0 Success; 2 Missing argument
prompt_response() {
  local def_arg response
  (( ${#} == 0 )) && { printf -- '%s\n' "prompt_response: missing argument" >&2; return 2; }
  def_arg="${2:-}"
  response=""
  while :; do
    printf -- '%s ? ' "${1}"
    [[ -n "${def_arg}" ]] && [[ "${def_arg}" != "-" ]] && printf -- '[%s] ' "${def_arg}"
    read -r response
    [[ -n "${response}" ]] && break
    if [[ -z "${response}" ]] && [[ -n "${def_arg}" ]]; then
      response="${def_arg}"
      break
    fi
  done
  [[ "${response}" = "-" ]] && response=""
  printf -- '%s\n' "${response}"
}

# @description Prompt for a password, echoing '*' per keystroke and supporting backspace.
#   Stores the result in the variable named by $1.
#   The variable is declared readonly after assignment to prevent accidental modification.
#
# @arg $1 string Name of variable to store the password in
# @arg $2 string Prompt text
#
# @example
#   prompt_password db_pass "Database password"
#   printf '%s\n' "${db_pass}"
#
# @exitcode 0 Success; 2 Missing arguments
prompt_password() {
  local var_name msg charcount char password
  (( ${#} < 2 )) && { printf -- '%s\n' "prompt_password: requires 2 arguments" >&2; return 2; }
  var_name="${1}"
  msg="${2}"
  charcount=0
  char=""
  password=""
  printf -- '%s: ' "${msg}"
  stty -echo
  while IFS= read -p "" -r -s -n 1 char; do
    if [[ "${char}" = $'\0' ]]; then
      break
    fi
    if [[ "${char}" = $'\177' ]]; then
      if (( charcount > 0 )); then
        (( charcount-- ))
        printf -- '\b \b'
        password="${password%?}"
      fi
    else
      (( charcount++ ))
      printf -- '*'
      password+="${char}"
    fi
  done
  stty echo
  printf -- '\n'
  # shellcheck disable=SC2229
  read -r "${var_name}" <<< "${password}"
  readonly "${var_name}"
}

# @description Prompt for an interactive yes/no confirmation. Reads a single
#   character; only 'y' or 'Y' returns 0. Supports an optional timeout via
#   -t or --timeout followed by a duration in seconds.
#
# @arg $1 string Optional: '-t' or '--timeout' followed by timeout in seconds
# @arg $2 int Optional: timeout in seconds (when using -t/--timeout)
# @arg $3 string Optional: custom prompt text (default: "Continue")
#
# @exitcode 0 User confirmed with 'y' or 'Y'
# @exitcode 1 Any other input, or timeout expired
prompt_confirm() {
  local _confirm_args
  case "${1}" in
    (-t|--timeout)
      _confirm_args=( -t "${2}" )
      set -- "${@:3}"
    ;;
  esac

  read "${_confirm_args[@]}" -rn 1 -p "${*:-Continue} [y/N]? "
  printf -- '%s\n' ""
  case "${REPLY}" in
    ([yY]) return 0 ;;
    (*)    return 1 ;;
  esac
}

# @description Alias for prompt_confirm.
confirm() { prompt_confirm "${@}"; }
