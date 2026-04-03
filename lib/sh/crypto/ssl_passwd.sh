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

[ -n "${_SHELLAC_LOADED_crypto_ssl_passwd+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_passwd=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_passwd: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Generate a hashed password string suitable for /etc/shadow or htpasswd.
#   This is distinct from secrets_genpasswd, which generates random plaintext passwords.
#   Here the input is a known password; the output is the shadow-compatible hash.
#
#   Supported algorithms (passed as $1):
#     -1      MD5-crypt (legacy, avoid where possible)
#     -apr1   Apache MD5-crypt (htpasswd compatible)
#     -5      SHA-256-crypt
#     -6      SHA-512-crypt (default; preferred for /etc/shadow on modern Linux)
#
#   If no password is given, openssl prompts interactively (input is not echoed).
#
# @arg $1 string Algorithm flag (default: -6)
# @arg $2 string Password to hash (optional; prompts if omitted)
# @arg $3 string Salt string (optional; openssl generates a random salt if omitted)
#
# @example
#   ssl_passwd_hash                          # prompts, SHA-512-crypt
#   ssl_passwd_hash -6 "mysecret"
#   ssl_passwd_hash -apr1 "htpassword" abc123
#
# @stdout Hash string in crypt(3) format
# @exitcode 0 Success
# @exitcode 1 openssl error
ssl_passwd_hash() {
    local _algo _password _salt
    _algo="${1:--6}"
    _password="${2:-}"
    _salt="${3:-}"

    local -a _args
    _args=( "${_algo}" )
    [[ -n "${_salt}" ]]     && _args+=( -salt "${_salt}" )
    [[ -n "${_password}" ]] && _args+=( "${_password}" )

    openssl passwd "${_args[@]}"
}
