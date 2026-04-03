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

[ -n "${_SHELLAC_LOADED_misc_nagios_output+x}" ] && return 0
_SHELLAC_LOADED_misc_nagios_output=1

# @description Emit a Nagios-formatted output line with status code and job name.
#   If the second argument contains '=', it is treated as performance data;
#   otherwise a '-' separator is inserted before the message.
#   $this_job is used as the service description. If not set by the caller,
#   defaults to the invoking script's basename.
#
# @arg $1 string Status code or prefix (e.g. 0, 1, 2, 3, P)
# @arg $2 string Message or performance data string
# @arg $@ string Optional: additional lines
#
# @stdout Nagios-formatted status line(s)
# @exitcode 0 Always
nagios_out() {
  local _job
  _job="${this_job:-${0##*/}}"
  if [[ "${2}" == *"="* ]]; then
    printf -- '%s\n' "${1} ${_job} ${2}" "${@:3}"
  else
    printf -- '%s\n' "${1} ${_job} - ${2}" "${@:3}"
  fi
}

# @description Emit a Nagios performance data output line, using nagios_long for multiple args.
#
# @arg $@ string Message or performance data
#
# @stdout Nagios-formatted output
# @exitcode 0 Always
nagios_auto() {
  if (( $# == 1 )); then
    nagios_out P "${*}"
  elif (( $# > 1 )); then
    nagios_out P "${@}" | nagios_long
  fi
}

# @description Emit a Nagios OK (status 0) output line.
#   Accepts -r/--return to return 0 after output, or -x/--exit to exit 0.
#
# @arg $1 string Optional: -r/--return or -x/--exit
# @arg $@ string Message or performance data
#
# @stdout Nagios OK output
# @exitcode 0 Always
nagios_ok() {
  local _return_mode _exit_mode
  case "${1}" in
    (-r|--return) _return_mode=true; shift ;;
    (-x|--exit)   _exit_mode=true;   shift ;;
  esac
  if (( $# == 1 )); then
    nagios_out 0 "${*}"
  elif (( $# > 1 )); then
    nagios_out 0 "${@}" | nagios_long
  fi
  [[ "${_return_mode}" = "true" ]] && return 0
  [[ "${_exit_mode}"   = "true" ]] && exit 0
}

# @description Emit a Nagios WARNING (status 1) output line.
#   Accepts -r/--return to return 1 after output, or -x/--exit to exit 1.
#
# @arg $1 string Optional: -r/--return or -x/--exit
# @arg $@ string Message or performance data
#
# @stdout Nagios WARNING output
# @exitcode 0 Always
nagios_warn() {
  local _return_mode _exit_mode
  case "${1}" in
    (-r|--return) _return_mode=true; shift ;;
    (-x|--exit)   _exit_mode=true;   shift ;;
  esac
  if (( $# == 1 )); then
    nagios_out 1 "${*}"
  elif (( $# > 1 )); then
    nagios_out 1 "${@}" | nagios_long
  fi
  [[ "${_return_mode}" = "true" ]] && return 1
  [[ "${_exit_mode}"   = "true" ]] && exit 1
}

# @description Emit a Nagios CRITICAL (status 2) output line.
#   Accepts -r/--return to return 2 after output, or -x/--exit to exit 2.
#
# @arg $1 string Optional: -r/--return or -x/--exit
# @arg $@ string Message or performance data
#
# @stdout Nagios CRITICAL output
# @exitcode 0 Always
nagios_crit() {
  local _return_mode _exit_mode
  case "${1}" in
    (-r|--return) _return_mode=true; shift ;;
    (-x|--exit)   _exit_mode=true;   shift ;;
  esac
  if (( $# == 1 )); then
    nagios_out 2 "${*}"
  elif (( $# > 1 )); then
    nagios_out 2 "${@}" | nagios_long
  fi
  [[ "${_return_mode}" = "true" ]] && return 2
  [[ "${_exit_mode}"   = "true" ]] && exit 2
}

# @description Emit a Nagios UNKNOWN (status 3) output line.
#   Accepts -r/--return to return 3 after output, or -x/--exit to exit 3.
#
# @arg $1 string Optional: -r/--return or -x/--exit
# @arg $@ string Message or performance data
#
# @stdout Nagios UNKNOWN output
# @exitcode 0 Always
nagios_unknown() {
  local _return_mode _exit_mode
  case "${1}" in
    (-r|--return) _return_mode=true; shift ;;
    (-x|--exit)   _exit_mode=true;   shift ;;
  esac
  if (( $# == 1 )); then
    nagios_out 3 "${*}"
  elif (( $# > 1 )); then
    nagios_out 3 "${@}" | nagios_long
  fi
  [[ "${_return_mode}" = "true" ]] && return 3
  [[ "${_exit_mode}"   = "true" ]] && exit 3
}

# @description Convert newlines to literal '\n' for Nagios multi-line output format.
#   Reads from stdin.
#
# @stdout Input with actual newlines replaced by the literal string \n
# @exitcode 0 Always
nagios_long() {
  sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'
}
