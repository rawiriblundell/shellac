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
  local key password outfile alias workdir chain_file cert

  while (( $# > 0 )); do
    case "${1}" in
      (-k) key="${2:?ssl_create_p12: -k requires a key file}";        shift 2 ;;
      (-p) password="${2:?ssl_create_p12: -p requires a password}";   shift 2 ;;
      (-o) outfile="${2:?ssl_create_p12: -o requires an output path}"; shift 2 ;;
      (-a) alias="${2:?ssl_create_p12: -a requires an alias}";         shift 2 ;;
      (--) shift; break ;;
      (-*) printf -- '%s\n' "ssl_create_p12: unknown option: ${1}" >&2; return 1 ;;
      (*)  break ;;
    esac
  done

  if [[ -z "${key}" ]];      then printf -- '%s\n' "ssl_create_p12: -k <key file> is required" >&2;    return 1; fi
  if [[ -z "${password}" ]]; then printf -- '%s\n' "ssl_create_p12: -p <password> is required" >&2;    return 1; fi
  if [[ -z "${outfile}" ]];  then printf -- '%s\n' "ssl_create_p12: -o <output.p12> is required" >&2;  return 1; fi
  if (( $# == 0 )); then         printf -- '%s\n' "ssl_create_p12: at least one certificate file required" >&2; return 1; fi

  # Default alias to CN of first (leaf) cert
  if [[ -z "${alias}" ]]; then
    alias=$(openssl x509 -noout -subject -in "${1}" -nameopt multiline 2>/dev/null |
      awk -F' = ' '/commonName/{print $2; exit}')
    : "${alias:="${outfile##*/}"; alias="${alias%.*}"}"
  fi

  if [[ ! -f "${key}" ]]; then
    printf -- '%s\n' "ssl_create_p12: not a file: ${key}" >&2; return 1
  fi
  if [[ ! -r "${key}" ]]; then
    printf -- '%s\n' "ssl_create_p12: permission denied: ${key}" >&2; return 1
  fi

  for cert in "${@}"; do
    if [[ ! -f "${cert}" ]]; then
      printf -- '%s\n' "ssl_create_p12: not a file: ${cert}" >&2; return 1
    fi
    if [[ ! -r "${cert}" ]]; then
      printf -- '%s\n' "ssl_create_p12: permission denied: ${cert}" >&2; return 1
    fi
    if ! openssl x509 -noout -in "${cert}" 2>/dev/null; then
      printf -- '%s\n' "ssl_create_p12: not a valid PEM certificate: ${cert}" >&2; return 1
    fi
  done

  local outdir
  outdir="${outfile%/*}"
  if [[ -n "${outdir}" ]] && [[ "${outdir}" != "${outfile}" ]] && [[ ! -d "${outdir}" ]]; then
    mkdir -p "${outdir}" || { printf -- '%s\n' "ssl_create_p12: could not create directory: ${outdir}" >&2; return 1; }
  fi

  workdir=$(mktemp -d) || { printf -- '%s\n' "ssl_create_p12: failed to create temp directory" >&2; return 1; }
  trap 'rm -rf "${workdir}"' RETURN
  chain_file="${workdir}/chain.crt"
  cat -- "${@}" > "${chain_file}"

  if ! openssl pkcs12 -export \
      -in "${chain_file}" \
      -inkey "${key}" \
      -name "${alias}" \
      -passout "pass:${password}" \
      -out "${outfile}" 2>/dev/null; then
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
  local outfile password cert workdir chain_file tmpstore count

  outfile="${1:?ssl_create_p12_truststore: output file argument required}"
  password="${2:?ssl_create_p12_truststore: password argument required}"
  shift 2

  if (( $# == 0 )); then
    printf -- '%s\n' "ssl_create_p12_truststore: at least one certificate file required" >&2
    return 1
  fi

  local outdir
  outdir="${outfile%/*}"
  if [[ -n "${outdir}" ]] && [[ "${outdir}" != "${outfile}" ]] && [[ ! -d "${outdir}" ]]; then
    mkdir -p "${outdir}" || { printf -- '%s\n' "ssl_create_p12_truststore: could not create directory: ${outdir}" >&2; return 1; }
  fi

  for cert in "${@}"; do
    if [[ ! -f "${cert}" ]]; then
      printf -- '%s\n' "ssl_create_p12_truststore: not a file: ${cert}" >&2; return 1
    fi
    if [[ ! -r "${cert}" ]]; then
      printf -- '%s\n' "ssl_create_p12_truststore: permission denied: ${cert}" >&2; return 1
    fi
    if ! openssl x509 -noout -in "${cert}" 2>/dev/null; then
      printf -- '%s\n' "ssl_create_p12_truststore: not a valid PEM certificate: ${cert}" >&2; return 1
    fi
  done

  workdir=$(mktemp -d) || { printf -- '%s\n' "ssl_create_p12_truststore: failed to create temp directory" >&2; return 1; }
  trap 'rm -rf "${workdir}"' RETURN

  chain_file="${workdir}/chain.pem"
  tmpstore="${workdir}/truststore.p12"
  cat -- "${@}" > "${chain_file}"
  count=$(grep -c -- '-BEGIN CERTIFICATE-' "${chain_file}")

  if ! openssl pkcs12 -export \
      -nokeys \
      -in "${chain_file}" \
      -passout "pass:${password}" \
      -out "${tmpstore}" 2>/dev/null; then
    printf -- '%s\n' "ssl_create_p12_truststore: openssl pkcs12 export failed" >&2
    return 1
  fi

  mv "${tmpstore}" "${outfile}"
  printf -- '%d certificates imported\n' "${count}"
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
  local p12 password outdir workdir bundle cert_count cn filename i

  p12="${1:?ssl_split_p12: .p12 file argument required}"
  password="${2?ssl_split_p12: password argument required}"
  outdir="${3:-.}"

  if [[ ! -f "${p12}" ]]; then
    printf -- '%s\n' "ssl_split_p12: not a file: ${p12}" >&2; return 1
  fi
  if [[ ! -r "${p12}" ]]; then
    printf -- '%s\n' "ssl_split_p12: permission denied: ${p12}" >&2; return 1
  fi

  if [[ ! -d "${outdir}" ]]; then
    mkdir -p "${outdir}" || { printf -- '%s\n' "ssl_split_p12: could not create output directory: ${outdir}" >&2; return 1; }
  fi

  workdir=$(mktemp -d) || { printf -- '%s\n' "ssl_split_p12: failed to create temp directory" >&2; return 1; }
  trap 'rm -rf "${workdir}"' RETURN

  bundle="${workdir}/bundle.pem"

  # Extract all certs (no key material)
  if ! openssl pkcs12 \
      -in "${p12}" \
      -passin "pass:${password}" \
      -nokeys \
      -out "${bundle}" 2>/dev/null; then
    printf -- '%s\n' "ssl_split_p12: failed to extract certificates from ${p12}" >&2
    return 1
  fi

  cert_count=$(grep -c -- '-BEGIN CERTIFICATE-' "${bundle}" 2>/dev/null)
  if (( cert_count == 0 )); then
    printf -- '%s\n' "ssl_split_p12: no certificates found in ${p12}" >&2
    return 1
  fi

  # Split bundle into numbered temp files, then rename by CN
  awk -v prefix="${workdir}/cert" \
    '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/{
       if (/BEGIN/) { n++ }
       out = sprintf("%s%02d.pem", prefix, n)
       print > out
     }' "${bundle}"

  i=0
  local tmpfile
  for tmpfile in "${workdir}"/cert*.pem; do
    cn=$(openssl x509 -noout -subject -in "${tmpfile}" -nameopt multiline 2>/dev/null |
      awk -F' = ' '/commonName/{print $2; exit}')
    # Sanitise: replace spaces and slashes with underscores
    cn="${cn// /_}"
    cn="${cn//\//_}"
    (( i++ ))
    filename="${cn:-$(printf 'cert%02d' "${i}")}"
    mv "${tmpfile}" "${outdir}/${filename}.pem"
  done

  printf -- '%d certificates extracted\n' "${cert_count}"
}
