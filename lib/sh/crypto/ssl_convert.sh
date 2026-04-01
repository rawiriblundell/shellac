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
# Provenance: https://github.com/rawiriblundell/sh_libpath
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_crypto_ssl_convert+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_convert=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_convert: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Convert a .cer file (DER or PEM) to a .crt file.
#   Auto-detects encoding: if the file contains "TRUSTED" it is treated as PEM,
#   otherwise as DER binary.
#
# @arg $1 string Input .cer file
# @arg $2 string Output .crt file (default: input basename with .crt extension)
#
# @exitcode 0 Success
# @exitcode 1 No input, empty file, or openssl error
ssl_cer_to_crt() {
    local _in _out _enctype
    _in="${1:?ssl_cer_to_crt: No input file provided}"
    _out="${2:-${_in%.*}.crt}"

    if [[ ! -s "${_in}" ]]; then
        printf -- 'ssl_cer_to_crt: %s\n' "Input file appears to be empty: ${_in}" >&2
        return 1
    fi

    grep -q "^-----BEGIN" "${_in}" || _enctype="DER"
    openssl x509 -inform "${_enctype:-PEM}" -in "${_in}" -out "${_out}"
}

# @description Convert a .crt certificate to PEM format.
#   Output is written to a .pem file.
#
# @arg $1 string Input .crt file
# @arg $2 string Output .pem file (default: input basename with .pem extension)
#
# @exitcode 0 Success
# @exitcode 1 No input, empty file, or openssl error
ssl_crt_to_pem() {
    local _in _out
    _in="${1:?ssl_crt_to_pem: No input file provided}"
    _out="${2:-${_in%.*}.pem}"

    if [[ ! -s "${_in}" ]]; then
        printf -- 'ssl_crt_to_pem: %s\n' "Input file appears to be empty: ${_in}" >&2
        return 1
    fi

    openssl x509 -in "${_in}" -out "${_out}" -outform PEM
}

# @description Convert a PEM certificate to a .crt file.
#
# @arg $1 string Input .pem file
# @arg $2 string Output .crt file (default: input basename with .crt extension)
#
# @exitcode 0 Success
# @exitcode 1 No input, empty file, or openssl error
ssl_pem_to_crt() {
    local _in _out
    _in="${1:?ssl_pem_to_crt: No input file provided}"
    _out="${2:-${_in%.*}.crt}"

    if [[ ! -s "${_in}" ]]; then
        printf -- 'ssl_pem_to_crt: %s\n' "Input file appears to be empty: ${_in}" >&2
        return 1
    fi

    openssl x509 -outform PEM -in "${_in}" -out "${_out}"
}

# @description Convert a PEM certificate to binary DER format.
#
# @arg $1 string Input PEM file
# @arg $2 string Output DER file (default: input basename with .der extension)
#
# @exitcode 0 Success
# @exitcode 1 openssl error
ssl_pem_to_der() {
    local _in _out
    _in="${1:?ssl_pem_to_der: No input PEM file provided}"
    _out="${2:-${_in%.pem}.der}"
    openssl x509 -outform der -in "${_in}" -out "${_out}"
}

# @description Convert a binary DER certificate to PEM format.
#
# @arg $1 string Input DER file
# @arg $2 string Output PEM file (default: input basename with .pem extension)
#
# @exitcode 0 Success
# @exitcode 1 openssl error
ssl_der_to_pem() {
    local _in _out
    _in="${1:?ssl_der_to_pem: No input DER file provided}"
    _out="${2:-${_in%.der}.pem}"
    openssl x509 -inform der -in "${_in}" -out "${_out}"
}
