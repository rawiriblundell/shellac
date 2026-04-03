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

[ -n "${_SHELLAC_LOADED_net_url+x}" ] && return 0
_SHELLAC_LOADED_net_url=1

# @description Percent-encode a string for use in a URL query string.
#   Encodes all characters except unreserved: A-Z a-z 0-9 - _ . ~
#
# @arg $1 string Value to encode
#
# @stdout Percent-encoded string
# @exitcode 0 Always
url_encode() {
  local _string _char _encoded _i
  _string="${1}"
  _encoded=""
  for (( _i = 0; _i < ${#_string}; _i++ )); do
    _char="${_string:_i:1}"
    case "${_char}" in
      ([A-Za-z0-9\-_.~]) _encoded+="${_char}" ;;
      (*) _encoded+="$(printf '%%%02X' "'${_char}")" ;;
    esac
  done
  printf -- '%s\n' "${_encoded}"
}

# @description Decode a percent-encoded URL string.
#   Also converts '+' to space (application/x-www-form-urlencoded convention).
#
# @arg $1 string Percent-encoded string
#
# @stdout Decoded string
# @exitcode 0 Always
url_decode() {
  local _encoded
  _encoded="${1//+/ }"
  # Replace %XX with \xXX then interpret with printf %b
  printf -- '%b\n' "${_encoded//%/\\x}"
}

# @description Parse a URL query string into key=value lines.
#   With -n <name>, populates a named associative array instead.
#   Keys and values are percent-decoded. For repeated keys, the last
#   value wins when writing to an associative array.
#
# @arg $1 string Optional: '-n <name>' to specify target associative array name
# @arg $2 string Query string (e.g. 'foo=bar&baz=qux'), or $1 if -n not used
#
# @example
#   url_parse_query 'name=Alice&city=Auckland'
#   # => name=Alice
#   # => city=Auckland
#
#   declare -A params
#   url_parse_query -n params 'name=Alice&city=Auckland'
#   printf '%s\n' "${params[name]}"   # => Alice
#
# @stdout key=value lines (without -n)
# @exitcode 0 Success
# @exitcode 2 Missing argument
url_parse_query() {
  local _arr_name _qs _pair _key _value
  _arr_name=""

  if [[ "${1}" = "-n" ]]; then
    _arr_name="${2:?url_parse_query: -n requires an array name}"
    shift 2
  fi

  _qs="${1:?url_parse_query: query _string argument required}"
  # Strip leading '?' if present
  _qs="${_qs#\?}"

  if [[ -n "${_arr_name}" ]]; then
    local -n _url_parse_query_target="${_arr_name}"
  fi

  local IFS='&'
  for _pair in ${_qs}; do
    _key="${_pair%%=*}"
    _value="${_pair#*=}"
    _key=$(url_decode "${_key}")
    _value=$(url_decode "${_value}")
    if [[ -n "${_arr_name}" ]]; then
      # shellcheck disable=SC2034
      _url_parse_query_target["${_key}"]="${_value}"
    else
      printf -- '%s=%s\n' "${_key}" "${_value}"
    fi
  done
}

# @description Extract a single parameter value from a URL query string.
#
# @arg $1 string Query string (e.g. 'foo=bar&baz=qux')
# @arg $2 string Parameter key to look up
#
# @stdout Parameter value (percent-decoded), or empty if not found
# @exitcode 0 Key found
# @exitcode 1 Key not found
url_get_param() {
  local _qs _key _pair _k _v
  _qs="${1:?url_get_param: query _string argument required}"
  _key="${2:?url_get_param: _key argument required}"
  _qs="${_qs#\?}"

  local IFS='&'
  for _pair in ${_qs}; do
    _k="${_pair%%=*}"
    _v="${_pair#*=}"
    _k=$(url_decode "${_k}")
    if [[ "${_k}" = "${_key}" ]]; then
      url_decode "${_v}"
      return 0
    fi
  done
  return 1
}

# @description Build a percent-encoded query string from key=value arguments.
#   Keys and values are each percent-encoded. Output does not include a leading '?'.
#
# @arg $@ string One or more 'key=value' pairs
#
# @example
#   url_build_query name=Alice city=Auckland
#   # => name=Alice&city=Auckland
#
#   url_build_query "q=hello world" lang=en
#   # => q=hello%20world&lang=en
#
# @stdout Percent-encoded query string
# @exitcode 0 Always
# @exitcode 1 No arguments
url_build_query() {
  (( ${#} == 0 )) && { printf -- '%s\n' "url_build_query: at least one key=value argument required" >&2; return 1; }

  local _pair _key _value result _first
  result=""
  _first=1

  for _pair in "${@}"; do
    _key="${_pair%%=*}"
    _value="${_pair#*=}"
    (( _first )) || result+="&"
    result+="$(url_encode "${_key}")=$(url_encode "${_value}")"
    _first=0
  done

  printf -- '%s\n' "${result}"
}
