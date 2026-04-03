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

[ -n "${_SHELLAC_LOADED_crypto_ssl_hpkp+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_hpkp=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_hpkp: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Generate an HPKP pin (base64-encoded SHA-256 of the public key's DER)
#   from a local private key file.
#
# @arg $1 string Private key file (PEM)
#
# @stdout Base64-encoded HPKP pin string
# @exitcode 0 Success
# @exitcode 1 No input or openssl error
ssl_key_to_hpkp_pin() {
    local _in
    _in="${1:?ssl_key_to_hpkp_pin: No key file provided}"
    openssl rsa -in "${_in}" -outform der -pubout |
        openssl dgst -sha256 -binary |
        openssl enc -base64
}

# @description Generate an HPKP pin by fetching the public key from a live TLS endpoint.
#
# @arg $1 string Hostname (and optional :port, default 443)
#
# @example
#   ssl_website_to_hpkp_pin example.com
#   ssl_website_to_hpkp_pin example.com:8443
#
# @stdout Base64-encoded HPKP pin string
# @exitcode 0 Success
# @exitcode 1 No input or openssl error
ssl_website_to_hpkp_pin() {
    local _host _port _target
    _target="${1:?ssl_website_to_hpkp_pin: No host provided}"
    # Accept host or host:port
    case "${_target}" in
        (*:*) _host="${_target%%:*}"; _port="${_target##*:}" ;;
        (*)   _host="${_target}";     _port="443" ;;
    esac
    openssl s_client -connect "${_host}:${_port}" |
        openssl x509 -pubkey -noout |
        openssl rsa -pubin -outform der |
        openssl dgst -sha256 -binary |
        openssl enc -base64
}
