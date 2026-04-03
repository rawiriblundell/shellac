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

[ -n "${_SHELLAC_LOADED_text_helmet+x}" ] && return 0
_SHELLAC_LOADED_text_helmet=1

# @description Protect header lines from being filtered by downstream pipes.
#   Reads stdin into an array, emits the first n lines (default: 1) to stderr,
#   and the remainder to stdout. This keeps header lines visible even when
#   stdout is piped to grep or similar filters.
#
# @arg $1 int Optional: number of header lines to protect (default: 1)
#
# @example
#   df -hP | helmet | grep shm
#   df -hP | helmet 2 | grep shm
#
# @stdout Input lines after the protected header lines
# @exitcode 0 Always
text_helmet() {
  local _count
  local _lines
  case "${1}" in
    (*[!0-9]*|'') ;;
    (*) _count="${1}"; shift ;;
  esac

  _count="${_count:-1}"

  mapfile -t _lines

  printf -- '%s\n' "${_lines[@]:0:_count}" >&2
  printf -- '%s\n' "${_lines[@]:_count}"
}

# @description Alias for text_helmet.
helmet() { text_helmet "${@}"; }
