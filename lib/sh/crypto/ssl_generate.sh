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

[ -n "${_SHELLAC_LOADED_crypto_ssl_generate+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_generate=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_generate: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Generate an RSA private key.
#   Key is written unencrypted. For a passphrase-protected key, use openssl genrsa directly.
#
# @arg $1 string Output file path (default: key.pem)
# @arg $2 int    Key size in bits (default: 4096)
#
# @example
#   ssl_genkey_rsa server.key 2048
#
# @exitcode 0 Success
# @exitcode 1 openssl error
ssl_genkey_rsa() {
    local _out _bits
    _out="${1:-key.pem}"
    _bits="${2:-4096}"
    openssl genrsa -out "${_out}" "${_bits}"
}

# @description List available elliptic curves.
#
# @stdout One curve name per line
# @exitcode 0 Always
ssl_ec_curves() {
    openssl ecparam -list_curves
}

# @description Generate an elliptic-curve private key.
#
# @arg $1 string Named curve (default: prime256v1). Use ssl_ec_curves to list options.
# @arg $2 string Output file path (default: ec_key.pem)
#
# @example
#   ssl_genkey_ec prime256v1 server.key
#   ssl_genkey_ec secp384r1 server.key
#
# @exitcode 0 Success
# @exitcode 1 openssl error or unknown curve
ssl_genkey_ec() {
    local _curve _out
    _curve="${1:-prime256v1}"
    _out="${2:-ec_key.pem}"
    openssl ecparam -name "${_curve}" -genkey -noout -out "${_out}"
}

# @description Generate a Certificate Signing Request from an existing private key.
#   If no subject string is provided, openssl will prompt interactively for DN fields.
#
# @arg $1 string Private key file (required)
# @arg $2 string Output CSR file (default: derives from key filename)
# @arg $3 string Subject DN string, e.g. /CN=example.com/O=Acme (optional)
#
# @example
#   ssl_gencsr server.key server.csr "/CN=example.com/O=Acme Ltd"
#   ssl_gencsr server.key   # prompts interactively for subject
#
# @exitcode 0 Success
# @exitcode 1 openssl error
ssl_gencsr() {
    local _key _out _subj
    _key="${1:?ssl_gencsr: No key file provided}"
    _out="${2:-${_key%.pem}.csr}"
    _subj="${3:-}"
    if [[ -n "${_subj}" ]]; then
        openssl req -new -key "${_key}" -out "${_out}" -subj "${_subj}"
    else
        openssl req -new -key "${_key}" -out "${_out}"
    fi
}

# @description Generate a self-signed certificate and private key in one step.
#   Private key is written unencrypted (-nodes).
#   If no subject string is provided, openssl will prompt interactively.
#
# @arg $1 string Output certificate file (default: cert.pem)
# @arg $2 string Output key file (default: key.pem)
# @arg $3 int    Validity in days (default: 365)
# @arg $4 string Subject DN string, e.g. /CN=example.com (optional)
#
# @example
#   ssl_selfsigned cert.pem key.pem 365 "/CN=localhost"
#   ssl_selfsigned   # prompts interactively, writes cert.pem and key.pem
#
# @exitcode 0 Success
# @exitcode 1 openssl error
ssl_selfsigned() {
    local _cert _key _days _subj
    _cert="${1:-cert.pem}"
    _key="${2:-key.pem}"
    _days="${3:-365}"
    _subj="${4:-}"
    if [[ -n "${_subj}" ]]; then
        openssl req -x509 -nodes -days "${_days}" -sha256 \
            -newkey rsa:4096 -keyout "${_key}" -out "${_cert}" \
            -subj "${_subj}"
    else
        openssl req -x509 -nodes -days "${_days}" -sha256 \
            -newkey rsa:4096 -keyout "${_key}" -out "${_cert}"
    fi
}
