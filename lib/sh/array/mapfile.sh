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

[ -n "${_SHELLAC_LOADED_array_mapfile+x}" ] && return 0
_SHELLAC_LOADED_array_mapfile=1
requires BASH43

command -v mapfile >/dev/null 2>&1 && return 0

# @description Step-in replacement for bash's 'mapfile' (readarray) builtin.
#   Reads lines from stdin into an indexed array. Strips trailing newlines by
#   default (equivalent to always running with -t). Exports MAPFILE as the
#   default array name; renames to the named array if one is given.
#   Note: -n, -s, and -u options from the real mapfile are not supported.
#
# @arg $1 string Optional: '-t' (accepted but ignored for compatibility)
# @arg $2 string Optional: target array name (default: MAPFILE)
#
# @exitcode 0 Always
mapfile() {
  local _arrName i IFS
  unset MAPFILE

  set -f        # Turn off globbing
  set +H        # Prevent parsing of '!' via history substitution

  # We use the behaviour of '-t' by default, so if it's given, skip it
  while getopts ":t" flags; do
    case "${flags}" in
      (t) :;; # Only here for compatibility
      (*) :;; # Dummy action
    esac
  done
  shift "$(( OPTIND - 1 ))"

  # If an argument is left, it's our array name, otherwise this
  # function will export an array named MAPFILE (as the real 'mapfile' does)
  _arrName="${1}"

  # Read all of the input
  i=0
  while IFS=$'\n' read -r; do
    MAPFILE[i]="${REPLY}"
    ((i++))
  done
  # Sometimes there's a trailing line in a while read loop, if so catch it
  [[ "${REPLY}" ]] && MAPFILE[i]="${REPLY}"

  export MAPFILE

  # Finally, rename the array if required.
  # eval is intentional: this fallback only runs when the mapfile builtin is
  # absent (bash < 4.0), which predates local -n namerefs (bash 4.3).
  if [[ -n "${_arrName}" ]]; then
    # shellcheck disable=SC2034
      eval "${_arrName}=( \"\${MAPFILE[@]}\" )"
  fi

  # Set f and H back to normal
  set +f
  set -H
}


# ################################################################################
# # NOTE: This function is a work in progress
# ################################################################################
# # If 'mapfile' is not available, offer it as a step-in function
# # Written as an attempt at http://wiki.bash-hackers.org/commands/builtin/mapfile?s[]=mapfile#to_do
# #   "Create an implementation as a shell function that's portable between Ksh, Zsh, and Bash
# #    (and possibly other bourne-like shells with array support)."

# # Potentially useful resources:
# # http://cfajohnson.com/shell/arrays/
# # https://stackoverflow.com/a/32931403
# # https://stackoverflow.com/a/64793921

# # Known issue: No traps!  This means IFS might be left altered if
# # the function is cancelled or fails in some way

# if ! command -v mapfile >/dev/null 2>&1; then
#   # This is simply the appropriate section of 'help mapfile', edited, as a function:
#   mapfilehelp() {
#     # Hey, this exercise is for an array-capable shell, so let's use an array for this!
#     # This gets around the mess of heredocs and tabbed indentation

#     # shellcheck disable=SC2054,SC2102
#     local mapfileHelpArray=(
#     "mapfile [-n count] [-s count] [-t] [-u fd] [array]"
#     "readarray [-n count] [-s count] [-t] [-u fd] [array]"
#     ""
#     "      Read  lines  from the standard input into the indexed array variable ARRAY, or"
#     "      from file descriptor FD if the -u option is supplied.  The variable MAPFILE"
#     "      is the default ARRAY."
#     ""
#     "      Options:"
#     "        -n     Copy at most count lines.  If count is 0, all lines are copied."
#     "        -s     Discard the first count lines read."
#     "        -t     Nothing.  This option is here only for drop-in compatibility"
#     "               'mapfile' behaviour without '-t' cannot be replicated, '-t' is almost"
#     "               always used, so we provide this dummy option for convenience"
#     "        -u     Read lines from file descriptor FD instead of the standard input."
#     ""
#     "      If not supplied with an explicit origin, mapfile will clear array before assigning to it."
#     ""
#     "      mapfile returns successfully unless an invalid option or option argument is supplied,"
#     "      ARRAY is invalid or unassignable, or if ARRAY is not an indexed array."
#     )
#     printf -- '%s\n' "${mapfileHelpArray[@]}"
#   }

#   mapfile() {
#     local elementCount elementDiscard fileDescr IFS
#     unset MAPFILE
#     # Handle our various options
#     while getopts ":hn:s:tu:" flags; do
#       case "${flags}" in
#         (h) mapfile-help; return 0;;
#         (n) elementCount="${OPTARG}";;
#         (s) elementDiscard="${OPTARG}";;
#         (t) :;; #Only here for compatibility
#         (u) fileDescr="${OPTARG}";;
#         (*) mapfile-help; return 1;;
#       esac
#     done
#     shift "$(( OPTIND - 1 ))"

#     IFS=$'\n'     # Temporarily set IFS to newlines
#     set -f        # Turn off globbing
#     set +H        # Prevent parsing of '!' via history substitution

#     # If a linecount is set, we build the array element by element
#     if [[ -n "${elementCount}" ]] && (( elementCount > 0 )); then
#       # First, if we're discarding elements:
#       for ((i=0;i<elementDiscard;i++)); do
#         read -r
#         echo "${REPLY}" >/dev/null 2>&1
#       done
#       # Next, read the input stream into MAPFILE
#       i=0
#       eof=
#       while (( i < elementCount )) && [[ -z "${eof}" ]]; do
#         read -r || eof=true
#         MAPFILE+=( "${REPLY}" )
#         (( i++ ))
#       done
#     # Otherwise we just read the whole lot in
#     else
#       while IFS= read -r; do
#         MAPFILE+=( "${REPLY}" )
#       done
#       [[ "${REPLY}" ]] && MAPFILE+=( "${REPLY}" )

#       # If elementDiscard is declared, then we can quickly reindex like so:
#       if [[ -n "${elementDiscard}" ]]; then
#         MAPFILE=( "${MAPFILE[@]:$elementDiscard}" )
#       fi
#     fi <&"${fileDescr:-0}"

#     # Finally, rename the array if required
#     # I would love to know a better way to handle this
#     if [[ -n "${1}" ]]; then
#       # shellcheck disable=SC2034
#       for element in "${MAPFILE[@]}"; do
#         eval "$1+=( \"\${element}\" )"
#       done
#     fi

#     # Set f and H back to normal
#     set +f
#     set -H
#   }
#   # And finally alias 'readarray'
#   alias readarray='mapfile'
# fi
