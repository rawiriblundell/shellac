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

[ -n "${_SHELLAC_LOADED_fs_backup+x}" ] && return 0
_SHELLAC_LOADED_fs_backup=1

# @description Back up a file by copying it to <file>.bak.<timestamp>.
#   If SHELLAC_BACKUP_DIR is set, the backup is placed there instead.
#
# @arg $1 string File to back up
#
# @example
#   file_backup /etc/hosts            # creates /etc/hosts.bak.20240319-153045
#
# @stdout Path of the backup file
# @exitcode 0 Success; 1 Source file not found; 2 Missing argument
file_backup() {
  local _src _dst _ts _backup_dir
  _src="${1:?file_backup: missing file argument}"
  [[ -f "${_src}" ]] || { printf -- '%s\n' "file_backup: not a file: ${_src}" >&2; return 1; }
  _ts="$(date +%Y%m%d-%H%M%S)"
  if [[ -n "${SHELLAC_BACKUP_DIR:-}" ]]; then
    _backup_dir="${SHELLAC_BACKUP_DIR}"
    _dst="${_backup_dir}/$(basename "${_src}").bak.${_ts}"
  else
    _dst="${_src}.bak.${_ts}"
  fi
  cp -- "${_src}" "${_dst}" || return 1
  printf -- '%s\n' "${_dst}"
}

# @description Restore a file from its most recent .bak.* backup.
#   If SHELLAC_BACKUP_DIR is set, looks there for the backup.
#
# @arg $1 string Original file path
#
# @example
#   file_restore /etc/hosts    # restores from /etc/hosts.bak.<latest>
#
# @exitcode 0 Restored; 1 No backup found; 2 Missing argument
file_restore() {
  local _src _latest _backup_dir _pattern
  _src="${1:?file_restore: missing file argument}"
  if [[ -n "${SHELLAC_BACKUP_DIR:-}" ]]; then
    _backup_dir="${SHELLAC_BACKUP_DIR}"
    _pattern="${_backup_dir}/$(basename "${_src}").bak.*"
  else
    _pattern="${_src}.bak.*"
  fi

  # Sort by modification time, take newest
  _latest=
  while IFS= read -r -d '' f; do
    _latest="${f}"
  done < <(find "$(dirname "${_pattern}")" -maxdepth 1 \
    -name "$(basename "${_pattern}")" -print0 2>/dev/null | sort -z)

  [[ -z "${_latest}" ]] && { printf -- '%s\n' "file_restore: no backup found for: ${_src}" >&2; return 1; }
  cp -- "${_latest}" "${_src}" || return 1
  printf -- '%s\n' "Restored ${_src} from ${_latest}"
}

# @description Return 0 if a backup (.bak.*) exists for the given file.
#
# @arg $1 string File path to check
#
# @exitcode 0 Backup exists; 1 No backup; 2 Missing argument
file_is_backed_up() {
  local _src _pattern _backup_dir
  _src="${1:?file_is_backed_up: missing file argument}"
  if [[ -n "${SHELLAC_BACKUP_DIR:-}" ]]; then
    _backup_dir="${SHELLAC_BACKUP_DIR}"
    _pattern="${_backup_dir}/$(basename "${_src}").bak.*"
  else
    _pattern="${_src}.bak.*"
  fi
  local _backup_file
  for _backup_file in ${_pattern}; do
    [[ -f "${_backup_file}" ]] && return 0
  done
  return 1
}
