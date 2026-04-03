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

[ -n "${_SHELLAC_LOADED_crypto_ssl_encrypt+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_encrypt=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_encrypt: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Encrypt a file using AES-256-CBC with base64 encoding and PBKDF2 key derivation.
#   openssl will prompt for a passphrase interactively.  Decrypt with ssl_decrypt.
#
# @arg $1 string Input file to encrypt
# @arg $2 string Output encrypted file (default: input path with .crypted suffix)
#
# @exitcode 0 Success
# @exitcode 1 No input file provided
ssl_encrypt() {
    local _ssl_encrypt_in _ssl_encrypt_out
    _ssl_encrypt_in="${1}"
    _ssl_encrypt_out="${2}"

    if (( "${#_ssl_encrypt_in}" == 0 )); then
        printf -- 'ssl_encrypt: %s\n' "No input file provided" >&2
        return 1
    fi

    if (( "${#_ssl_encrypt_out}" == 0 )); then
        _ssl_encrypt_out="${_ssl_encrypt_in}.crypted"
    fi

    openssl aes-256-cbc -a -salt -pbkdf2 -iter 600000 -in "${_ssl_encrypt_in}" -out "${_ssl_encrypt_out}"
}

# Generate keypair
# Must be pem mode, not openssh format
# ssh-keygen -t rsa -b 4096 -m pem -f "${HOME}/.ssh/ssl_encrypt" -N ''
# Convert public key to pkcs8
# ssh-keygen -f ~/.ssh/ssl_encrypt.pub -e -m pkcs8 > ~/.ssh/ssl_encrypt/radium.pkcs8
# Rename private key
# mv "${HOME}/.ssh/ssl_encrypt" "${HOME}/.ssh/ssl_encrypt.key"
# openssl pkeyutl -encrypt -pubin -inkey radium.pkcs8 -in testfile -out testhashed
