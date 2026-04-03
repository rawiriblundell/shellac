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

[ -n "${_SHELLAC_LOADED_text_prefix_suffix+x}" ] && return 0
_SHELLAC_LOADED_text_prefix_suffix=1

# @description Remove a prefix from a string. If the string does not start
#   with the prefix, the original string is returned unchanged.
#
# @arg $1 string The string to process
# @arg $2 string The prefix to remove
#
# @example
#   str_remove_prefix "foobar" "foo"   # => bar
#   str_remove_prefix "foobar" "baz"   # => foobar
#
# @stdout String with prefix removed
# @exitcode 0 Always
str_remove_prefix() {
  local _str _prefix
  _str="${1:?No string given}"
  _prefix="${2:?No prefix given}"
  printf -- '%s\n' "${_str#"${_prefix}"}"
}

# @description Remove a suffix from a string. If the string does not end
#   with the suffix, the original string is returned unchanged.
#
# @arg $1 string The string to process
# @arg $2 string The suffix to remove
#
# @example
#   str_remove_suffix "foobar" "bar"   # => foo
#   str_remove_suffix "foobar" "baz"   # => foobar
#
# @stdout String with suffix removed
# @exitcode 0 Always
str_remove_suffix() {
  local _str _suffix
  _str="${1:?No string given}"
  _suffix="${2:?No suffix given}"
  printf -- '%s\n' "${_str%"${_suffix}"}"
}

# @description Append a suffix to a string if the string does not already
#   end with that suffix.
#
# @arg $1 string The string to process
# @arg $2 string The suffix to append if missing
#
# @example
#   str_append_if_missing "/etc/hosts" "s"   # => /etc/hostss
#   str_append_if_missing "/etc/hosts" "/"   # => /etc/hosts/
#   str_append_if_missing "/etc/hosts/" "/"  # => /etc/hosts/
#
# @stdout String with suffix appended if it was missing
# @exitcode 0 Always
str_append_if_missing() {
  local _str _suffix
  _str="${1:?No string given}"
  _suffix="${2:?No suffix given}"
  [[ "${_str}" = *"${_suffix}" ]] || _str="${_str}${_suffix}"
  printf -- '%s\n' "${_str}"
}

# @description Prepend a prefix to a string if the string does not already
#   start with that prefix.
#
# @arg $1 string The string to process
# @arg $2 string The prefix to prepend if missing
#
# @example
#   str_prepend_if_missing "etc/hosts" "/"   # => /etc/hosts
#   str_prepend_if_missing "/etc/hosts" "/"  # => /etc/hosts
#
# @stdout String with prefix prepended if it was missing
# @exitcode 0 Always
str_prepend_if_missing() {
  local _str _prefix
  _str="${1:?No string given}"
  _prefix="${2:?No prefix given}"
  [[ "${_str}" = "${_prefix}"* ]] || _str="${_prefix}${_str}"
  printf -- '%s\n' "${_str}"
}

# @description Append one string to another and print the result.
#   Optionally define a delimiter with -d|--delimiter (defaults to a single space).
#
# @arg $1 string Optional: -d|--delimiter followed by delimiter string
# @arg $2 string First string
# @arg $3 string Second string to append
#
# @example
#   str_append -d ':' foo bar   # => foo:bar
#   str_append foo bar          # => foo bar
#
# @stdout Concatenated string
# @exitcode 0 Always
str_append() {
  local _append_delimiter
  case "${1}" in
    (-d|--delimiter)
      _append_delimiter="${2}"
      shift 2
    ;;
  esac
  printf -- '%s\n' "${1}${_append_delimiter:- }${2}"
}

# @description Alias for str_append.
append() {
  str_append "${@}"
}

# @description Prepend one string to another and print the result.
#   Optionally define a delimiter with -d|--delimiter (defaults to a single space).
#
# @arg $1 string Optional: -d|--delimiter followed by delimiter string
# @arg $2 string The string to prepend
# @arg $3 string The string to prepend to
#
# @example
#   str_prepend -d ':' bar foo   # => bar:foo
#   str_prepend bar foo          # => bar foo
#
# @stdout Concatenated string
# @exitcode 0 Always
str_prepend() {
  local _prepend_delimiter
  case "${1}" in
    (-d|--delimiter)
      _prepend_delimiter="${2}"
      shift 2
    ;;
  esac
  printf -- '%s\n' "${1}${_prepend_delimiter:- }${2}"
}

# @description Prepend a string to each line of stdin.
#   Optionally define a delimiter with -d|--delimiter (defaults to a single space).
#
# @arg $1 string Optional: -d|--delimiter followed by delimiter string
# @arg $2 string The string to prepend to each line
#
# @stdout Each stdin line prefixed with the given string and delimiter
# @exitcode 0 Always
prepend() {
  local _prepend_delimiter
  case "${1}" in
    (-d|--delimiter)
      _prepend_delimiter="${2}"
      shift 2
    ;;
  esac
  while read -r; do
    printf -- '%s\n' "${1}${_prepend_delimiter:- }${REPLY}"
  done
}
