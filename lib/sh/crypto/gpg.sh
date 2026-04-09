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

[ -n "${_SHELLAC_LOADED_crypto_gpg+x}" ] && return 0
_SHELLAC_LOADED_crypto_gpg=1
requires gpg

# @description List GPG public key IDs, optionally filtered by query.
#
# @arg $@ string Optional key ID, name, or email to filter by
#
# @stdout One key ID per line
# @exitcode 0 Always
gpg_list_keys_public() {
  gpg --batch --no-tty --with-colons --list-public-keys -- "$@" 2>/dev/null |
    grep "^pub:" |
    cut -d ":" -f 5
}

# @description List GPG secret key IDs, optionally filtered by query.
#
# @arg $@ string Optional key ID, name, or email to filter by
#
# @stdout One key ID per line
# @exitcode 0 Always
gpg_list_keys_secret() {
  gpg --batch --no-tty --with-colons --list-secret-keys -- "$@" 2>/dev/null |
    grep "^sec:" |
    cut -d ":" -f 5
}

# @description Generate a new 2048-bit RSA GPG key that does not expire.
#
# @arg $1 string  Name for the key
# @arg $2 string  Email for the key
# @arg $3 string  Optional comment for the key
# @arg $4 string  Optional passphrase; if omitted the key has no passphrase
#
# @stdout The new key ID on success
# @exitcode 0 Success
# @exitcode 1 gpg key generation failed
gpg_create() {
  local _name _email _comment _passphrase _comment_line _passphrase_line _gpg_out
  _name="${1:?gpg_create: name required}"
  _email="${2:?gpg_create: email required}"
  _comment="${3:-}"
  _passphrase="${4:-}"
  _comment_line=""
  _passphrase_line=""

  if [[ -n "${_comment}" ]]; then
    _comment_line="Name-Comment: ${_comment}"
  fi

  if [[ -n "${_passphrase}" ]]; then
    _passphrase_line="Passphrase: ${_passphrase}"
  else
    _passphrase_line="%no-protection"
  fi

  if _gpg_out="$(gpg --no-tty --batch --generate-key 2>&1 <<-EOT
	Key-Type: RSA
	Key-Length: 2048
	Name-Real: ${_name}
	${_comment_line}
	Name-Email: ${_email}
	${_passphrase_line}
	Expire-Date: 0
	%commit
	EOT
  )"; then
    printf -- '%s\n' "${_gpg_out}" | sed -n '/^gpg: key /p' | cut -d " " -f 3
  fi
}

# @description Interactively prompt to change the passphrase on a GPG key.
#
# @arg $1 string  Key ID
#
# @exitcode 0 Success
# @exitcode 1 gpg error
gpg_password_prompt() {
  local _key_id
  _key_id="${1:?gpg_password_prompt: key_id required}"
  gpg --no-tty --batch --edit-key -- "${_key_id}" passwd save 2>/dev/null
}

# @description Export a GPG key as an ASCII-armored .asc file.
#   If destination is a directory, the file is named <key_id>.asc within it.
#
# @arg $1 string  Key ID to export
# @arg $2 string  Destination file or directory
#
# @exitcode 0 Success
# @exitcode 1 gpg error
gpg_export_armored() {
  local _key_id _dest
  _key_id="${1:?gpg_export_armored: key_id required}"
  _dest="${2:?gpg_export_armored: destination required}"
  if [[ -d "${_dest}" ]]; then
    _dest="${_dest}/${_key_id}.asc"
  fi
  gpg --no-tty --armor --export -- "${_key_id}" > "${_dest}"
}

# @description Export a GPG key as a binary .gpg file.
#   If destination is a directory, the file is named <key_id>.gpg within it.
#
# @arg $1 string  Key ID to export
# @arg $2 string  Destination file or directory
#
# @exitcode 0 Success
# @exitcode 1 gpg error
gpg_export() {
  local _key_id _dest
  _key_id="${1:?gpg_export: key_id required}"
  _dest="${2:?gpg_export: destination required}"
  if [[ -d "${_dest}" ]]; then
    _dest="${_dest}/${_key_id}.gpg"
  fi
  gpg --batch --no-tty --export -- "${_key_id}" > "${_dest}"
}

# @description Search for public keys on configured keyservers.
#
# @arg $1 string  Query term (key ID, email, or name)
#
# @stdout Raw colon-delimited gpg search output
# @exitcode 0 Always
gpg_search_keys() {
  local _query
  _query="${1:?gpg_search_keys: query required}"
  gpg --no-tty --with-colons --batch --search-keys -- "${_query}" 2>/dev/null
}

# @description Fetch one or more public keys from configured keyservers.
#
# @arg $@ string  One or more key IDs to receive
#
# @stdout gpg key receipt messages
# @exitcode 0 Success
# @exitcode 1 No key IDs provided
gpg_receive_keys() {
  if (( ${#} == 0 )); then
    printf -- '%s\n' "gpg_receive_keys: at least one key ID required" >&2
    return 1
  fi
  gpg --no-tty --batch --receive-keys -- "$@" 2>&1 |
    sed -n '/^gpg: key /p' |
    cut -c 6-
}

# @description Test whether a value is a valid GPG key ID.
#   Accepts short (8 hex chars) or long (16 hex chars) IDs, with or without a 0x prefix.
#
# @arg $1 string  Value to test
#
# @exitcode 0 Valid key ID
# @exitcode 1 Not a valid key ID
gpg_keyid_valid() {
  local _key_id
  _key_id="${1:?gpg_keyid_valid: key_id required}"
  # Strip 0x prefix for 10-char (0x + 8) and 18-char (0x + 16) forms
  case "${_key_id}" in
    (0x????????|0x????????????????)
      _key_id="${_key_id#0x}"
    ;;
  esac
  # Must be exactly 8 or 16 characters
  case "${#_key_id}" in
    (8|16) ;;
    (*) return 1 ;;
  esac
  # Must consist entirely of hex characters
  [[ "${_key_id}" =~ ^[0-9A-Fa-f]+$ ]]
}
