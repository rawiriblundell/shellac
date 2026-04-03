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

[ -n "${_SHELLAC_LOADED_crypto_ssl_validate_cert+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_validate_cert=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_validate_cert: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Validate that a certificate, private key, and CSR all share the same modulus.
#   If key and/or CSR paths are omitted, they are inferred from the certificate basename.
#   e.g. for 'example.com.crt', 'example.com.key' and 'example.com.csr' are assumed.
#
# @arg $1 string Certificate file (.crt or .pem)
# @arg $2 string Private key file (optional; default: cert basename + .key)
# @arg $3 string CSR file (optional; default: cert basename + .csr)
#
# @exitcode 0 Certificate, key, and CSR moduli all match
# @exitcode 1 No certificate provided, missing/unreadable files, or modulus mismatch
ssl_validate_cert() {
    local _ssl_validate_cert _validate_key _validate_csr _cert_hash _key_hash _csr_hash
    _ssl_validate_cert="${1}"
    _validate_key="${2}"
    _validate_csr="${3}"

    if (( "${#_ssl_validate_cert}" == 0 )); then
        printf -- 'ssl_validate_cert: %s\n' "No input file provided" >&2
        return 1
    fi

    if (( "${#_validate_key}" == 0 )); then
        # We assume either a .pem or .crt extension and remove it
        _validate_key="${_ssl_validate_cert%.*}"
        # We assume a .key file with the same name exists
        _validate_key="${_validate_key}.key"
    fi

    if (( "${#_validate_csr}" == 0 )); then
        _validate_key="${_ssl_validate_cert%.*}"
        _validate_key="${_validate_key}.csr"
    fi

    if [ ! -r "${_validate_key}" ]; then
        printf -- 'ssl_validate_cert: %s\n' "key file not found, specified, or readable" >&2
        return 1
    fi

    if [ ! -r "${_validate_csr}" ]; then
        printf -- 'ssl_validate_cert: %s\n' "csr file not found, specified, or readable" >&2
        return 1
    fi

    _cert_hash="$(openssl x509 -noout -modulus -in "${_ssl_validate_cert}" | openssl md5)"
    _key_hash="$(openssl rsa -noout -modulus -in "${_validate_key}" | openssl md5)"
    _csr_hash="$(openssl req -noout -modulus -in "${_validate_csr}" | openssl md5)"

    if [ "${_cert_hash}" = "${_key_hash}" ] && [ "${_cert_hash}" = "${_csr_hash}" ]; then
        return 0
    fi

    return 1
}
