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

[ -n "${_SHELLAC_LOADED_crypto_ssl_cert_join+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssl_cert_join=1

# @description Join two or more PEM certificate files into a single chain bundle.
#   Each input file is validated as a PEM certificate before concatenation.
#   Output is written to stdout or to a file with -o.
#
# @arg $1 string Optional: '-o <file>' to write output to a file
# @arg $@ string Two or more PEM certificate files (order determines chain order)
#
# @example
#   ssl_cert_join cert.pem intermediate.pem root.pem > bundle.pem
#   ssl_cert_join -o bundle.pem cert.pem intermediate.pem root.pem
#
# @stdout PEM chain bundle
# @exitcode 0 Success
# @exitcode 1 Missing arguments, unreadable file, or invalid PEM certificate
ssl_cert_join() {
  local outfile cert

  if [[ "${1}" = "-o" ]]; then
    outfile="${2:?ssl_cert_join: -o requires an output file path}"
    shift 2
  fi

  if (( ${#} < 1 )); then
    printf -- '%s\n' "ssl_cert_join: at least one certificate file required" >&2
    return 1
  fi

  # Validate all inputs before writing any output
  for cert in "${@}"; do
    if [[ ! -f "${cert}" ]]; then
      printf -- '%s\n' "ssl_cert_join: not a file: ${cert}" >&2
      return 1
    fi
    if [[ ! -r "${cert}" ]]; then
      printf -- '%s\n' "ssl_cert_join: permission denied: ${cert}" >&2
      return 1
    fi
    if ! openssl x509 -noout -in "${cert}" 2>/dev/null; then
      printf -- '%s\n' "ssl_cert_join: not a valid PEM certificate: ${cert}" >&2
      return 1
    fi
  done

  if [[ -n "${outfile}" ]]; then
    cat -- "${@}" > "${outfile}"
  else
    cat -- "${@}"
  fi
}
