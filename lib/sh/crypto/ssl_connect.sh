# shellcheck shell=ksh

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

[ -n "${_SHELLAC_LOADED_crypto_ssl_connect+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_connect=1

if ! command -v openssl >/dev/null 2>&1; then
    printf -- 'ssl_connect: %s\n' "This library requires 'openssl', which was not found in PATH" >&2
    exit 1
fi

# @description Open an interactive TLS connection to a remote host, displaying OCSP status.
#
# @arg $1 string Remote hostname or IP
# @arg $2 int    Port (default: 443)
#
# @exitcode 0 Connection established (interactive)
# @exitcode 1 No host provided
ssl_connect () {
    local _ssl_connect_remote_host _ssl_connect_remote_port
    _ssl_connect_remote_host="${1}"
    _ssl_connect_remote_port="${2:-443}"

    if (( "${#_ssl_connect_remote_host}" == 0 )); then
        printf -- 'ssl_connect: %s\n' "No remote host defined" >&2
        return 1
    fi

    openssl s_client -status -connect "${_ssl_connect_remote_host}:${_ssl_connect_remote_port}"
}

# @description Connect to a TLS host with an explicit SNI name.
#   Useful for virtual-hosted TLS where the SNI name differs from the connect address.
#
# @arg $1 string Remote host
# @arg $2 int    Port (default: 443)
# @arg $3 string SNI hostname (default: same as host)
#
# @example
#   ssl_connect_sni 192.168.1.10 443 example.com
#
# @exitcode 0 Connection established (interactive)
ssl_connect_sni() {
    local _host _port _sni
    _host="${1:?ssl_connect_sni: No remote host provided}"
    _port="${2:-443}"
    _sni="${3:-${_host}}"
    openssl s_client -connect "${_host}:${_port}" -servername "${_sni}"
}

# @description Connect to a STARTTLS service for certificate inspection.
#   Protocol determines the default port; port may be overridden as third argument.
#
# @arg $1 string Remote host
# @arg $2 string Protocol: smtp (587), imap (143), pop3 (110), ftp (21), xmpp (5222) (default: smtp)
# @arg $3 int    Port override (optional)
#
# @example
#   ssl_connect_starttls mail.example.com smtp
#   ssl_connect_starttls mail.example.com imap 993
#
# @exitcode 0 Connection established (interactive)
ssl_connect_starttls() {
    local _host _proto _port
    _host="${1:?ssl_connect_starttls: No remote host provided}"
    _proto="${2:-smtp}"
    case "${_proto}" in
        (smtp)  _port="${3:-587}"  ;;
        (imap)  _port="${3:-143}"  ;;
        (pop3)  _port="${3:-110}"  ;;
        (ftp)   _port="${3:-21}"   ;;
        (xmpp)  _port="${3:-5222}" ;;
        (*)     _port="${3:-25}"   ;;
    esac
    openssl s_client -connect "${_host}:${_port}" -starttls "${_proto}"
}

# @description Retrieve the TLS certificate from a remote host and print it as PEM.
#   Non-interactive: reads from /dev/null so openssl does not wait for input.
#   If an output file is given, writes PEM there instead of stdout.
#
# @arg $1 string Remote host
# @arg $2 int    Port (default: 443)
# @arg $3 string Output file path (optional; default: stdout)
#
# @example
#   ssl_fetch_cert example.com > example.pem
#   ssl_fetch_cert example.com 443 example.pem
#
# @stdout PEM certificate (if no output file given)
# @exitcode 0 Success
# @exitcode 1 Connection or parse error
ssl_fetch_cert() {
    local _host _port _out
    _host="${1:?ssl_fetch_cert: No remote host provided}"
    _port="${2:-443}"
    _out="${3:-}"
    if [[ -n "${_out}" ]]; then
        openssl s_client -connect "${_host}:${_port}" -servername "${_host}" \
            </dev/null 2>/dev/null | openssl x509 -out "${_out}"
    else
        openssl s_client -connect "${_host}:${_port}" -servername "${_host}" \
            </dev/null 2>/dev/null | openssl x509
    fi
}
