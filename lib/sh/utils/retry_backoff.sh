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
# Adapted from cyberark/bash-lib (Apache-2.0) https://github.com/cyberark/bash-lib
# Adapted from dolpa/dolpa-bash-utils (Unlicense) https://github.com/dolpa/dolpa-bash-utils

[ -n "${_SHELLAC_LOADED_utils_retry_backoff+x}" ] && return 0
_SHELLAC_LOADED_utils_retry_backoff=1

# @description Retry a command with exponential backoff.
#   Waits 1s, 2s, 4s, 8s … up to SHELLAC_RETRY_MAX_WAIT seconds between attempts.
#   Default cap is 60 seconds.
#
# @arg $1 int   Maximum number of attempts (default: 5)
# @arg $@       Command and its arguments
#
# @example
#   cmd_retry_backoff 5 curl -sf https://example.com
#
# @exitcode 0 Command succeeded within attempts; 1 All attempts failed; 2 Missing command
cmd_retry_backoff() {
  local max_attempts attempt wait_secs max_wait
  max_attempts="${1:-5}"
  shift
  (( ${#} == 0 )) && { printf -- '%s\n' "cmd_retry_backoff: missing command" >&2; return 2; }
  max_wait="${SHELLAC_RETRY_MAX_WAIT:-60}"

  attempt=1
  wait_secs=1
  while (( attempt <= max_attempts )); do
    if "${@}"; then
      return 0
    fi
    if (( attempt < max_attempts )); then
      printf -- '%s\n' "cmd_retry_backoff: attempt ${attempt}/${max_attempts} failed; retrying in ${wait_secs}s" >&2
      sleep "${wait_secs}"
      wait_secs=$(( wait_secs * 2 ))
      (( wait_secs > max_wait )) && wait_secs="${max_wait}"
    fi
    (( attempt += 1 ))
  done
  printf -- '%s\n' "cmd_retry_backoff: command failed after ${max_attempts} attempts: ${*}" >&2
  return 1
}

# @description Retry a command with a constant wait interval until it succeeds.
#
# @arg $1 int   Maximum number of attempts (default: 5)
# @arg $2 int   Wait seconds between attempts (default: 5)
# @arg $@       Command and its arguments
#
# @example
#   cmd_retry_constant 10 3 ping -c1 192.168.1.1
#
# @exitcode 0 Command succeeded; 1 All attempts failed; 2 Missing command
cmd_retry_constant() {
  local max_attempts wait_secs attempt
  max_attempts="${1:-5}"
  wait_secs="${2:-5}"
  shift 2
  (( ${#} == 0 )) && { printf -- '%s\n' "cmd_retry_constant: missing command" >&2; return 2; }

  attempt=1
  while (( attempt <= max_attempts )); do
    if "${@}"; then
      return 0
    fi
    if (( attempt < max_attempts )); then
      printf -- '%s\n' "cmd_retry_constant: attempt ${attempt}/${max_attempts} failed; retrying in ${wait_secs}s" >&2
      sleep "${wait_secs}"
    fi
    (( attempt += 1 ))
  done
  printf -- '%s\n' "cmd_retry_constant: command failed after ${max_attempts} attempts: ${*}" >&2
  return 1
}

# @description Retry a command until it succeeds or a timeout is reached.
#   Polls every $2 seconds (default: 5).
#
# @arg $1 int   Timeout in seconds
# @arg $2 int   Poll interval in seconds (default: 5)
# @arg $@       Command and its arguments
#
# @example
#   cmd_retry_until 120 10 curl -sf http://localhost:8080/health
#
# @exitcode 0 Command succeeded; 1 Timeout reached; 2 Missing command
cmd_retry_until() {
  local timeout interval deadline now attempt
  if (( ${#} == 0 )); then
    printf -- '%s\n' "cmd_retry_until: missing timeout argument" >&2
    return 2
  fi
  timeout="${1}"
  interval="${2:-5}"
  (( $# >= 2 )) && shift 2 || shift 1
  (( ${#} == 0 )) && { printf -- '%s\n' "cmd_retry_until: missing command" >&2; return 2; }

  deadline=$(( $(date +%s) + timeout ))
  attempt=1
  while (( $(date +%s) < deadline )); do
    if "${@}"; then
      return 0
    fi
    printf -- '%s\n' "cmd_retry_until: attempt ${attempt} failed; retrying in ${interval}s" >&2
    sleep "${interval}"
    (( attempt += 1 ))
  done
  printf -- '%s\n' "cmd_retry_until: timed out after ${timeout}s: ${*}" >&2
  return 1
}
