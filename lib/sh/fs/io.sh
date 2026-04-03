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

[ -n "${_SHELLAC_LOADED_fs_io+x}" ] && return 0
_SHELLAC_LOADED_fs_io=1

# @description Read an entire file to stdout with error handling.
#
# @arg $1 string Path to the file
#
# @stdout File contents
# @exitcode 0 Success
# @exitcode 1 File not found or not readable
fs_read_file() {
  local _path
  _path="${1:?fs_read_file: _path argument required}"
  if [[ ! -f "${_path}" ]]; then
    printf -- '%s\n' "fs_read_file: not a file: ${_path}" >&2
    return 1
  fi
  if [[ ! -r "${_path}" ]]; then
    printf -- '%s\n' "fs_read_file: permission denied: ${_path}" >&2
    return 1
  fi
  printf -- '%s\n' "$(<"${_path}")"
}

# @description Write content to a file, creating parent directories as needed.
#   Content may be supplied as a second argument or piped via stdin.
#   The file is created or overwritten.
#
# @arg $1 string Path to the file
# @arg $2 string Optional: content to write (if omitted, reads from stdin)
#
# @exitcode 0 Success
# @exitcode 1 Path is a directory, or parent directory could not be created
fs_write_file() {
  local _path _content _parent
  _path="${1:?fs_write_file: _path argument required}"

  if [[ -d "${_path}" ]]; then
    printf -- '%s\n' "fs_write_file: _path is a directory: ${_path}" >&2
    return 1
  fi

  _parent="${_path%/*}"
  if [[ -n "${_parent}" ]] && [[ ! -d "${_parent}" ]]; then
    if ! mkdir -p "${_parent}"; then
      printf -- '%s\n' "fs_write_file: could not create directory: ${_parent}" >&2
      return 1
    fi
  fi

  if (( ${#} >= 2 )); then
    printf -- '%s\n' "${2}" > "${_path}"
  else
    cat > "${_path}"
  fi
}

# @description Append a line to a file if it is not already present (idempotent).
#   Creates the file and parent directories if they do not exist.
#
# @arg $1 string Path to the file
# @arg $2 string Line to append
#
# @exitcode 0 Success (line added or already present)
# @exitcode 1 Missing arguments, or parent directory could not be created
fs_append_line() {
  local _path _line _parent
  _path="${1:?fs_append_line: _path argument required}"
  _line="${2:?fs_append_line: _line argument required}"

  _parent="${_path%/*}"
  if [[ -n "${_parent}" ]] && [[ ! -d "${_parent}" ]]; then
    if ! mkdir -p "${_parent}"; then
      printf -- '%s\n' "fs_append_line: could not create directory: ${_parent}" >&2
      return 1
    fi
  fi

  if [[ -f "${_path}" ]] && grep -qxF "${_line}" "${_path}" 2>/dev/null; then
    return 0
  fi
  printf -- '%s\n' "${_line}" >> "${_path}"
}

# @description Read a file into an indexed array, one element per line.
#   Blank lines and lines beginning with # are included as-is.
#   Defaults to FS_LINES as the target array name.
#
# @arg $1 string Optional: '-n <name>' to specify target array name
# @arg $2 string Path to the file (or $1 if -n not used)
#
# @example
#   fs_read_lines /etc/hosts
#   printf '%s\n' "${FS_LINES[@]}"
#
#   fs_read_lines -n hosts_lines /etc/hosts
#   printf '%s\n' "${hosts_lines[@]}"
#
# @exitcode 0 Success
# @exitcode 1 File not found or not readable
fs_read_lines() {
  local _arr_name _path
  _arr_name="FS_LINES"

  if [[ "${1}" = "-n" ]]; then
    _arr_name="${2:?fs_read_lines: -n requires an array name}"
    shift 2
  fi

  _path="${1:?fs_read_lines: _path argument required}"

  if [[ ! -f "${_path}" ]]; then
    printf -- '%s\n' "fs_read_lines: not a file: ${_path}" >&2
    return 1
  fi
  if [[ ! -r "${_path}" ]]; then
    printf -- '%s\n' "fs_read_lines: permission denied: ${_path}" >&2
    return 1
  fi

  local -n _fs_read_lines_target="${_arr_name}"
  # shellcheck disable=SC2034
  mapfile -t _fs_read_lines_target < "${_path}"
}
