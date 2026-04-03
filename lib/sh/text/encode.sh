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

[ -n "${_SHELLAC_LOADED_text_encode+x}" ] && return 0
_SHELLAC_LOADED_text_encode=1

# @description Percent-encode a string for use in a URL (RFC 3986).
#   Unreserved characters (A-Z a-z 0-9 - _ . ~) are passed through unchanged.
#
# @arg $@ string The string to encode
#
# @example
#   str_url_encode "hello world"   # => hello%20world
#   str_url_encode "foo=bar&baz"   # => foo%3Dbar%26baz
#
# @stdout URL-encoded string
# @exitcode 0 Always
str_url_encode() {
  local _input _encoded _char _i
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  _encoded=""
  for (( _i = 0; _i < ${#_input}; _i++ )); do
    _char="${_input:_i:1}"
    case "${_char}" in
      ([a-zA-Z0-9.~_-])
        _encoded+="${_char}"
      ;;
      (*)
        # shellcheck disable=SC2059
        printf -v _char '%%%02X' "'${_char}"
        _encoded+="${_char}"
      ;;
    esac
  done
  printf -- '%s\n' "${_encoded}"
}

# @description Decode a percent-encoded URL string. Plus signs are decoded
#   as spaces (application/x-www-form-urlencoded convention).
#
# @arg $@ string The URL-encoded string to decode
#
# @example
#   str_url_decode "hello%20world"   # => hello world
#   str_url_decode "foo%3Dbar"       # => foo=bar
#
# @stdout Decoded string
# @exitcode 0 Always
str_url_decode() {
  local _input
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  _input="${_input//+/ }"
  printf -- '%b\n' "${_input//%/\\x}"
}

# @internal
# Encode stdin to base64. Tries base64, then openssl, then uuencode.
_str_base64_encode() {
  if command -v base64 >/dev/null 2>&1; then
    base64
  elif command -v openssl >/dev/null 2>&1; then
    openssl base64
  elif command -v uuencode >/dev/null 2>&1; then
    uuencode -r -m -
  else
    printf -- '%s\n' "str_to_base64: no base64 tool found (tried: base64, openssl, uuencode)" >&2
    return 1
  fi
}

# @internal
# Decode base64 stdin. Tries base64 -d, then openssl, then uudecode.
_str_base64_decode() {
  if command -v base64 >/dev/null 2>&1; then
    base64 -d
  elif command -v openssl >/dev/null 2>&1; then
    openssl base64 -d
  elif command -v uudecode >/dev/null 2>&1; then
    uudecode -r -m
  else
    printf -- '%s\n' "str_from_base64: no base64 tool found (tried: base64, openssl, uudecode)" >&2
    return 1
  fi
}

# @description Base64-encode a string. Tries base64, openssl, uuencode in order.
#
# @arg $@ string The string to encode
#
# @example
#   str_to_base64 "hello world"   # => aGVsbG8gd29ybGQ=
#
# @stdout Base64-encoded string
# @exitcode 0 Success
# @exitcode 1 No suitable tool found
str_to_base64() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    _str_base64_encode
  else
    printf -- '%s' "${*}" | _str_base64_encode
  fi
}

# @description Decode a base64-encoded string. Tries base64, openssl, uudecode in order.
#
# @arg $@ string The base64-encoded string to decode
#
# @example
#   str_from_base64 "aGVsbG8gd29ybGQ="   # => hello world
#
# @stdout Decoded string
# @exitcode 0 Success
# @exitcode 1 No suitable tool found
str_from_base64() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    _str_base64_decode
  else
    printf -- '%s' "${*}" | _str_base64_decode
  fi
}

# @description Escape a string for safe use as a shell argument.
#   Uses bash's printf %q format, which produces output suitable for reuse
#   as input to the shell.
#
# @arg $@ string The string to escape
#
# @example
#   str_escape "hello world"     # => hello\ world
#   str_escape "it's a test"     # => it\'s\ a\ test
#
# @stdout Shell-escaped string
# @exitcode 0 Always
str_escape() {
  local _input
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  printf -- '%q\n' "${_input}"
}

# @description Convert a string to its hexadecimal representation.
#   Requires xxd.
#
# @arg $1 string The string to convert
#
# @stdout Hex-encoded string (no spaces, lowercase)
# @exitcode 0 Always
str_to_hex() {
  local _input
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${1:?No string supplied}"
  fi
  printf -- '%s' "${_input}" | xxd -pu
}
