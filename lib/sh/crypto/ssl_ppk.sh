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

[ -n "${_SHELLAC_LOADED_crypto_ssl_ppk+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_ppk=1

if ! command -v puttygen >/dev/null 2>&1; then
    printf -- 'ssl_ppk: %s\n' "This library requires 'puttygen', which was not found in PATH" >&2
    exit 1
fi

# @description Convert a PuTTY .ppk private key to OpenSSH PEM format.
#
# @arg $1 string Input .ppk file
# @arg $2 string Output PEM file (default: input basename with .pem extension)
#
# @exitcode 0 Success
# @exitcode 1 No input or puttygen error
ssl_ppk_to_pem() {
    local _in _out
    _in="${1:?ssl_ppk_to_pem: No input file provided}"
    _out="${2:-${_in%.*}.pem}"
    puttygen "${_in}" -O private-openssh -o "${_out}"
}

# @description Convert an OpenSSH PEM private key to PuTTY .ppk format.
#
# @arg $1 string Input PEM key file
# @arg $2 string Output .ppk file (default: input basename with .ppk extension)
#
# @exitcode 0 Success
# @exitcode 1 No input or puttygen error
ssl_pem_to_ppk() {
    local _in _out
    _in="${1:?ssl_pem_to_ppk: No input file provided}"
    _out="${2:-${_in%.*}.ppk}"
    puttygen "${_in}" -O private -o "${_out}"
}
