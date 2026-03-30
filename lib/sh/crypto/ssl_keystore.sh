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

[ -n "${_SHELLAC_LOADED_crypto_ssl_keystore+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_keystore=1

if ! command -v openssl >/dev/null 2>&1; then
  printf -- '%s\n' "ssl_keystore: this library requires 'openssl', which was not found in PATH" >&2
  return 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  printf -- '%s\n' "ssl_keystore: this library requires 'keytool', which was not found in PATH" >&2
  return 1
fi

# @description Create a Java JKS keystore from a private key and one or more
#   PEM certificate files. Certificate files are joined in the order given
#   (same behaviour as ssl_cert_join). The pipeline is:
#     PEM chain + key → PKCS12 (openssl) → JKS (keytool)
#   A temporary working directory is created and removed on return.
#
# @arg -k string Private key file (required)
# @arg -p string Keystore password (required)
# @arg -o string Output JKS file path (required)
# @arg -a string Alias for the key entry (default: basename of output without extension)
# @arg $@ string One or more PEM certificate files in chain order
#
# @example
#   ssl_create_jks -k server.key -p changeit -o keystore.jks cert.pem intermediate.pem root.pem
#   ssl_create_jks -k server.key -p changeit -o /opt/app/keystore.jks -a myapp cert.pem chain.pem
#
# @exitcode 0 Success
# @exitcode 1 Missing arguments, invalid input files, or openssl/keytool failure
ssl_create_jks() {
  local key password outfile alias workdir p12_file chain_file cert

  # Parse flags
  while (( $# > 0 )); do
    case "${1}" in
      (-k) key="${2:?ssl_create_jks: -k requires a key file}";        shift 2 ;;
      (-p) password="${2:?ssl_create_jks: -p requires a password}";   shift 2 ;;
      (-o) outfile="${2:?ssl_create_jks: -o requires an output path}"; shift 2 ;;
      (-a) alias="${2:?ssl_create_jks: -a requires an alias}";         shift 2 ;;
      (--) shift; break ;;
      (-*) printf -- '%s\n' "ssl_create_jks: unknown option: ${1}" >&2; return 1 ;;
      (*)  break ;;
    esac
  done

  # Validate required flags
  if [[ -z "${key}" ]]; then
    printf -- '%s\n' "ssl_create_jks: -k <key file> is required" >&2
    return 1
  fi
  if [[ -z "${password}" ]]; then
    printf -- '%s\n' "ssl_create_jks: -p <password> is required" >&2
    return 1
  fi
  if [[ -z "${outfile}" ]]; then
    printf -- '%s\n' "ssl_create_jks: -o <output.jks> is required" >&2
    return 1
  fi
  if (( $# == 0 )); then
    printf -- '%s\n' "ssl_create_jks: at least one certificate file required" >&2
    return 1
  fi

  # Default alias to the CN of the first (leaf) certificate
  if [[ -z "${alias}" ]]; then
    alias=$(openssl x509 -noout -subject -in "${1}" -nameopt multiline 2>/dev/null |
      awk -F' = ' '/commonName/{print $2; exit}')
    # Fall back to output basename if CN extraction fails
    : "${alias:="${outfile##*/}"; alias="${alias%.*}"}"
  fi

  # Validate key file
  if [[ ! -f "${key}" ]]; then
    printf -- '%s\n' "ssl_create_jks: not a file: ${key}" >&2
    return 1
  fi
  if [[ ! -r "${key}" ]]; then
    printf -- '%s\n' "ssl_create_jks: permission denied: ${key}" >&2
    return 1
  fi

  # Validate all cert files before doing any work
  for cert in "${@}"; do
    if [[ ! -f "${cert}" ]]; then
      printf -- '%s\n' "ssl_create_jks: not a file: ${cert}" >&2
      return 1
    fi
    if [[ ! -r "${cert}" ]]; then
      printf -- '%s\n' "ssl_create_jks: permission denied: ${cert}" >&2
      return 1
    fi
    if ! openssl x509 -noout -in "${cert}" 2>/dev/null; then
      printf -- '%s\n' "ssl_create_jks: not a valid PEM certificate: ${cert}" >&2
      return 1
    fi
  done

  # Set up temp working directory
  workdir=$(mktemp -d) || { printf -- '%s\n' "ssl_create_jks: failed to create temp directory" >&2; return 1; }
  trap 'rm -rf "${workdir}"' RETURN

  chain_file="${workdir}/chain.crt"
  p12_file="${workdir}/keystore.p12"

  # Assemble certificate chain
  cat -- "${@}" > "${chain_file}"

  # PEM chain + key → PKCS12
  if ! openssl pkcs12 -export \
      -in "${chain_file}" \
      -inkey "${key}" \
      -name "${alias}" \
      -passout "pass:${password}" \
      -out "${p12_file}" 2>/dev/null; then
    printf -- '%s\n' "ssl_create_jks: openssl pkcs12 export failed" >&2
    return 1
  fi

  # Ensure output parent directory exists
  local outdir
  outdir="${outfile%/*}"
  if [[ -n "${outdir}" ]] && [[ ! -d "${outdir}" ]]; then
    if ! mkdir -p "${outdir}"; then
      printf -- '%s\n' "ssl_create_jks: could not create output directory: ${outdir}" >&2
      return 1
    fi
  fi

  # PKCS12 → JKS
  if ! keytool -importkeystore \
      -srckeystore "${p12_file}" \
      -srcstoretype PKCS12 \
      -srcstorepass "${password}" \
      -destkeystore "${outfile}" \
      -deststoretype JKS \
      -deststorepass "${password}" \
      -noprompt 2>/dev/null; then
    printf -- '%s\n' "ssl_create_jks: keytool importkeystore failed" >&2
    return 1
  fi
}

# @description Create a JKS truststore from one or more PEM certificate files.
#   Each certificate is imported as a trusted CA entry using keytool -importcert.
#   The alias for each cert defaults to its CN; falls back to the filename stem.
#   No private key is required — this is for truststores, not keystores.
#
# @arg $1 string Output JKS truststore file path (required)
# @arg $2 string Truststore password (required)
# @arg $@ string One or more PEM certificate files
#
# @example
#   ssl_create_truststore truststore.jks changeit ca1.pem ca2.pem ca3.pem
#   ssl_create_truststore /opt/app/truststore.jks changeit keytooltest/split/*.pem
#
# @stdout Count of certificates imported
# @exitcode 0 Success
# @exitcode 1 Missing arguments, invalid cert, or keytool failure
ssl_create_truststore() {
  local outfile password cert alias cn filename count

  outfile="${1:?ssl_create_truststore: output file argument required}"
  password="${2:?ssl_create_truststore: password argument required}"
  shift 2

  if (( $# == 0 )); then
    printf -- '%s\n' "ssl_create_truststore: at least one certificate file required" >&2
    return 1
  fi

  # Ensure output parent directory exists
  local outdir
  outdir="${outfile%/*}"
  if [[ -n "${outdir}" ]] && [[ "${outdir}" != "${outfile}" ]] && [[ ! -d "${outdir}" ]]; then
    if ! mkdir -p "${outdir}"; then
      printf -- '%s\n' "ssl_create_truststore: could not create output directory: ${outdir}" >&2
      return 1
    fi
  fi

  # Validate all inputs before importing any
  for cert in "${@}"; do
    if [[ ! -f "${cert}" ]]; then
      printf -- '%s\n' "ssl_create_truststore: not a file: ${cert}" >&2
      return 1
    fi
    if [[ ! -r "${cert}" ]]; then
      printf -- '%s\n' "ssl_create_truststore: permission denied: ${cert}" >&2
      return 1
    fi
    if ! openssl x509 -noout -in "${cert}" 2>/dev/null; then
      printf -- '%s\n' "ssl_create_truststore: not a valid PEM certificate: ${cert}" >&2
      return 1
    fi
  done

  # Build into a temp file; only move to destination on full success
  local tmpstore
  tmpstore=$(mktemp --suffix=.jks) || {
    printf -- '%s\n' "ssl_create_truststore: failed to create temp file" >&2
    return 1
  }
  trap 'rm -f "${tmpstore}"' RETURN
  # mktemp creates an empty file; keytool needs it absent to create a new store
  rm -f "${tmpstore}"

  count=0
  for cert in "${@}"; do
    # Derive alias from filename stem; fall back to CN
    filename="${cert##*/}"
    filename="${filename%.pem}"
    if [[ -n "${filename}" ]]; then
      alias="${filename}"
    else
      alias=$(openssl x509 -noout -subject -in "${cert}" -nameopt multiline 2>/dev/null |
        awk -F' = ' '/commonName/{print $2; exit}')
    fi

    if ! keytool -importcert \
        -trustcacerts \
        -storetype JKS \
        -alias "${alias}" \
        -file "${cert}" \
        -keystore "${tmpstore}" \
        -storepass "${password}" \
        -noprompt 2>/dev/null; then
      printf -- '%s\n' "ssl_create_truststore: failed to import '${cert}' (alias: ${alias})" >&2
      return 1
    fi
    (( count++ ))
  done

  mv "${tmpstore}" "${outfile}"
  printf -- '%d certificates imported\n' "${count}"
}

# @description Split a JKS keystore or truststore into individual PEM files,
#   one per alias. Output files are written to the current directory (or a
#   specified output directory) as <alias>.pem.
#
# @arg $1 string Path to the JKS keystore/truststore file (required)
# @arg $2 string Keystore password (default: empty — common for truststores)
# @arg $3 string Output directory (default: current directory)
#
# @example
#   ssl_split_jks truststore.jks changeit /tmp/certs
#   ssl_split_jks truststore.jks          # empty password, current directory
#
# @stdout Count of certificates exported
# @exitcode 0 Success
# @exitcode 1 File not found, no aliases found, or export failure
ssl_split_jks() {
  local keystore password outdir alias count

  keystore="${1:?ssl_split_jks: keystore file argument required}"
  password="${2:-}"
  outdir="${3:-.}"

  if [[ ! -f "${keystore}" ]]; then
    printf -- '%s\n' "ssl_split_jks: not a file: ${keystore}" >&2
    return 1
  fi
  if [[ ! -r "${keystore}" ]]; then
    printf -- '%s\n' "ssl_split_jks: permission denied: ${keystore}" >&2
    return 1
  fi

  if [[ ! -d "${outdir}" ]]; then
    if ! mkdir -p "${outdir}"; then
      printf -- '%s\n' "ssl_split_jks: could not create output directory: ${outdir}" >&2
      return 1
    fi
  fi

  count=0
  while IFS= read -r alias; do
    # Sanitise alias for use as a filename: replace ':' with '_', strip .pem suffix
    local filename
    filename="${alias//:/_}"
    filename="${filename%.pem}"
    if ! keytool -exportcert \
        -alias "${alias}" \
        -keystore "${keystore}" \
        -storepass "${password}" \
        -rfc \
        -file "${outdir}/${filename}.pem" 2>/dev/null; then
      printf -- '%s\n' "ssl_split_jks: failed to export alias '${alias}'" >&2
      return 1
    fi
    (( count++ ))
  done < <(
    keytool -list -v \
      -keystore "${keystore}" \
      -storepass "${password}" \
      </dev/null 2>/dev/null |
      awk '/^Alias name:/{print $NF}'
  )

  if (( count == 0 )); then
    printf -- '%s\n' "ssl_split_jks: no aliases found in ${keystore}" >&2
    return 1
  fi

  printf -- '%d certificates extracted\n' "${count}"
}
