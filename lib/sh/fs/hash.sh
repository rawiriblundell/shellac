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

[ -n "${_SHELLAC_LOADED_fs_hash+x}" ] && return 0
_SHELLAC_LOADED_fs_hash=1

# @internal
# Compute the hash of a single file (or /dev/stdin) using the named algorithm.
# Tries native *sum tools first, then shasum, then openssl as a fallback.
_fs_hash_compute() {
  local _algo _file
  _algo="${1}"
  _file="${2:?_fs_hash_compute: no _file given}"

  if [[ "${_file}" != "/dev/stdin" ]] && [[ ! -r "${_file}" ]]; then
    printf -- 'fs_hash: not readable: %s\n' "${_file}" >&2
    return 1
  fi

  case "${_algo}" in
    (sha512)
      if command -v sha512sum >/dev/null 2>&1; then
        sha512sum -- "${_file}" | awk '{print $1}'
      elif command -v shasum >/dev/null 2>&1; then
        shasum -a 512 -- "${_file}" | awk '{print $1}'
      elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha512 -- "${_file}" | awk '{print $NF}'
      else
        printf -- 'fs_hash: no sha512 tool found\n' >&2; return 1
      fi ;;
    (sha256)
      if command -v sha256sum >/dev/null 2>&1; then
        sha256sum -- "${_file}" | awk '{print $1}'
      elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 -- "${_file}" | awk '{print $1}'
      elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 -- "${_file}" | awk '{print $NF}'
      else
        printf -- 'fs_hash: no sha256 tool found\n' >&2; return 1
      fi ;;
    (sha1)
      if command -v sha1sum >/dev/null 2>&1; then
        sha1sum -- "${_file}" | awk '{print $1}'
      elif command -v shasum >/dev/null 2>&1; then
        shasum -a 1 -- "${_file}" | awk '{print $1}'
      elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha1 -- "${_file}" | awk '{print $NF}'
      else
        printf -- 'fs_hash: no sha1 tool found\n' >&2; return 1
      fi ;;
    (md5)
      if command -v md5sum >/dev/null 2>&1; then
        md5sum -- "${_file}" | awk '{print $1}'
      elif command -v md5 >/dev/null 2>&1; then
        md5 -- "${_file}" | awk '{print $NF}'
      elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -md5 -- "${_file}" | awk '{print $NF}'
      else
        printf -- 'fs_hash: no md5 tool found\n' >&2; return 1
      fi ;;
    (*)
      printf -- 'fs_hash: unknown algorithm: %s\n' "${_algo}" >&2; return 1 ;;
  esac
}

# @description Hash a file or directory tree using a portable tool-agnostic approach.
#   Defaults to sha256. With --tree/-R, produces a stable hash of all files under
#   a directory by hashing sorted per-file hashes, then hashing the result.
#
# @arg $1 string Optional: '--algo <algo>' to select algorithm (sha256, sha512, sha1, md5)
# @arg $2 string Optional: '--tree' or '-R' to hash a directory tree recursively
# @arg $@ string Path to file or directory
#
# @example
#   fs_hash /etc/passwd
#   fs_hash --algo sha512 /etc/passwd
#   fs_hash --tree /etc/
#   fs_hash --algo md5 --tree /var/www/
#
# @stdout Hex digest
# @exitcode 0 Success
# @exitcode 1 Path not found, not readable, or no suitable tool available
fs_hash() {
  local _algo _tree _target
  _algo="sha256"
  _tree=0

  while (( $# > 0 )); do
    case "${1}" in
      (--algo|-a)  _algo="${2}"; shift 2 ;;
      (--tree|-R)  _tree=1; shift ;;
      (--)         shift; _target="${1}"; break ;;
      (-*)
        printf -- 'Usage: fs_hash [--algo <algo>] [--tree|-R] <path>\n' >&2
        return 1
      ;;
      (*)          _target="${1}"; shift ;;
    esac
  done

  _target="${_target:?No path given}"

  if (( _tree == 1 )); then
    [[ -d "${_target}" ]] || {
      printf -- 'fs_hash: not a directory: %s\n' "${_target}" >&2
      return 1
    }
    # Hash each file sorted by name for stability, then hash the concatenated result
    (
      cd -- "${_target}" || return 1
      find '.' -type f | sort | while IFS= read -r _file; do
        printf -- '%s  %s\n' "$(_fs_hash_compute "${_algo}" "${_file}")" "${_file}"
      done
    ) | _fs_hash_compute "${_algo}" /dev/stdin
  else
    _fs_hash_compute "${_algo}" "${_target}"
  fi
}
