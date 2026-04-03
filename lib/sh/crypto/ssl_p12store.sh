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

[ -n "${_SHELLAC_LOADED_crypto_ssl_p12store+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_p12store=1

if ! command -v openssl >/dev/null 2>&1; then
  printf -- '%s\n' "ssl_p12store: this library requires 'openssl', which was not found in PATH" >&2
  return 1
fi

# @description Create a PKCS#12 keystore from a private key and one or more
#   PEM certificate files. Certificate files are joined in the order given
#   (same behaviour as ssl_cert_join). Non-interactive; password supplied via -p.
#   Alias defaults to the CN of the first (leaf) certificate.
#
# @arg -k string Private key file (required)
# @arg -p string Export password (required)
# @arg -o string Output .p12 file path (required)
# @arg -a string Alias/friendly name for the key entry (default: CN of first cert)
# @arg $@ string One or more PEM certificate files in chain order
#
# @example
#   ssl_create_p12 -k server.key -p changeit -o keystore.p12 cert.pem intermediate.pem
#   ssl_create_p12 -k server.key -p changeit -o keystore.p12 -a myapp cert.pem chain.pem
#
# @exitcode 0 Success
# @exitcode 1 Missing arguments, invalid input files, or openssl failure
ssl_create_p12() {
  local _key _password _outfile _alias _workdir _chain_file _cert

  while (( $# > 0 )); do
    case "${1}" in
      (-k) _key="${2:?ssl_create_p12: -k requires a _key file}";        shift 2 ;;
      (-p) _password="${2:?ssl_create_p12: -p requires a _password}";   shift 2 ;;
      (-o) _outfile="${2:?ssl_create_p12: -o requires an output path}"; shift 2 ;;
      (-a) _alias="${2:?ssl_create_p12: -a requires an _alias}";         shift 2 ;;
      (--) shift; break ;;
      (-*) printf -- '%s\n' "ssl_create_p12: unknown option: ${1}" >&2; return 1 ;;
      (*)  break ;;
    esac
  done

  if [[ -z "${_key}" ]];      then printf -- '%s\n' "ssl_create_p12: -k <_key file> is required" >&2;    return 1; fi
  if [[ -z "${_password}" ]]; then printf -- '%s\n' "ssl_create_p12: -p <_password> is required" >&2;    return 1; fi
  if [[ -z "${_outfile}" ]];  then printf -- '%s\n' "ssl_create_p12: -o <output._p12> is required" >&2;  return 1; fi
  if (( $# == 0 )); then         printf -- '%s\n' "ssl_create_p12: at least one certificate file required" >&2; return 1; fi

  # Default alias to CN of first (leaf) cert
  if [[ -z "${_alias}" ]]; then
    _alias=$(openssl x509 -noout -subject -in "${1}" -nameopt multiline 2>/dev/null |
      awk -F' = ' '/commonName/{print $2; exit}')
    : "${_alias:="${_outfile##*/}"; _alias="${_alias%.*}"}"
  fi

  if [[ ! -f "${_key}" ]]; then
    printf -- '%s\n' "ssl_create_p12: not a file: ${_key}" >&2; return 1
  fi
  if [[ ! -r "${_key}" ]]; then
    printf -- '%s\n' "ssl_create_p12: permission denied: ${_key}" >&2; return 1
  fi

  for _cert in "${@}"; do
    if [[ ! -f "${_cert}" ]]; then
      printf -- '%s\n' "ssl_create_p12: not a file: ${_cert}" >&2; return 1
    fi
    if [[ ! -r "${_cert}" ]]; then
      printf -- '%s\n' "ssl_create_p12: permission denied: ${_cert}" >&2; return 1
    fi
    if ! openssl x509 -noout -in "${_cert}" 2>/dev/null; then
      printf -- '%s\n' "ssl_create_p12: not a valid PEM certificate: ${_cert}" >&2; return 1
    fi
  done

  local _outdir
  _outdir="${_outfile%/*}"
  if [[ -n "${_outdir}" ]] && [[ "${_outdir}" != "${_outfile}" ]] && [[ ! -d "${_outdir}" ]]; then
    mkdir -p "${_outdir}" || { printf -- '%s\n' "ssl_create_p12: could not create directory: ${_outdir}" >&2; return 1; }
  fi

  _workdir=$(mktemp -d) || { printf -- '%s\n' "ssl_create_p12: failed to create temp directory" >&2; return 1; }
  trap 'rm -rf "${_workdir}"' RETURN
  _chain_file="${_workdir}/chain.crt"
  cat -- "${@}" > "${_chain_file}"

  if ! openssl pkcs12 -export \
      -in "${_chain_file}" \
      -inkey "${_key}" \
      -name "${_alias}" \
      -passout "pass:${_password}" \
      -out "${_outfile}" 2>/dev/null; then
    printf -- '%s\n' "ssl_create_p12: openssl pkcs12 export failed" >&2
    return 1
  fi
}

# @description Create a PKCS#12 trust bundle from one or more PEM certificate files.
#   Contains only trusted certificates — no private key. Atomic write via temp file.
#
# @arg $1 string Output .p12 file path (required)
# @arg $2 string Export password (required)
# @arg $@ string One or more PEM certificate files
#
# @example
#   ssl_create_p12_truststore truststore.p12 changeit ca1.pem ca2.pem
#
# @stdout Count of certificates imported
# @exitcode 0 Success
# @exitcode 1 Missing arguments, invalid cert, or openssl failure
ssl_create_p12_truststore() {
  local _outfile _password _cert _workdir _chain_file _tmpstore _count

  _outfile="${1:?ssl_create_p12_truststore: output file argument required}"
  _password="${2:?ssl_create_p12_truststore: _password argument required}"
  shift 2

  if (( $# == 0 )); then
    printf -- '%s\n' "ssl_create_p12_truststore: at least one certificate file required" >&2
    return 1
  fi

  local _outdir
  _outdir="${_outfile%/*}"
  if [[ -n "${_outdir}" ]] && [[ "${_outdir}" != "${_outfile}" ]] && [[ ! -d "${_outdir}" ]]; then
    mkdir -p "${_outdir}" || { printf -- '%s\n' "ssl_create_p12_truststore: could not create directory: ${_outdir}" >&2; return 1; }
  fi

  for _cert in "${@}"; do
    if [[ ! -f "${_cert}" ]]; then
      printf -- '%s\n' "ssl_create_p12_truststore: not a file: ${_cert}" >&2; return 1
    fi
    if [[ ! -r "${_cert}" ]]; then
      printf -- '%s\n' "ssl_create_p12_truststore: permission denied: ${_cert}" >&2; return 1
    fi
    if ! openssl x509 -noout -in "${_cert}" 2>/dev/null; then
      printf -- '%s\n' "ssl_create_p12_truststore: not a valid PEM certificate: ${_cert}" >&2; return 1
    fi
  done

  _workdir=$(mktemp -d) || { printf -- '%s\n' "ssl_create_p12_truststore: failed to create temp directory" >&2; return 1; }
  trap 'rm -rf "${_workdir}"' RETURN

  _chain_file="${_workdir}/chain.pem"
  _tmpstore="${_workdir}/truststore._p12"
  cat -- "${@}" > "${_chain_file}"
  _count=$(grep -c -- '-BEGIN CERTIFICATE-' "${_chain_file}")

  if ! openssl pkcs12 -export \
      -nokeys \
      -in "${_chain_file}" \
      -passout "pass:${_password}" \
      -out "${_tmpstore}" 2>/dev/null; then
    printf -- '%s\n' "ssl_create_p12_truststore: openssl pkcs12 export failed" >&2
    return 1
  fi

  mv "${_tmpstore}" "${_outfile}"
  printf -- '%d certificates imported\n' "${_count}"
}

# @description Split a PKCS#12 file into individual PEM certificate files.
#   Extracts all certificates (leaf and CA chain), writing one file per cert
#   named by the certificate's CN. Falls back to a numbered prefix if CN is absent.
#   Output directory is created if it does not exist.
#
# @arg $1 string Path to the .p12 file (required)
# @arg $2 string Password (required; use '' for no password)
# @arg $3 string Output directory (default: current directory)
#
# @example
#   ssl_split_p12 bundle.p12 changeit /tmp/certs
#
# @stdout Count of certificates extracted
# @exitcode 0 Success
# @exitcode 1 File not found, no certs found, or extraction failure
ssl_split_p12() {
  local _p12 _password _outdir _workdir _bundle _cert_count _cn _filename _i

  _p12="${1:?ssl_split_p12: ._p12 file argument required}"
  _password="${2?ssl_split_p12: _password argument required}"
  _outdir="${3:-.}"

  if [[ ! -f "${_p12}" ]]; then
    printf -- '%s\n' "ssl_split_p12: not a file: ${_p12}" >&2; return 1
  fi
  if [[ ! -r "${_p12}" ]]; then
    printf -- '%s\n' "ssl_split_p12: permission denied: ${_p12}" >&2; return 1
  fi

  if [[ ! -d "${_outdir}" ]]; then
    mkdir -p "${_outdir}" || { printf -- '%s\n' "ssl_split_p12: could not create output directory: ${_outdir}" >&2; return 1; }
  fi

  _workdir=$(mktemp -d) || { printf -- '%s\n' "ssl_split_p12: failed to create temp directory" >&2; return 1; }
  trap 'rm -rf "${_workdir}"' RETURN

  _bundle="${_workdir}/_bundle.pem"

  # Extract all certs (no key material)
  if ! openssl pkcs12 \
      -in "${_p12}" \
      -passin "pass:${_password}" \
      -nokeys \
      -out "${_bundle}" 2>/dev/null; then
    printf -- '%s\n' "ssl_split_p12: failed to extract certificates from ${_p12}" >&2
    return 1
  fi

  _cert_count=$(grep -c -- '-BEGIN CERTIFICATE-' "${_bundle}" 2>/dev/null)
  if (( _cert_count == 0 )); then
    printf -- '%s\n' "ssl_split_p12: no certificates found in ${_p12}" >&2
    return 1
  fi

  # Split bundle into numbered temp files, then rename by CN
  awk -v prefix="${_workdir}/_cert" \
    '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/{
       if (/BEGIN/) { n++ }
       out = sprintf("%s%02d.pem", prefix, n)
       print > out
     }' "${_bundle}"

  _i=0
  local _tmpfile
  for _tmpfile in "${_workdir}"/_cert*.pem; do
    _cn=$(openssl x509 -noout -subject -in "${_tmpfile}" -nameopt multiline 2>/dev/null |
      awk -F' = ' '/commonName/{print $2; exit}')
    # Sanitise: replace spaces and slashes with underscores
    _cn="${_cn// /_}"
    _cn="${_cn//\//_}"
    (( _i++ ))
    _filename="${_cn:-$(printf '_cert%02d' "${_i}")}"
    mv "${_tmpfile}" "${_outdir}/${_filename}.pem"
  done

  printf -- '%d certificates extracted\n' "${_cert_count}"
}
