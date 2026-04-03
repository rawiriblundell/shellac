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

[ -n "${_SHELLAC_LOADED_sys_signals+x}" ] && return 0
_SHELLAC_LOADED_sys_signals=1

# @description Convert a signal number to its symbolic name (without SIG prefix).
#
# @arg $1 int Signal number (e.g. 15)
#
# @example
#   signame 15    # => TERM
#   signame 2     # => INT
#
# @stdout Signal name (e.g. TERM, INT, HUP)
# @exitcode 0 Known signal; 1 Unknown signal number
signame() {
  local _num
  _num="${1:?signame: missing signal number}"
  case "${_num}" in
    (0)  printf -- 'EXIT\n' ;;
    (1)  printf -- 'HUP\n'  ;;
    (2)  printf -- 'INT\n'  ;;
    (3)  printf -- 'QUIT\n' ;;
    (4)  printf -- 'ILL\n'  ;;
    (5)  printf -- 'TRAP\n' ;;
    (6)  printf -- 'ABRT\n' ;;
    (7)  printf -- 'BUS\n'  ;;
    (8)  printf -- 'FPE\n'  ;;
    (9)  printf -- 'KILL\n' ;;
    (10) printf -- 'USR1\n' ;;
    (11) printf -- 'SEGV\n' ;;
    (12) printf -- 'USR2\n' ;;
    (13) printf -- 'PIPE\n' ;;
    (14) printf -- 'ALRM\n' ;;
    (15) printf -- 'TERM\n' ;;
    (17) printf -- 'CHLD\n' ;;
    (18) printf -- 'CONT\n' ;;
    (19) printf -- 'STOP\n' ;;
    (20) printf -- 'TSTP\n' ;;
    (21) printf -- 'TTIN\n' ;;
    (22) printf -- 'TTOU\n' ;;
    (*)
      printf -- '%s\n' "signame: unknown signal number: ${_num}" >&2
      return 1
    ;;
  esac
}

# @description Convert a signal name (with or without SIG prefix) to its number.
#
# @arg $1 string Signal name (e.g. TERM, SIGTERM, term)
#
# @example
#   signum TERM      # => 15
#   signum SIGKILL   # => 9
#   signum int       # => 2
#
# @stdout Signal number
# @exitcode 0 Known signal; 1 Unknown name
signum() {
  local _name
  _name="${1:?signum: missing signal _name}"
  # Strip leading SIG (case-insensitive) and uppercase
  _name="${_name#[Ss][Ii][Gg]}"
  _name="${_name^^}"
  case "${_name}" in
    (EXIT) printf -- '0\n'  ;;
    (HUP)  printf -- '1\n'  ;;
    (INT)  printf -- '2\n'  ;;
    (QUIT) printf -- '3\n'  ;;
    (ILL)  printf -- '4\n'  ;;
    (TRAP) printf -- '5\n'  ;;
    (ABRT) printf -- '6\n'  ;;
    (BUS)  printf -- '7\n'  ;;
    (FPE)  printf -- '8\n'  ;;
    (KILL) printf -- '9\n'  ;;
    (USR1) printf -- '10\n' ;;
    (SEGV) printf -- '11\n' ;;
    (USR2) printf -- '12\n' ;;
    (PIPE) printf -- '13\n' ;;
    (ALRM) printf -- '14\n' ;;
    (TERM) printf -- '15\n' ;;
    (CHLD) printf -- '17\n' ;;
    (CONT) printf -- '18\n' ;;
    (STOP) printf -- '19\n' ;;
    (TSTP) printf -- '20\n' ;;
    (TTIN) printf -- '21\n' ;;
    (TTOU) printf -- '22\n' ;;
    (*)
      printf -- '%s\n' "signum: unknown signal _name: ${1}" >&2
      return 1
    ;;
  esac
}

# @description Return the shell exit code corresponding to death by a signal.
#   Exit code = 128 + signal number (POSIX convention).
#
# @arg $1 string|int Signal name or number
#
# @example
#   sigexitcode TERM    # => 143   (128 + 15)
#   sigexitcode 9       # => 137   (128 + 9)
#
# @stdout Exit code integer
# @exitcode 0 Always; 1 Unknown signal
sigexitcode() {
  local _num
  case "${1:-}" in
    ([0-9]|[0-9][0-9]) _num="${1}" ;;
    (*)
      _num="$(signum "${1}")" || return 1
    ;;
  esac
  printf -- '%d\n' "$(( 128 + _num ))"
}
