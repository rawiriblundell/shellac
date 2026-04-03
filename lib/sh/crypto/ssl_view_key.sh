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

[ -n "${_SHELLAC_LOADED_crypto_ssl_view_key+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_view_key=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_view_key: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Display the decoded components of an RSA private key and verify its consistency.
#
# @arg $1 string PEM private key file
#
# @stdout Decoded key components (modulus, public exponent, etc.)
# @exitcode 0 Key is consistent
# @exitcode 1 No input provided or key check failed
ssl_view_key () {
    local _ssl_view_key_in
    _ssl_view_key_in="${1}"

    if (( "${#_ssl_view_key_in}" == 0 )); then
        printf -- 'ssl_view_key: %s\n' "No input file provided" >&2
        return 1
    fi

    openssl rsa -check -in "${_ssl_view_key_in}"
}

# @description Print the SHA-256 hash of the public key modulus from a private key.
#   Used to verify that a key and its corresponding certificate share the same modulus.
#
# @arg $1 string PEM private key file
#
# @stdout SHA-256 hash of the modulus
# @exitcode 0 Success
# @exitcode 1 No input provided
ssl_view_key_modulus() {
    local _ssl_view_key_modulus_in
    _ssl_view_key_modulus_in="${1}"

    if (( "${#_ssl_view_key_modulus_in}" == 0 )); then
        printf -- 'ssl_view_key_modulus: %s\n' "No input file provided" >&2
        return 1
    fi

    openssl rsa -noout -modulus -in "${_ssl_view_key_modulus_in}" | shasum -a 256
}
