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

[ -n "${_SHELLAC_LOADED_utils_watch+x}" ] && return 0
_SHELLAC_LOADED_utils_watch=1

command -v watch >/dev/null 2>&1 && return 0

# @description Step-in replacement for watch(1) on systems that lack it.
#   Repeatedly clears the screen and runs the given command, displaying
#   a header line with the command and current timestamp (unless -t is set).
#
#   Piped or compound commands must be quoted as a single string:
#   watch 'ps aux | head'
#
# @option -h         Print usage and return
# @option -n seconds Seconds between updates (default: 2)
# @option -t         Suppress the header line
# @option -v         Print version information and return
# @arg $@ string     Command to run
#
# @example
#   watch df -h
#   watch -n 5 uptime
#   watch -t 'ps aux | head'
#
# @exitcode 0 Loop terminated (e.g. by Ctrl-C); or -h/-v flag
# @exitcode 1 Invalid option or no command given
watch() {
  local _opt _col_width _title_head _sleep_time _date_now
  local OPTIND

  while getopts ":hn:tv" _opt; do
    case "${_opt}" in
      (h)
        printf -- '%s\n' \
          "Usage: watch [-hntv] <command>" "" \
          "Options:" \
          "  -h  Print this help" \
          "  -n  Seconds to wait between updates (default: 2)" \
          "  -t  Suppress the header line" \
          "  -v  Print version information"
        return 0
      ;;
      (n)  _sleep_time="${OPTARG}" ;;
      (t)  _title_head=false ;;
      (v)
        printf -- '%s\n' "watch: shell step-in, active because watch(1) was not found in PATH"
        return 0
      ;;
      (\?)
        printf -- '%s\n' "watch: unsupported option '-${OPTARG}'" >&2
        return 1
      ;;
      (:)
        printf -- '%s\n' "watch: option '-${OPTARG}' requires an argument" >&2
        return 1
      ;;
    esac
  done
  shift "$(( OPTIND - 1 ))"

  : "${_sleep_time:=2}"
  : "${_title_head:=true}"

  if [[ -z "${*}" ]]; then
    printf -- '%s\n' "watch: no command given" >&2
    return 1
  fi

  while true; do
    clear
    if [[ "${_title_head}" = "true" ]]; then
      _date_now="$(date)"
      _col_width="$(( $(tput cols) - ${#_date_now} ))"
      printf -- '%s%*s' "Every ${_sleep_time}s: ${*}" "${_col_width}" "${_date_now}"
      tput sgr0
      printf -- '\n\n'
    fi
    "${SHELL:-sh}" -c "${*}"
    sleep "${_sleep_time}"
  done
}
