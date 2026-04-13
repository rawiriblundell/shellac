#!/bin/false
# shellcheck shell=bash

# Copyright 2024 Rawiri Blundell
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

[ -n "${_SHELLAC_LOADED_fs_dir+x}" ] && return 0
_SHELLAC_LOADED_fs_dir=1

# @description Compare two directories.
#
#   By default performs a quiet shallow comparison: checks whether the
#   immediate children of both directories are identical (by name only,
#   not content).  Returns 0 if identical, 1 if they differ.
#
#   Flags:
#     -r | --recursive  Recurse into subdirectories (uses diff -rq)
#     -v | --verbose    Print what differs instead of remaining silent
#
#   Combining -r and -v runs diff -rq and prints its output.
#   Combining -v alone prints added/removed names for shallow comparison.
#
# @arg $1 string Path to first directory
# @arg $2 string Path to second directory
#
# @stdout Nothing (quiet mode) or list of differences (verbose mode)
# @stderr Validation errors
# @exitcode 0 Directories are identical under the chosen mode
# @exitcode 1 Directories differ, or arguments are invalid
#
# @example
#   dir_compare /etc/skel /home/user      # quiet shallow
#   dir_compare -r /etc/skel /home/user   # quiet recursive
#   dir_compare -v /etc/skel /home/user   # verbose shallow
#   dir_compare -r -v /etc/skel /home/user  # verbose recursive
dir_compare() {
  local _recursive
  local _verbose
  local _dir1
  local _dir2
  local _entry
  local _children1
  local _children2
  _recursive=0
  _verbose=0

  # Parse flags — support both short and long forms
  while (( $# > 0 )); do
    case "${1}" in
      (-r|--recursive)
        _recursive=1
        shift
      ;;
      (-v|--verbose)
        _verbose=1
        shift
      ;;
      (-rv|-vr)
        _recursive=1
        _verbose=1
        shift
      ;;
      (--)
        shift
        break
      ;;
      (-*)
        printf -- '%s\n' "dir_compare: unknown option: ${1}" >&2
        return 1
      ;;
      (*)
        break
      ;;
    esac
  done

  _dir1="${1}"
  _dir2="${2}"

  if [[ -z "${_dir1}" || -z "${_dir2}" ]]; then
    printf -- '%s\n' "dir_compare: two directory arguments required" >&2
    return 1
  fi

  if [[ ! -d "${_dir1}" ]]; then
    printf -- '%s\n' "dir_compare: not a directory: ${_dir1}" >&2
    return 1
  fi

  if [[ ! -d "${_dir2}" ]]; then
    printf -- '%s\n' "dir_compare: not a directory: ${_dir2}" >&2
    return 1
  fi

  # Recursive modes delegate to diff -rq
  if (( _recursive == 1 )); then
    if (( _verbose == 1 )); then
      diff -rq -- "${_dir1}" "${_dir2}"
      return "${?}"
    else
      diff -rq -- "${_dir1}" "${_dir2}" >/dev/null 2>&1
      return "${?}"
    fi
  fi

  # Shallow comparison: collect immediate children (names only) via globs.
  # We capture both visible and hidden entries, excluding . and ..
  _children1=()
  _children2=()

  # shellcheck disable=SC2010
  # We use globs deliberately here — not parsing ls
  for _entry in "${_dir1}"/* "${_dir1}"/.[!.]*; do
    [[ -e "${_entry}" || -L "${_entry}" ]] || continue
    _children1+=( "${_entry##*/}" )
  done

  for _entry in "${_dir2}"/* "${_dir2}"/.[!.]*; do
    [[ -e "${_entry}" || -L "${_entry}" ]] || continue
    _children2+=( "${_entry##*/}" )
  done

  # Sort both arrays for deterministic comparison
  # Use printf | sort to avoid requiring mapfile with process substitution
  local _sorted1
  local _sorted2
  _sorted1="$(printf -- '%s\n' "${_children1[@]+"${_children1[@]}"}" | sort)"
  _sorted2="$(printf -- '%s\n' "${_children2[@]+"${_children2[@]}"}" | sort)"

  if [[ "${_sorted1}" = "${_sorted2}" ]]; then
    return 0
  fi

  if (( _verbose == 1 )); then
    # Show what is in dir1 but not dir2, and vice versa
    local _name
    local _found
    while IFS= read -r _name; do
      [[ -z "${_name}" ]] && continue
      _found=0
      while IFS= read -r _entry; do
        [[ "${_entry}" = "${_name}" ]] && { _found=1; break; }
      done <<< "${_sorted2}"
      (( _found == 0 )) && printf -- 'only in %s: %s\n' "${_dir1}" "${_name}"
    done <<< "${_sorted1}"

    while IFS= read -r _name; do
      [[ -z "${_name}" ]] && continue
      _found=0
      while IFS= read -r _entry; do
        [[ "${_entry}" = "${_name}" ]] && { _found=1; break; }
      done <<< "${_sorted1}"
      (( _found == 0 )) && printf -- 'only in %s: %s\n' "${_dir2}" "${_name}"
    done <<< "${_sorted2}"
  fi

  return 1
}
