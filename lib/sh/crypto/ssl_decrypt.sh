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

[ -n "${_SHELLAC_LOADED_crypto_ssl_decrypt+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_decrypt=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_decrypt: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Decrypt a file encrypted with ssl_encrypt (AES-256-CBC, base64, PBKDF2).
#   openssl will prompt for the passphrase interactively.
#
# @arg $1 string Input encrypted file
# @arg $2 string Output decrypted file (default: input path with .decrypted suffix)
#
# @exitcode 0 Success
# @exitcode 1 No input file provided
ssl_decrypt() {
    local _ssl_decrypt_in _ssl_decrypt_out
    _ssl_decrypt_in="${1}"
    _ssl_decrypt_out="${2}"

    if (( "${#_ssl_decrypt_in}" == 0 )); then
        printf -- 'ssl_decrypt: %s\n' "No input file provided" >&2
        return 1
    fi

    if (( "${#_ssl_decrypt_out}" == 0 )); then
        _ssl_decrypt_out="${_ssl_decrypt_in}.decrypted"
    fi

    openssl aes-256-cbc -d -a -pbkdf2 -iter 600000 -in "${_ssl_decrypt_in}" -out "${_ssl_decrypt_out}"
}

# Decrypt using private key
# If key is not supplied, try "${HOME}/.ssh/ssl_encrypt.key"
# openssl pkeyutl -decrypt -inkey radium -in testhashed -out testunhashed
