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

[ -n "${_SHELLAC_LOADED_crypto_ssl_dgst+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_dgst=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_dgst: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Compute a cryptographic digest of a file.
#
# @arg $1 string File to hash
# @arg $2 string Digest algorithm (default: sha256)
#
# @example
#   ssl_dgst archive.tar.gz
#   ssl_dgst archive.tar.gz sha512
#
# @stdout Digest string in the form "algo(file)= hash"
# @exitcode 0 Success
ssl_dgst() {
    local _file _algo
    _file="${1:?ssl_dgst: No file provided}"
    _algo="${2:-sha256}"
    openssl dgst -"${_algo}" "${_file}"
}

# @description Sign a file's digest with a private key.
#   Produces a binary signature file.
#
# @arg $1 string Private key file
# @arg $2 string File to sign
# @arg $3 string Output signature file (default: input file with .sig suffix)
# @arg $4 string Digest algorithm (default: sha256)
#
# @example
#   ssl_dgst_sign server.key archive.tar.gz
#   ssl_dgst_sign server.key archive.tar.gz archive.tar.gz.sig sha512
#
# @exitcode 0 Success
# @exitcode 1 openssl error
ssl_dgst_sign() {
    local _key _file _out _algo
    _key="${1:?ssl_dgst_sign: No key file provided}"
    _file="${2:?ssl_dgst_sign: No file to sign provided}"
    _out="${3:-${_file}.sig}"
    _algo="${4:-sha256}"
    openssl dgst -"${_algo}" -sign "${_key}" -out "${_out}" "${_file}"
}

# @description Verify a signed digest against a public key.
#
# @arg $1 string Public key file (PEM, extracted via openssl rsa -pubout)
# @arg $2 string Signature file produced by ssl_dgst_sign
# @arg $3 string File to verify
# @arg $4 string Digest algorithm (default: sha256; must match what was used to sign)
#
# @example
#   ssl_dgst_verify pubkey.pem archive.tar.gz.sig archive.tar.gz
#
# @stdout "Verified OK" or "Verification Failure"
# @exitcode 0 Signature verified
# @exitcode 1 Verification failed
ssl_dgst_verify() {
    local _pubkey _sig _file _algo
    _pubkey="${1:?ssl_dgst_verify: No public key file provided}"
    _sig="${2:?ssl_dgst_verify: No signature file provided}"
    _file="${3:?ssl_dgst_verify: No file to verify provided}"
    _algo="${4:-sha256}"
    openssl dgst -"${_algo}" -verify "${_pubkey}" -signature "${_sig}" "${_file}"
}
