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
# Provenance: https://raw.githubusercontent.com/rawiriblundell/dotfiles/master/.bashrc
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_utils_timeout+x}" ] && return 0
_SHELLAC_LOADED_utils_timeout=1

command -v timeout >/dev/null 2>&1 && return 0

# @description Step-in replacement for 'timeout' on systems that lack it.
#   Runs a command and kills it if it is still running after the given duration.
#   Duration suffix: s (seconds, default), m (minutes), h (hours), d (days).
#   Uses perl if available; otherwise uses a shell background process approach.
#
# @arg $1 string Duration with optional suffix, e.g. "30", "5m", "2h"
# @arg $2 string Command and arguments to run
#
# @exitcode 0 Command completed within the timeout
# @exitcode 1 Invalid duration argument
# @exitcode 77 Command timed out (perl path only)
timeout() {
  local _duration

  # $# should be at least 1, if not, print a usage message
  if (( $# == 0 )); then
    printf -- '%s\n' "Usage:  timeout DURATION COMMAND" ""
    printf -- '\t%s\n' \
      "Start COMMAND, and kill it if still running after DURATION." "" \
      "DURATION is an integer with an optional suffix:" \
      "  's'  for seconds (the default)" \
      "  'm' for minutes" \
      "  'h' for hours" \
      "  'd' for days" "" \
      "Note: This is a bash function that mimics the command 'timeout'"
    return 0
  fi

  # Is $1 good?  If so, sanitise and convert to seconds
  case "${1}" in
    (*[!0-9smhd]*|'')
      printf -- '%s\n' \
        "timeout: '${1}' is not valid.  Run 'timeout' for usage." >&2
      return 1
    ;;
    (*m)
      _duration="${1//[!0-9]/}"; _duration=$(( _duration * 60 ))
    ;;
    (*h)
      _duration="${1//[!0-9]/}"; _duration=$(( _duration * 60 * 60 ))
    ;;
    (*d)
      _duration="${1//[!0-9]/}"; _duration=$(( _duration * 60 * 60 * 24 ))
    ;;
    (*)
      _duration="${1//[!0-9]/}"
    ;;
  esac
  # shift so that the rest of the line is the command to execute
  shift

  # If 'perl' is available, it has a few pretty good one-line options
  # see: http://stackoverflow.com/q/601543
  if command -v perl >/dev/null 2>&1; then
    perl -e '$s = shift; $SIG{ALRM} = sub { kill INT => $p; exit 77 }; exec(@ARGV) unless $p = fork; alarm $s; waitpid $p, 0; exit ($? >> 8)' "${_duration}" "$@"
    #perl -MPOSIX -e '$SIG{ALRM} = sub { kill(SIGTERM, -$$); }; alarm shift; $exit = system @ARGV; exit(WIFEXITED($exit) ? WEXITSTATUS($exit) : WTERMSIG($exit));' "$@"

  # Otherwise we offer a shell based failover.
  # I tested a few, this one works nicely and is fairly simple
  # http://stackoverflow.com/a/24413646
  else
    # Run in a subshell to avoid job control messages
    ( "$@" &
      child=$! # Grab the PID of the COMMAND

      # Avoid default notification in non-interactive shell for SIGTERM
      trap -- "" SIGTERM
      ( sleep "${_duration}"
        kill "${child}"
      ) 2> /dev/null &

      wait "${child}"
    )
  fi
}
