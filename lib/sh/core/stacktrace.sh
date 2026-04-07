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
# Adapted from elibs/ebash (Apache-2.0) https://github.com/elibs/ebash

[ -n "${_SHELLAC_LOADED_core_stacktrace+x}" ] && return 0
_SHELLAC_LOADED_core_stacktrace=1
requires BASH43

# Note: this file requires bash (FUNCNAME, BASH_SOURCE, BASH_LINENO arrays).
# It is intentionally separate from core/debug to keep that file portable to
# ksh and other POSIX shells.  To integrate with the ERR trap in core/debug,
# load this file first and replace debug_err_handler's caller loop with a
# call to stacktrace().

# @description Print a human-readable call stack to stderr.
#   Frame 0 is the stacktrace function itself (always skipped).
#   Frame 1 is the caller of stacktrace.
#
# @arg $1 int Starting frame offset (default: 1, skip stacktrace itself)
#
# @example
#   my_function() {
#     stacktrace
#   }
#
# @stdout Call stack to stderr, one frame per line
# @exitcode 0 Always
stacktrace() {
  local _frame _offset
  _offset="${1:-1}"
  printf -- '%s\n' "--- Stack trace ---" >&2
  for (( _frame = _offset; _frame < ${#FUNCNAME[@]}; _frame++ )); do
    printf -- '  [%d] %s  %s:%d\n' \
      "$(( _frame - _offset ))" \
      "${FUNCNAME[${_frame}]:-main}" \
      "${BASH_SOURCE[${_frame}]:-unknown}" \
      "${BASH_LINENO[$(( _frame - 1 ))]}" >&2
  done
  printf -- '%s\n' "-------------------" >&2
}

# @description Populate a named array with call-stack frame strings.
#   Requires bash 4.3+ for namerefs.  Each element is "func  file:line".
#   Frame 0 is always stacktrace_array itself (skipped).
#
# @arg $1 string Name of the caller's array variable to populate
# @arg $2 int    Starting frame offset (default: 1)
#
# @example
#   declare -a frames
#   stacktrace_array frames
#   printf '%s\n' "${frames[@]}"
#
# @exitcode 0 Always; 1 Missing array name argument
stacktrace_array() {
  local -n _sta_out="${1:?stacktrace_array: missing array name argument}"
  local _offset _frame _entry
  _offset="${2:-1}"
  _sta_out=()
  for (( _frame = _offset; _frame < ${#FUNCNAME[@]}; _frame++ )); do
    _entry="$(printf -- '%s  %s:%d' \
      "${FUNCNAME[${_frame}]:-main}" \
      "${BASH_SOURCE[${_frame}]:-unknown}" \
      "${BASH_LINENO[$(( _frame - 1 ))]}")"
    _sta_out+=( "${_entry}" )
  done
}
