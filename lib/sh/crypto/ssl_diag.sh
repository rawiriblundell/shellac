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

[ -n "${_SHELLAC_LOADED_crypto_ssl_diag+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_diag=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_diag: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description List available TLS ciphers, optionally filtered by a cipher string.
#   See openssl-ciphers(1) for filter syntax (e.g. HIGH, !aNULL, TLSv1.2).
#
# @arg $1 string Cipher filter string (optional; default: all ciphers)
#
# @example
#   ssl_ciphers_list
#   ssl_ciphers_list HIGH:!aNULL:!MD5
#
# @stdout One cipher per line with protocol, key exchange, auth, enc, and MAC columns
# @exitcode 0 Always
ssl_ciphers_list() {
    local _filter
    _filter="${1:-}"
    if [[ -n "${_filter}" ]]; then
        openssl ciphers -v "${_filter}"
    else
        openssl ciphers -v
    fi
}

# @description Decode a hex OpenSSL error code to a human-readable description.
#   Error codes are printed by openssl commands in the form "error:XXXXXXXX:...".
#
# @arg $1 string Hex error code (e.g. 0200100D)
#
# @example
#   ssl_errstr 0200100D
#
# @stdout Human-readable error string
# @exitcode 0 Always
ssl_errstr() {
    local _code
    _code="${1:?ssl_errstr: No error code provided}"
    openssl errstr "${_code}"
}
