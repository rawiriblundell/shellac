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

[ -n "${_SHELLAC_LOADED_crypto_ssl_cert_split+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_cert_split=1

# @description Split a PEM bundle containing one or more certificates into
#   individual files. Output files are written to the current directory (or
#   a specified output directory) as <prefix>01.pem, <prefix>02.pem, etc.
#
# @arg $1 string Path to the PEM bundle file (required)
# @arg $2 string Optional: output prefix (default: 'cert')
# @arg $3 string Optional: output directory (default: current directory)
#
# @example
#   ssl_cert_split bundle.pem
#   # => cert01.pem  cert02.pem  cert03.pem
#
#   ssl_cert_split bundle.pem chain /tmp/certs
#   # => /tmp/certs/chain01.pem  /tmp/certs/chain02.pem
#
# @stdout Count of certificates extracted
# @exitcode 0 Success
# @exitcode 1 File not found, not readable, no certificates found, or output dir error
ssl_cert_split() {
  local _bundle _prefix _outdir _cert_count
  _bundle="${1:?ssl_cert_split: _bundle file argument required}"
  _prefix="${2:-cert}"
  _outdir="${3:-.}"

  if [[ ! -f "${_bundle}" ]]; then
    printf -- '%s\n' "ssl_cert_split: not a file: ${_bundle}" >&2
    return 1
  fi
  if [[ ! -r "${_bundle}" ]]; then
    printf -- '%s\n' "ssl_cert_split: permission denied: ${_bundle}" >&2
    return 1
  fi

  _cert_count=$(grep -c -- '-BEGIN CERTIFICATE-' "${_bundle}" 2>/dev/null)
  if (( _cert_count == 0 )); then
    printf -- '%s\n' "ssl_cert_split: no PEM certificates found in ${_bundle}" >&2
    return 1
  fi

  if [[ ! -d "${_outdir}" ]]; then
    if ! mkdir -p "${_outdir}"; then
      printf -- '%s\n' "ssl_cert_split: could not create output directory: ${_outdir}" >&2
      return 1
    fi
  fi

  awk -v _prefix="${_outdir}/${_prefix}" \
    '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/{
       if (/BEGIN/) { n++ }
       out = sprintf("%s%02d.pem", _prefix, n)
       print > out
     }' "${_bundle}"

  printf -- '%d certificates extracted\n' "${_cert_count}"
}
