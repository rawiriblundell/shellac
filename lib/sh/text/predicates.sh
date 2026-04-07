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
# Adapted from adoyle-h/lobash (Apache-2.0) https://github.com/adoyle-h/lobash
# Adapted from hastec-fr/apash (Apache-2.0) https://github.com/hastec-fr/apash

[ -n "${_SHELLAC_LOADED_text_predicates+x}" ] && return 0
_SHELLAC_LOADED_text_predicates=1
requires BASH43

# @description Test if a string is empty (zero length).
#
# @arg $1 string The string to test
#
# @exitcode 0 String is empty
# @exitcode 1 String is not empty
str_is_empty() {
  local _str
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
  else
    _str="${1}"
  fi
  [[ -z "${_str}" ]]
}

# @description Test if a string is blank (empty or whitespace only).
#
# @arg $1 string The string to test
#
# @exitcode 0 String is blank
# @exitcode 1 String contains non-whitespace characters
str_is_blank() {
  local _str
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
  else
    _str="${1}"
  fi
  _str="${_str//[[:space:]]/}"
  [[ -z "${_str}" ]]
}

# @description Test if a string starts with a given prefix.
#
# @arg $1 string The string to test
# @arg $2 string The prefix to check for
#
# @exitcode 0 String starts with prefix
# @exitcode 1 String does not start with prefix
str_starts_with() {
  local _str _prefix
  if (( ${#} == 1 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
    _prefix="${1}"
  else
    _str="${1:?No string given}"
    _prefix="${2:?No prefix given}"
  fi
  [[ "${_str}" = "${_prefix}"* ]]
}

# @description Test if a string ends with a given suffix.
#
# @arg $1 string The string to test
# @arg $2 string The suffix to check for
#
# @exitcode 0 String ends with suffix
# @exitcode 1 String does not end with suffix
str_ends_with() {
  local _str _suffix
  if (( ${#} == 1 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
    _suffix="${1}"
  else
    _str="${1:?No string given}"
    _suffix="${2:?No suffix given}"
  fi
  [[ "${_str}" = *"${_suffix}" ]]
}

# @description Test if a string contains a given substring.
#
# @arg $1 string The string to test
# @arg $2 string The substring to check for
#
# @exitcode 0 String contains substring
# @exitcode 1 String does not contain substring
str_contains() {
  local _str _substr
  if (( ${#} == 1 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
    _substr="${1}"
  else
    _str="${1:?No string given}"
    _substr="${2:?No substring given}"
  fi
  [[ "${_str}" = *"${_substr}"* ]]
}

# @description Test if two strings are equal ignoring case.
#
# @arg $1 string First string
# @arg $2 string Second string
#
# @exitcode 0 Strings are equal (case-insensitive)
# @exitcode 1 Strings are not equal
str_equal_fold() {
  local _a _b
  _a="${1:?No first string given}"
  _b="${2:?No second string given}"
  if (( BASH_VERSINFO >= 4 )); then
    [[ "${_a,,}" = "${_b,,}" ]]
  else
    [[ "$(printf -- '%s' "${_a}" | tr '[:upper:]' '[:lower:]')" = "$(printf -- '%s' "${_b}" | tr '[:upper:]' '[:lower:]')" ]]
  fi
}

# @description Test whether a string matches a regex pattern (ERE).
#   On success BASH_REMATCH is populated by the shell.
#
# @arg $1 string String to test
# @arg $2 string Extended regex pattern
#
# @example
#   str_match "hello world" "^hello"                             # 0
#   str_match "2024-03-19" "([0-9]{4})-([0-9]{2})-([0-9]{2})"
#   printf '%s\n' "${BASH_REMATCH[1]}"                           # => 2024
#
# @exitcode 0 Match; 1 No match
str_match() {
  if (( ${#} == 1 )) && [[ ! -t 0 ]]; then
    local _str
    IFS= read -r _str
    [[ "${_str}" =~ ${1} ]]
  else
    [[ "${1:-}" =~ ${2:-} ]]
  fi
}

# @description Match a string against a regex and populate a named array with
#   the capture groups (BASH_REMATCH[0..n]).  Requires bash 4.3+ for namerefs.
#
# @arg $1 string String to test
# @arg $2 string Extended regex pattern
# @arg $3 string Name of the caller's array variable to populate
#
# @example
#   str_match_captures "2024-03-19" "([0-9]{4})-([0-9]{2})-([0-9]{2})" parts
#   printf '%s\n' "${parts[1]}"   # => 2024
#   printf '%s\n' "${parts[2]}"   # => 03
#   printf '%s\n' "${parts[3]}"   # => 19
#
# @exitcode 0 Match found and array populated; 1 No match; 2 Missing argument
str_match_captures() {
  local _str _pattern
  local -n _str_match_out="${3:?str_match_captures: missing array name argument}"
  _str="${1:-}"
  _pattern="${2:-}"
  _str_match_out=()
  [[ "${_str}" =~ ${_pattern} ]] || return 1
  _str_match_out=( "${BASH_REMATCH[@]}" )
}

# @description Return 0 if the string is composed only of characters in the given set.
#   An empty string always returns 0. A non-empty string against an empty set returns 1.
#   The character set is used as a bracket expression: e.g. "a-z0-9", "[:alpha:]".
#
# @arg $1 string The string to test
# @arg $2 string Allowed character set (bracket expression)
#
# @example
#   str_contains_only ""     "abc"      # 0 — empty string always passes
#   str_contains_only "abab" "abc"      # 0 — only a, b, c
#   str_contains_only "ab1"  "a-z"      # 1 — digit not in set
#
# @exitcode 0 String contains only characters from the set (or is empty)
# @exitcode 1 String contains characters outside the set, or non-empty with empty set
str_contains_only() {
  local _str _set
  _str="${1:-}"
  _set="${2:-}"
  [[ -z "${_str}" ]] && return 0
  [[ -n "${_str}" && -z "${_set}" ]] && return 1
  case "${_str}" in (*[!${_set}]*) return 1 ;; esac
}

# @description Return 0 if the string contains only ASCII alphabetic characters (non-empty).
# @arg $1 string String to test
# @exitcode 0 Non-empty and purely alphabetic; 1 otherwise
str_is_alpha() {
  local _str
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
  else
    _str="${1:-}"
  fi
  case "${_str}" in
    (''|*[![:alpha:]]*) return 1 ;;
  esac
}

# @description Return 0 if the string contains only ASCII alphanumeric characters (non-empty).
# @arg $1 string String to test
# @exitcode 0 Non-empty and purely alphanumeric; 1 otherwise
str_is_alnum() {
  local _str
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
  else
    _str="${1:-}"
  fi
  case "${_str}" in
    (''|*[![:alnum:]]*) return 1 ;;
  esac
}

# @description Return 0 if the string contains only ASCII digit characters (non-empty).
# @arg $1 string String to test
# @exitcode 0 Non-empty and purely decimal digits; 1 otherwise
str_is_digits() {
  local _str
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
  else
    _str="${1:-}"
  fi
  case "${_str}" in
    (''|*[![:digit:]]*) return 1 ;;
  esac
}

# @description Return 0 if the string is a valid integer (optional leading minus, digits only).
#   Differs from str_is_digits: allows a leading '-' sign.
#   An empty string or bare '-' returns 1.
#
# @arg $1 string String to test
#
# @example
#   str_is_int "42"    # => 0
#   str_is_int "-7"    # => 0
#   str_is_int "+7"    # => 1  (unary + not accepted)
#   str_is_int "3.14"  # => 1
#
# @exitcode 0 Non-empty valid integer; 1 otherwise
str_is_int() {
  local _str _digits
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
  else
    _str="${1:-}"
  fi
  # Strip optional leading minus; empty remainder or any non-digit → fail
  _digits="${_str#-}"
  case "${_digits}" in
    (''|*[![:digit:]]*) return 1 ;;
  esac
}

# @description Return 0 if the string is a valid hexadecimal value.
#   Case-insensitive. Accepts an optional 0x/0X prefix.
#   An empty string or bare '0x'/'0X' returns 1.
#
# @arg $1 string String to test
#
# @example
#   str_is_hex "DEADBEEF"   # => 0
#   str_is_hex "0xff"       # => 0
#   str_is_hex "0x"         # => 1  (no digits after prefix)
#   str_is_hex "0xGG"       # => 1
#
# @exitcode 0 Non-empty valid hex string; 1 otherwise
str_is_hex() {
  local _str _digits
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
  else
    _str="${1:-}"
  fi
  # Strip optional 0x/0X prefix; empty remainder or any non-hex char → fail
  _digits="${_str#0[xX]}"
  case "${_digits}" in
    (''|*[![:xdigit:]]*) return 1 ;;
  esac
}

# @description Return 0 if the string is valid base64-encoded content.
#   Accepts both standard ('+', '/') and URL-safe ('_', '-') alphabets.
#   Requires proper padding: length must be a multiple of 4; trailing '='
#   or '==' is allowed, but '=' may not appear elsewhere in the string.
#
# @arg $1 string String to test
#
# @example
#   str_is_base64 "YWJj"     # => 0  ("abc")
#   str_is_base64 "YQ=="     # => 0  ("a")
#   str_is_base64 "YQ"       # => 1  (not padded to multiple of 4)
#   str_is_base64 "YQ==="    # => 1  (over-padded)
#   str_is_base64 "!!"       # => 1
#
# @exitcode 0 Valid padded base64 string; 1 otherwise
str_is_base64() {
  local _str _len _body _pad
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
  else
    _str="${1:-}"
  fi
  [[ -z "${_str}" ]] && return 1
  _len="${#_str}"
  # Length must be a multiple of 4
  (( _len % 4 != 0 )) && return 1
  # Isolate body (everything before the first '=') and trailing padding
  _body="${_str%%=*}"
  _pad="${_str#"${_body}"}"
  # Padding may only be '', '=', or '=='
  case "${_pad}" in
    (''|'='|'==') ;;
    (*) return 1 ;;
  esac
  # Body must be non-empty and contain only base64 alphabet chars
  # (standard: A-Za-z0-9+/  or URL-safe: A-Za-z0-9_-)
  case "${_body}" in
    (''|*[!A-Za-z0-9+/_-]*) return 1 ;;
  esac
}

# @description Return 0 if every letter character in the string is uppercase.
#   Non-letter characters (digits, punctuation, etc.) are ignored.
#   An empty string or a string with no letters passes.
#
# @arg $1 string String to test
#
# @example
#   str_is_upper "HELLO"      # => 0
#   str_is_upper "HELLO123"   # => 0
#   str_is_upper "Hello"      # => 1
#   str_is_upper "123"        # => 0  (no letters to be wrong)
#
# @exitcode 0 All letters are uppercase (or no letters present); 1 otherwise
str_is_upper() {
  local _str _stripped
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
  else
    _str="${1:-}"
  fi
  # Remove all uppercase letters; any surviving lowercase letter → fail
  _stripped="${_str//[[:upper:]]/}"
  case "${_stripped}" in
    (*[[:lower:]]*) return 1 ;;
  esac
}

# @description Return 0 if every letter character in the string is lowercase.
#   Non-letter characters (digits, punctuation, etc.) are ignored.
#   An empty string or a string with no letters passes.
#
# @arg $1 string String to test
#
# @example
#   str_is_lower "hello"      # => 0
#   str_is_lower "hello123"   # => 0
#   str_is_lower "Hello"      # => 1
#   str_is_lower "123"        # => 0  (no letters to be wrong)
#
# @exitcode 0 All letters are lowercase (or no letters present); 1 otherwise
str_is_lower() {
  local _str _stripped
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _str
  else
    _str="${1:-}"
  fi
  # Remove all lowercase letters; any surviving uppercase letter → fail
  _stripped="${_str//[[:lower:]]/}"
  case "${_stripped}" in
    (*[[:upper:]]*) return 1 ;;
  esac
}

# @description Test if a string is a plausible email address.
#   Checks structural format only — no DNS or deliverability checks.
#
# @arg $1 string String to test
#
# @example
#   str_is_email "user@example.com"   # => exit 0
#   str_is_email "notanemail"          # => exit 1
#
# @exitcode 0 Valid email format
# @exitcode 1 Invalid format
# @exitcode 2 Missing argument
# Adapted from labbots/bash-utility (MIT) https://github.com/labbots/bash-utility
str_is_email() {
  local _email_re _str
  if (( ${#} == 0 )); then
    if [[ ! -t 0 ]]; then
      IFS= read -r _str
    else
      printf -- '%s\n' "str_is_email: missing argument" >&2
      return 2
    fi
  else
    _str="${1}"
  fi
  _email_re="^([A-Za-z]+[A-Za-z0-9]*\+?((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*)*)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$"
  [[ "${_str}" =~ ${_email_re} ]]
}
