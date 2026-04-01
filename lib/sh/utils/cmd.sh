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

[ -n "${_SHELLAC_LOADED_utils_cmd+x}" ] && return 0
_SHELLAC_LOADED_utils_cmd=1

# @description Check whether one or more commands exist in PATH. With -v/--verbose,
#   prints the resolved path of each found command and an error for each missing one.
#   Without -v, suppresses all output and simply returns 0 or 1.
#
# @arg $1 string Optional: '-v' or '--verbose' to print paths and missing-command errors
# @arg $@ string One or more command names to check
#
# @example
#   cmd_check git curl jq
#   cmd_check --verbose git curl jq
#
# @stdout (verbose only) Path of each found command; error message for each missing one
# @exitcode 0 All specified commands were found
# @exitcode 1 One or more commands were not found
cmd_check() {
  local errcount cmd
  case "${1}" in
    (-v|--verbose)
      shift 1
      errcount=0
      for cmd in "${@}"; do
        command -v "${cmd}" ||
          { printf -- '%s\n' "${cmd} not found" >&2; (( ++errcount )); }
      done
      (( errcount == 0 )) && return 0
    ;;
    ('')
      printf -- 'Usage: cmd_check [-v|--verbose] <command> [command...]\n' >&2
      return 0
    ;;
    (*)
      errcount=0
      for cmd in "${@}"; do
        command -v "${cmd}" >/dev/null 2>&1 || (( ++errcount ))
      done
      (( errcount == 0 )) && return 0
    ;;
  esac
  return 1
}

# @description List all commands available in the current shell environment,
#   optionally filtered by one or more search strings. Multiple patterns are
#   OR-joined into a single ERE pass over compgen -c output.
#
# @arg $@ string Optional: one or more substrings or ERE patterns to filter by
#
# @example
#   cmd_list
#   cmd_list git aws
#
# @stdout Matching command names, one per line
# @exitcode 0 Always
cmd_list() {
  local IFS
  case "${1}" in
    ('') compgen -c ;;
    (*)
      IFS='|'
      compgen -c | grep -E "${*}"
    ;;
  esac
}

# @description Execute a command while logging its timestamp, output and exit code.
#   Uses colour when stdout is a terminal. Pass -e/--exit-on-fail to abort on error.
#
# @arg $1 string Optional: -e or --exit-on-fail to exit on non-zero return
# @arg $@ string The command and its arguments to execute
#
# @stdout Formatted execution log with timestamp, command output and exit code
# @exitcode 0 Command succeeded
# @exitcode 1 Command failed and -e/--exit-on-fail was given
cmd_exec() {
  local _die
  local _output
  local _exit_code

  _die=0
  case "${1}" in
    (-e|--exit-on-fail) _die=1; shift ;;
  esac

  if [ -t 1 ]; then
    printf '\e[7m====>Timestamp:\e[0m %s\n\e[7m====>Executing:\e[0m %s\n' \
      "$(date +%s)" "${*}"
  else
    printf -- '====>Timestamp: %s\n====>Executing: %s\n' \
      "$(date +%s)" "${*}"
  fi

  _output=$("${@}")
  _exit_code="${?}"

  if (( _exit_code == 0 )); then
    if [ -t 1 ]; then
      printf '\e[7m====>Output   :\e[0m\n%s\n\n\e[32;1m====>Exit Code\e[0m: %s\n\e[32;1m====>all be GOOD\e[0m\n' \
        "${_output}" "${_exit_code}"
    else
      printf -- '====>Output: %s\n\n====>Exit Code: %s\n====>all be GOOD\n' \
        "${_output}" "${_exit_code}"
    fi
  else
    if [ -t 1 ]; then
      printf '\e[31;1m====>Output   :\e[0m\n%s\n\e[31;1m====>Exit Code\e[0m: %s\n\e[31;1m====>in ERROR\e[0m\n' \
        "${_output}" "${_exit_code}"
    else
      printf -- '====>Output: %s\n====>Exit Code: %s\n====>in ERROR\n' \
        "${_output}" "${_exit_code}"
    fi
    (( _die )) && exit 1
  fi
  return 0
}
