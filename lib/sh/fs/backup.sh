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
  local src dst ts backup_dir
  src="${1:?file_backup: missing file argument}"
  [[ -f "${src}" ]] || { printf -- '%s\n' "file_backup: not a file: ${src}" >&2; return 1; }
  ts="$(date +%Y%m%d-%H%M%S)"
  if [[ -n "${SHELLAC_BACKUP_DIR:-}" ]]; then
    backup_dir="${SHELLAC_BACKUP_DIR}"
    dst="${backup_dir}/$(basename "${src}").bak.${ts}"
  else
    dst="${src}.bak.${ts}"
  fi
  cp -- "${src}" "${dst}" || return 1
  printf -- '%s\n' "${dst}"
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
  local src latest backup_dir pattern
  src="${1:?file_restore: missing file argument}"
  if [[ -n "${SHELLAC_BACKUP_DIR:-}" ]]; then
    backup_dir="${SHELLAC_BACKUP_DIR}"
    pattern="${backup_dir}/$(basename "${src}").bak.*"
  else
    pattern="${src}.bak.*"
  fi

  # Sort by modification time, take newest
  latest=
  while IFS= read -r -d '' f; do
    latest="${f}"
  done < <(find "$(dirname "${pattern}")" -maxdepth 1 \
    -name "$(basename "${pattern}")" -print0 2>/dev/null | sort -z)

  [[ -z "${latest}" ]] && { printf -- '%s\n' "file_restore: no backup found for: ${src}" >&2; return 1; }
  cp -- "${latest}" "${src}" || return 1
  printf -- '%s\n' "Restored ${src} from ${latest}"
}

# @description Return 0 if a backup (.bak.*) exists for the given file.
#
# @arg $1 string File path to check
#
# @exitcode 0 Backup exists; 1 No backup; 2 Missing argument
file_is_backed_up() {
  local src pattern backup_dir
  src="${1:?file_is_backed_up: missing file argument}"
  if [[ -n "${SHELLAC_BACKUP_DIR:-}" ]]; then
    backup_dir="${SHELLAC_BACKUP_DIR}"
    pattern="${backup_dir}/$(basename "${src}").bak.*"
  else
    pattern="${src}.bak.*"
  fi
  local _backup_file
  for _backup_file in ${pattern}; do
    [[ -f "${_backup_file}" ]] && return 0
  done
  return 1
}
