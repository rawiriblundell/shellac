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

[ -n "${_SHELLAC_LOADED_crypto_ssl_inspect+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_inspect=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_inspect: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Print the validity dates (notBefore and notAfter) of a certificate.
#   More concise than ssl_view_cert for scripting expiry checks.
#
# @arg $1 string Certificate file
#
# @example
#   ssl_cert_dates server.pem
#   # notBefore=Jan  1 00:00:00 2024 GMT
#   # notAfter=Jan   1 00:00:00 2025 GMT
#
# @stdout notBefore and notAfter lines
# @exitcode 0 Success
# @exitcode 1 openssl error
ssl_cert_dates() {
    local _in
    _in="${1:?ssl_cert_dates: No certificate file provided}"
    openssl x509 -noout -dates -in "${_in}"
}

# @description Print the subject DN of a certificate.
#
# @arg $1 string Certificate file
#
# @stdout Subject DN line
# @exitcode 0 Success
ssl_cert_subject() {
    local _in
    _in="${1:?ssl_cert_subject: No certificate file provided}"
    openssl x509 -noout -subject -in "${_in}"
}

# @description Print the fingerprint of a certificate.
#   Defaults to SHA-256; pass a second argument to use another digest (e.g. sha1, md5).
#
# @arg $1 string Certificate file
# @arg $2 string Digest algorithm (default: sha256)
#
# @example
#   ssl_cert_fingerprint server.pem
#   ssl_cert_fingerprint server.pem sha1
#
# @stdout Fingerprint line
# @exitcode 0 Success
ssl_cert_fingerprint() {
    local _in _algo
    _in="${1:?ssl_cert_fingerprint: No certificate file provided}"
    _algo="${2:-sha256}"
    openssl x509 -noout -fingerprint -"${_algo}" -in "${_in}"
}

# @description Verify that a certificate and key (and optionally a CSR) belong together
#   by comparing the MD5 hash of each object's modulus.
#   Prints OK to stdout on match; prints the divergent hashes to stderr and returns 1 on mismatch.
#
# @arg $1 string Certificate file
# @arg $2 string Private key file
# @arg $3 string CSR file (optional)
#
# @example
#   ssl_modulus_match server.pem server.key
#   ssl_modulus_match server.pem server.key server.csr
#
# @exitcode 0 All supplied objects share the same modulus
# @exitcode 1 Mismatch detected
ssl_modulus_match() {
    local _cert _key _csr _cert_md5 _key_md5 _csr_md5
    _cert="${1:?ssl_modulus_match: No certificate file provided}"
    _key="${2:?ssl_modulus_match: No key file provided}"
    _csr="${3:-}"

    _cert_md5=$(openssl x509 -noout -modulus -in "${_cert}" | openssl md5)
    _key_md5=$(openssl rsa -noout -modulus -in "${_key}" | openssl md5)

    if [[ -n "${_csr}" ]]; then
        _csr_md5=$(openssl req -noout -modulus -in "${_csr}" | openssl md5)
        if [[ "${_cert_md5}" = "${_key_md5}" ]] && [[ "${_cert_md5}" = "${_csr_md5}" ]]; then
            printf -- '%s\n' "OK: cert, key, and CSR moduli match"
            return 0
        fi
        printf -- 'ssl_modulus_match: MISMATCH: cert=%s key=%s csr=%s\n' \
            "${_cert_md5}" "${_key_md5}" "${_csr_md5}" >&2
        return 1
    fi

    if [[ "${_cert_md5}" = "${_key_md5}" ]]; then
        printf -- '%s\n' "OK: cert and key moduli match"
        return 0
    fi
    printf -- 'ssl_modulus_match: MISMATCH: cert=%s key=%s\n' \
        "${_cert_md5}" "${_key_md5}" >&2
    return 1
}

# @description Verify a certificate against a CA bundle or the system default trust store.
#
# @arg $1 string Certificate file
# @arg $2 string CA bundle file (optional; omit to use system trust store)
#
# @example
#   ssl_verify_chain server.pem
#   ssl_verify_chain server.pem /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
#
# @exitcode 0 Certificate verifies OK
# @exitcode 1 Verification failed
ssl_verify_chain() {
    local _cert _ca
    _cert="${1:?ssl_verify_chain: No certificate file provided}"
    _ca="${2:-}"
    if [[ -n "${_ca}" ]]; then
        openssl verify -CAfile "${_ca}" "${_cert}"
    else
        openssl verify "${_cert}"
    fi
}

# @description Verify the signature of a CSR and display its contents.
#
# @arg $1 string CSR file
#
# @stdout CSR text dump
# @exitcode 0 Signature OK
# @exitcode 1 Verification failed
ssl_verify_csr() {
    local _csr
    _csr="${1:?ssl_verify_csr: No CSR file provided}"
    openssl req -verify -text -noout -in "${_csr}"
}

# @description Remove the passphrase from an encrypted private key.
#   Writes the decrypted key to a new file; does not overwrite the input.
#   openssl will prompt for the passphrase interactively.
#
# @arg $1 string Encrypted key file
# @arg $2 string Output file (default: input basename with .nopass.pem suffix)
#
# @example
#   ssl_key_strip_passphrase encrypted.key
#   ssl_key_strip_passphrase encrypted.key plain.key
#
# @exitcode 0 Success
# @exitcode 1 Wrong passphrase or openssl error
ssl_key_strip_passphrase() {
    local _in _out
    _in="${1:?ssl_key_strip_passphrase: No input key file provided}"
    _out="${2:-${_in%.pem}.nopass.pem}"
    openssl rsa -in "${_in}" -out "${_out}"
}
