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
  local _key _password _outfile _alias _workdir _p12_file _chain_file _cert

  # Parse flags
  while (( $# > 0 )); do
    case "${1}" in
      (-k) _key="${2:?ssl_create_jks: -k requires a _key file}";        shift 2 ;;
      (-p) _password="${2:?ssl_create_jks: -p requires a _password}";   shift 2 ;;
      (-o) _outfile="${2:?ssl_create_jks: -o requires an output path}"; shift 2 ;;
      (-a) _alias="${2:?ssl_create_jks: -a requires an _alias}";         shift 2 ;;
      (--) shift; break ;;
      (-*) printf -- '%s\n' "ssl_create_jks: unknown option: ${1}" >&2; return 1 ;;
      (*)  break ;;
    esac
  done

  # Validate required flags
  if [[ -z "${_key}" ]]; then
    printf -- '%s\n' "ssl_create_jks: -k <_key file> is required" >&2
    return 1
  fi
  if [[ -z "${_password}" ]]; then
    printf -- '%s\n' "ssl_create_jks: -p <_password> is required" >&2
    return 1
  fi
  if [[ -z "${_outfile}" ]]; then
    printf -- '%s\n' "ssl_create_jks: -o <output.jks> is required" >&2
    return 1
  fi
  if (( $# == 0 )); then
    printf -- '%s\n' "ssl_create_jks: at least one certificate file required" >&2
    return 1
  fi

  # Default alias to the CN of the first (leaf) certificate
  if [[ -z "${_alias}" ]]; then
    _alias=$(openssl x509 -noout -subject -in "${1}" -nameopt multiline 2>/dev/null |
      awk -F' = ' '/commonName/{print $2; exit}')
    # Fall back to output basename if CN extraction fails
    : "${_alias:="${_outfile##*/}"; _alias="${_alias%.*}"}"
  fi

  # Validate key file
  if [[ ! -f "${_key}" ]]; then
    printf -- '%s\n' "ssl_create_jks: not a file: ${_key}" >&2
    return 1
  fi
  if [[ ! -r "${_key}" ]]; then
    printf -- '%s\n' "ssl_create_jks: permission denied: ${_key}" >&2
    return 1
  fi

  # Validate all cert files before doing any work
  for _cert in "${@}"; do
    if [[ ! -f "${_cert}" ]]; then
      printf -- '%s\n' "ssl_create_jks: not a file: ${_cert}" >&2
      return 1
    fi
    if [[ ! -r "${_cert}" ]]; then
      printf -- '%s\n' "ssl_create_jks: permission denied: ${_cert}" >&2
      return 1
    fi
    if ! openssl x509 -noout -in "${_cert}" 2>/dev/null; then
      printf -- '%s\n' "ssl_create_jks: not a valid PEM certificate: ${_cert}" >&2
      return 1
    fi
  done

  # Set up temp working directory
  _workdir=$(mktemp -d) || { printf -- '%s\n' "ssl_create_jks: failed to create temp directory" >&2; return 1; }
  trap 'rm -rf "${_workdir}"' RETURN

  _chain_file="${_workdir}/chain.crt"
  _p12_file="${_workdir}/_keystore.p12"

  # Assemble certificate chain
  cat -- "${@}" > "${_chain_file}"

  # PEM chain + key → PKCS12
  if ! openssl pkcs12 -export \
      -in "${_chain_file}" \
      -inkey "${_key}" \
      -name "${_alias}" \
      -passout "pass:${_password}" \
      -out "${_p12_file}" 2>/dev/null; then
    printf -- '%s\n' "ssl_create_jks: openssl pkcs12 export failed" >&2
    return 1
  fi

  # Ensure output parent directory exists
  local _outdir
  _outdir="${_outfile%/*}"
  if [[ -n "${_outdir}" ]] && [[ ! -d "${_outdir}" ]]; then
    if ! mkdir -p "${_outdir}"; then
      printf -- '%s\n' "ssl_create_jks: could not create output directory: ${_outdir}" >&2
      return 1
    fi
  fi

  # PKCS12 → JKS
  if ! keytool -importkeystore \
      -srckeystore "${_p12_file}" \
      -srcstoretype PKCS12 \
      -srcstorepass "${_password}" \
      -destkeystore "${_outfile}" \
      -deststoretype JKS \
      -deststorepass "${_password}" \
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
  local _outfile _password _cert _alias _cn _filename _count

  _outfile="${1:?ssl_create_truststore: output file argument required}"
  _password="${2:?ssl_create_truststore: _password argument required}"
  shift 2

  if (( $# == 0 )); then
    printf -- '%s\n' "ssl_create_truststore: at least one certificate file required" >&2
    return 1
  fi

  # Ensure output parent directory exists
  local _outdir
  _outdir="${_outfile%/*}"
  if [[ -n "${_outdir}" ]] && [[ "${_outdir}" != "${_outfile}" ]] && [[ ! -d "${_outdir}" ]]; then
    if ! mkdir -p "${_outdir}"; then
      printf -- '%s\n' "ssl_create_truststore: could not create output directory: ${_outdir}" >&2
      return 1
    fi
  fi

  # Validate all inputs before importing any
  for _cert in "${@}"; do
    if [[ ! -f "${_cert}" ]]; then
      printf -- '%s\n' "ssl_create_truststore: not a file: ${_cert}" >&2
      return 1
    fi
    if [[ ! -r "${_cert}" ]]; then
      printf -- '%s\n' "ssl_create_truststore: permission denied: ${_cert}" >&2
      return 1
    fi
    if ! openssl x509 -noout -in "${_cert}" 2>/dev/null; then
      printf -- '%s\n' "ssl_create_truststore: not a valid PEM certificate: ${_cert}" >&2
      return 1
    fi
  done

  # Build into a temp file; only move to destination on full success
  local _tmpstore
  _tmpstore=$(mktemp --suffix=.jks) || {
    printf -- '%s\n' "ssl_create_truststore: failed to create temp file" >&2
    return 1
  }
  trap 'rm -f "${_tmpstore}"' RETURN
  # mktemp creates an empty file; keytool needs it absent to create a new store
  rm -f "${_tmpstore}"

  _count=0
  for _cert in "${@}"; do
    # Derive alias from filename stem; fall back to CN
    _filename="${_cert##*/}"
    _filename="${_filename%.pem}"
    if [[ -n "${_filename}" ]]; then
      _alias="${_filename}"
    else
      _alias=$(openssl x509 -noout -subject -in "${_cert}" -nameopt multiline 2>/dev/null |
        awk -F' = ' '/commonName/{print $2; exit}')
    fi

    if ! keytool -importcert \
        -trustcacerts \
        -storetype JKS \
        -alias "${_alias}" \
        -file "${_cert}" \
        -keystore "${_tmpstore}" \
        -storepass "${_password}" \
        -noprompt 2>/dev/null; then
      printf -- '%s\n' "ssl_create_truststore: failed to import '${_cert}' (_alias: ${_alias})" >&2
      return 1
    fi
    (( _count++ ))
  done

  mv "${_tmpstore}" "${_outfile}"
  printf -- '%d certificates imported\n' "${_count}"
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
  local _keystore _password _outdir _alias _count

  _keystore="${1:?ssl_split_jks: _keystore file argument required}"
  _password="${2:-}"
  _outdir="${3:-.}"

  if [[ ! -f "${_keystore}" ]]; then
    printf -- '%s\n' "ssl_split_jks: not a file: ${_keystore}" >&2
    return 1
  fi
  if [[ ! -r "${_keystore}" ]]; then
    printf -- '%s\n' "ssl_split_jks: permission denied: ${_keystore}" >&2
    return 1
  fi

  if [[ ! -d "${_outdir}" ]]; then
    if ! mkdir -p "${_outdir}"; then
      printf -- '%s\n' "ssl_split_jks: could not create output directory: ${_outdir}" >&2
      return 1
    fi
  fi

  _count=0
  while IFS= read -r _alias; do
    # Sanitise alias for use as a filename: replace ':' with '_', strip .pem suffix
    local _filename
    _filename="${_alias//:/_}"
    _filename="${_filename%.pem}"
    if ! keytool -exportcert \
        -alias "${_alias}" \
        -keystore "${_keystore}" \
        -storepass "${_password}" \
        -rfc \
        -file "${_outdir}/${_filename}.pem" 2>/dev/null; then
      printf -- '%s\n' "ssl_split_jks: failed to export _alias '${_alias}'" >&2
      return 1
    fi
    (( _count++ ))
  done < <(
    keytool -list -v \
      -keystore "${_keystore}" \
      -storepass "${_password}" \
      </dev/null 2>/dev/null |
      awk '/^Alias name:/{print $NF}'
  )

  if (( _count == 0 )); then
    printf -- '%s\n' "ssl_split_jks: no aliases found in ${_keystore}" >&2
    return 1
  fi

  printf -- '%d certificates extracted\n' "${_count}"
}
