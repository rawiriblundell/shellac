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

[ -n "${_SHELLAC_LOADED_crypto_ssl_view_csr+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_view_csr=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_view_csr: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Display the decoded text of a certificate signing request (CSR).
#   Verifies the CSR signature as part of the output.
#
# @arg $1 string CSR file
#
# @stdout Decoded CSR text including subject, public key, and extensions
# @exitcode 0 Success
# @exitcode 1 No input provided
ssl_view_csr () {
    local _ssl_view_csr_in
    _ssl_view_csr_in="${1}"

    if (( "${#_ssl_view_csr_in}" == 0 )); then
        printf -- 'ssl_view_csr: %s\n' "No input file provided" >&2
        return 1
    fi

    openssl req -text -noout -verify -in "${_ssl_view_csr_in}"
}

# @description Print the SHA-256 hash of the public key modulus from a CSR.
#   Used to verify that a CSR and its corresponding key share the same modulus.
#
# @arg $1 string CSR file
#
# @stdout SHA-256 hash of the modulus
# @exitcode 0 Success
# @exitcode 1 No input provided
ssl_view_csr_modulus() {
    local _ssl_view_csr_modulus_in
    _ssl_view_csr_modulus_in="${1}"

    if (( "${#_ssl_view_csr_modulus_in}" == 0 )); then
        printf -- 'ssl_view_csr_modulus: %s\n' "No input file provided" >&2
        return 1
    fi

    openssl req -noout -modulus -in "${_ssl_view_csr_modulus_in}" | shasum -a 256
}
