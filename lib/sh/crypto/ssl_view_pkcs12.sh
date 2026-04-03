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

[ -n "${_SHELLAC_LOADED_crypto_ssl_view_pkcs12+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_view_pkcs12=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_view_pkcs12: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Display the contents of a PKCS#12 bundle (.p12 / .pfx).
#   openssl will prompt for the import password interactively.
#
# @arg $1 string PKCS#12 file (.p12 or .pfx)
#
# @stdout Certificate and key information from the bundle
# @exitcode 0 Success
# @exitcode 1 No input provided
ssl_view_pkcs12 () {
    local _ssl_view_pkcs12_in
    _ssl_view_pkcs12_in="${1}"

    if (( "${#_ssl_view_pkcs12_in}" == 0 )); then
        printf -- 'ssl_view_pkcs12: %s\n' "No input file provided" >&2
        return 1
    fi

    openssl pkcs12 -info -in "${_ssl_view_pkcs12_in}"
}
