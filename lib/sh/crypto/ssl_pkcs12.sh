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

[ -n "${_SHELLAC_LOADED_crypto_ssl_pkcs12+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_pkcs12=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_pkcs12: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Convert a PKCS#12 (.p12 / .pfx) bundle to PEM.
#   Extracts private key, certificate, and any chain certificates unencrypted (-nodes).
#   openssl will prompt for the import password interactively.
#
# @arg $1 string Input .p12 / .pfx file
# @arg $2 string Output PEM file (default: input basename with .pem extension)
#
# @exitcode 0 Success
# @exitcode 1 No input, empty file, or openssl error
ssl_p12_to_pem() {
    local _in _out
    _in="${1:?ssl_p12_to_pem: No input file provided}"
    _out="${2:-${_in%.*}.pem}"

    if [[ ! -s "${_in}" ]]; then
        printf -- 'ssl_p12_to_pem: %s\n' "Input file appears to be empty: ${_in}" >&2
        return 1
    fi

    openssl pkcs12 -nodes -in "${_in}" -out "${_out}"
}

# @description Bundle a private key, certificate, and CA chain into a PKCS#12 (.p12) file.
#   openssl will prompt for an export password interactively.
#
# @arg $1 string Private key file
# @arg $2 string Certificate file
# @arg $3 string CA chain file
# @arg $4 string Output .p12 file
#
# @exitcode 0 Success
# @exitcode 1 Missing arguments, empty input files, or openssl error
ssl_pem_to_p12() {
    local _key _cert _ca _out
    _key="${1:?ssl_pem_to_p12: No key file provided}"
    _cert="${2:?ssl_pem_to_p12: No certificate file provided}"
    _ca="${3:?ssl_pem_to_p12: No CA chain file provided}"
    _out="${4:?ssl_pem_to_p12: No output file provided}"

    if [[ ! -s "${_key}" ]]; then
        printf -- 'ssl_pem_to_p12: %s\n' "Key file appears to be empty: ${_key}" >&2
        return 1
    fi
    if [[ ! -s "${_cert}" ]]; then
        printf -- 'ssl_pem_to_p12: %s\n' "Certificate file appears to be empty: ${_cert}" >&2
        return 1
    fi
    if [[ ! -s "${_ca}" ]]; then
        printf -- 'ssl_pem_to_p12: %s\n' "CA chain file appears to be empty: ${_ca}" >&2
        return 1
    fi

    openssl pkcs12 -export \
        -inkey "${_key}" \
        -in "${_cert}" \
        -certfile "${_ca}" \
        -out "${_out}"
}
