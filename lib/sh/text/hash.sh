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
# Provenance: https://github.com/rawiriblundell/shellac
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_text_hash+x}" ] && return 0
_SHELLAC_LOADED_text_hash=1

# @internal
_str_hash_not_found() {
  printf -- 'str_hash: %s\n' "${1:-Hashing} method not found" >&2
  return 1
}

# @internal
_str_hash_failed() {
  printf -- 'str_hash: %s\n' "${1:-Hashing} method failed" >&2
  return 1
}

# @internal
# Each _str_hash_* function reads from stdin and writes to stdout.
_str_hash_sha512() {
  if command -v sha512sum >/dev/null 2>&1; then
    sha512sum || _str_hash_failed "sha512sum"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 512 || _str_hash_failed "shasum(sha512)"
  elif command -v digest >/dev/null 2>&1; then
    digest -v -a sha512 || _str_hash_failed "digest(sha512)"
  else
    _str_hash_not_found sha512
  fi
}

# @internal
_str_hash_sha384() {
  if command -v sha384sum >/dev/null 2>&1; then
    sha384sum || _str_hash_failed "sha384sum"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 384 || _str_hash_failed "shasum(sha384)"
  elif command -v digest >/dev/null 2>&1; then
    digest -v -a sha384 || _str_hash_failed "digest(sha384)"
  else
    _str_hash_not_found sha384
  fi
}

# @internal
_str_hash_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum || _str_hash_failed "sha256sum"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 || _str_hash_failed "shasum(sha256)"
  elif command -v digest >/dev/null 2>&1; then
    digest -v -a sha256 || _str_hash_failed "digest(sha256)"
  else
    _str_hash_not_found sha256
  fi
}

# @internal
_str_hash_sha224() {
  if command -v sha224sum >/dev/null 2>&1; then
    sha224sum || _str_hash_failed "sha224sum"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 224 || _str_hash_failed "shasum(sha224)"
  elif command -v digest >/dev/null 2>&1; then
    digest -v -a sha224 || _str_hash_failed "digest(sha224)"
  else
    _str_hash_not_found sha224
  fi
}

# @internal
_str_hash_sha1() {
  if command -v sha1sum >/dev/null 2>&1; then
    sha1sum || _str_hash_failed "sha1sum"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 1 || _str_hash_failed "shasum(sha1)"
  elif command -v digest >/dev/null 2>&1; then
    digest -v -a sha1 || _str_hash_failed "digest(sha1)"
  else
    _str_hash_not_found sha1
  fi
}

# @internal
_str_hash_md5() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum || _str_hash_failed "md5sum"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 1 || _str_hash_failed "shasum(md5)"
  elif command -v digest >/dev/null 2>&1; then
    digest -v -a md5 || _str_hash_failed "digest(md5)"
  else
    _str_hash_not_found md5
  fi
}

# @internal
_str_hash_ck() {
  if command -v cksum >/dev/null 2>&1; then
    cksum || _str_hash_failed "cksum"
  else
    _str_hash_not_found cksum
  fi
}

# @internal
# Dispatch stdin to the selected hash tool, printing only the digest field.
_str_hash_dispatch() {
  case "${1}" in
    (sha512) _str_hash_sha512 | awk '{print $1}' ;;
    (sha384) _str_hash_sha384 | awk '{print $1}' ;;
    (sha256) _str_hash_sha256 | awk '{print $1}' ;;
    (sha224) _str_hash_sha224 | awk '{print $1}' ;;
    (sha1)   _str_hash_sha1   | awk '{print $1}' ;;
    (md5)    _str_hash_md5    | awk '{print $1}' ;;
    (ck)     _str_hash_ck     | awk '{print $1}' ;;
    (*)      _str_hash_md5    | awk '{print $1}' ;;
  esac
}

# @description Hash a string using the specified algorithm.
#   Defaults to md5 if no algorithm is specified.
#   Accepts input as arguments or from stdin when no content argument is given.
#   Tries multiple available system tools (sha*sum, shasum, digest) for each algorithm.
#
# @arg $1 string Hash algorithm: sha512, sha384, sha256, sha224, sha1, md5, ck
# @arg $@ string The string to hash (optional; reads from stdin when absent)
#
# @stdout Hex digest of the hashed input
# @exitcode 0 Success
# @exitcode 1 Required hash tool not found
str_hash() {
  local _algo
  case "${1:-}" in
    (sha512|sha384|sha256|sha224|sha1|md5|ck) _algo="${1}"; shift ;;
    (*) _algo="md5" ;;
  esac
  if (( ${#} > 0 )); then
    printf -- '%s\n' "${*}" | _str_hash_dispatch "${_algo}"
  elif [[ ! -t 0 ]]; then
    _str_hash_dispatch "${_algo}"
  fi
}
