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

[ -n "${_SHELLAC_LOADED_time_date_ordinal+x}" ] && return 0
_SHELLAC_LOADED_time_date_ordinal=1

# @description Wrapper around the system date(1) command that adds a %o format specifier
#   for ordinal day suffixes (st, nd, rd, th). All other format strings pass through unchanged.
#
# @arg $@ string date(1) arguments; use %o in the format string for the ordinal suffix
#
# @example
#   date '+%B %-d'    # => February 8
#   date '+%B %-d%o'  # => February 8th
#
# @stdout Formatted date string
# @exitcode 0 Always
date() {
  local _date_suffix
  case "${@}" in
    (*"%o"*) 
      declare -a args1
      declare -a args2
      while [[ -n "$1" ]]; do
        args2+=("$1")
        if [[ "${1:0:1}" != + ]]; then
          args1+=("$1")
        fi
        shift
      done
      case $(command date +%d "${args1[@]}") in
        (01|21|31) _date_suffix="st";;
        (02|22)    _date_suffix="nd";;
        (03|23)    _date_suffix="rd";;
        (*)        _date_suffix="th";;
      esac
      command date "${args2[@]}" | sed -e "s/%o/${_date_suffix}/g"
    ;;
    (*)
      command date "${@}"
    ;;
  esac
}
