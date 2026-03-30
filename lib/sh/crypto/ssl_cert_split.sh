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
  local bundle prefix outdir cert_count
  bundle="${1:?ssl_cert_split: bundle file argument required}"
  prefix="${2:-cert}"
  outdir="${3:-.}"

  if [[ ! -f "${bundle}" ]]; then
    printf -- '%s\n' "ssl_cert_split: not a file: ${bundle}" >&2
    return 1
  fi
  if [[ ! -r "${bundle}" ]]; then
    printf -- '%s\n' "ssl_cert_split: permission denied: ${bundle}" >&2
    return 1
  fi

  cert_count=$(grep -c -- '-BEGIN CERTIFICATE-' "${bundle}" 2>/dev/null)
  if (( cert_count == 0 )); then
    printf -- '%s\n' "ssl_cert_split: no PEM certificates found in ${bundle}" >&2
    return 1
  fi

  if [[ ! -d "${outdir}" ]]; then
    if ! mkdir -p "${outdir}"; then
      printf -- '%s\n' "ssl_cert_split: could not create output directory: ${outdir}" >&2
      return 1
    fi
  fi

  awk -v prefix="${outdir}/${prefix}" \
    '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/{
       if (/BEGIN/) { n++ }
       out = sprintf("%s%02d.pem", prefix, n)
       print > out
     }' "${bundle}"

  printf -- '%d certificates extracted\n' "${cert_count}"
}
