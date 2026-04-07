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
# Adapted from elibs/ebash (Apache-2.0) https://github.com/elibs/ebash
# Original author: Marshall McMullen <marshall.mcmullen@gmail.com>

[ -n "${_SHELLAC_LOADED_text_case_convert+x}" ] && return 0
_SHELLAC_LOADED_text_case_convert=1

# @description Convert a string to snake_case. Handles space-separated words,
#   hyphen-separated words, and camelCase input.
#
# @arg $@ string The string to convert
#
# @example
#   str_snake_case "Hello World"   # => hello_world
#   str_snake_case "fooBar"        # => foo_bar
#   str_snake_case "kebab-case"    # => kebab_case
#
# @stdout snake_case string
# @exitcode 0 Always
str_snake_case() {
  local _input
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  printf -- '%s\n' "${_input}" |
    sed 's/\([A-Z]\)/_\1/g' |
    tr '[:upper:] -' '[:lower:]__' |
    sed 's/_\+/_/g; s/^_//; s/_$//'
}

# @description Convert a string to camelCase. Handles space-separated,
#   underscore-separated, and hyphen-separated words. Input that is already
#   camelCase will be normalised to all-lowercase then re-cased.
#   Requires bash 4+.
#
# @arg $@ string The string to convert
#
# @example
#   str_camel_case "hello world"   # => helloWorld
#   str_camel_case "foo_bar_baz"   # => fooBarBaz
#   str_camel_case "kebab-case"    # => kebabCase
#
# @stdout camelCase string
# @exitcode 0 Always
str_camel_case() {
  requires BASH4
  local _input _result _word _first
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  _input="${_input//[_-]/ }"
  _result=""
  _first=1
  for _word in ${_input}; do
    if (( _first )); then
      _result+="${_word,,}"
      _first=0
    else
      _result+="${_word^}"
    fi
  done
  printf -- '%s\n' "${_result}"
}

# @description Convert a string to kebab-case. Handles space-separated words,
#   underscore-separated words, and camelCase input.
#
# @arg $@ string The string to convert
#
# @example
#   str_kebab_case "Hello World"   # => hello-world
#   str_kebab_case "fooBar"        # => foo-bar
#   str_kebab_case "snake_case"    # => snake-case
#
# @stdout kebab-case string
# @exitcode 0 Always
str_kebab_case() {
  local _input
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  printf -- '%s\n' "${_input}" |
    sed 's/\([A-Z]\)/-\1/g' |
    tr '[:upper:] _' '[:lower:]--' |
    sed 's/-\+/-/g; s/^-//; s/-$//'
}

# @description Convert a string to a URL-safe slug: lowercase alphanumeric
#   characters only, with runs of non-alphanumeric characters replaced by
#   a single hyphen.
#
# @arg $@ string The string to convert
#
# @example
#   str_slug "Hello, World!"       # => hello-world
#   str_slug "My Blog Post Title"  # => my-blog-post-title
#   str_slug "  extra  spaces  "   # => extra-spaces
#
# @stdout URL slug string
# @exitcode 0 Always
str_slug() {
  local _input
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  printf -- '%s\n' "${_input}" |
    tr '[:upper:]' '[:lower:]' |
    sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//'
}

# @internal
_str_altcaps_lowercase() {
  # shellcheck disable=SC2059
  case "${1}" in
    ([[:upper:]])
      printf \\"$(printf '%o' "$(( $(printf '%d' "'${1}") + 32 ))")"
    ;;
    (*)
      printf '%s' "${1}"
    ;;
  esac
}

# @internal
_str_altcaps_uppercase() {
  # shellcheck disable=SC2059
  case "${1}" in
    ([[:lower:]])
      printf \\"$(printf '%o' "$(( $(printf '%d' "'${1}") - 32 ))")"
    ;;
    (*)
      printf '%s' "${1}"
    ;;
  esac
}

# @description Convert text to alternating caps (mocking spongebob style).
#
# @arg $@ string One or more words to convert
#
# @stdout Text with alternating uppercase/lowercase characters
# @exitcode 0 Always
str_altcaps() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    local _altcaps_input
    IFS= read -r _altcaps_input
    # shellcheck disable=SC2086
    set -- ${_altcaps_input}
  fi
  local _lastswitch
  local _count
  local _word
  local _char
  _lastswitch=lower
  _count=0
  for _word in "${@}"; do
    for _char in $(printf -- '%s\n' "${_word}" | fold -w 1); do
      case "${_lastswitch}" in
        (lower)
          _str_altcaps_uppercase "${_char}"
          _lastswitch=upper
        ;;
        (upper)
          _str_altcaps_lowercase "${_char}"
          _lastswitch=lower
        ;;
      esac
    done
    _count=$(( _count + 1 ))
    (( _count != "${#}" )) && printf -- '%s' " "
  done
  printf -- '%s\n' ""
}

# @description Uppercase the first character of a string. Requires bash 4+.
#
# @arg $@ string The string to convert
#
# @example
#   str_ucfirst "hello world"   # => Hello world
#
# @stdout String with first character uppercased
# @exitcode 0 Always
str_ucfirst() {
  requires BASH4
  local _input
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  printf -- '%s\n' "${_input^}"
}

# @description Lowercase the first character of a string. Requires bash 4+.
#
# @arg $@ string The string to convert
#
# @example
#   str_lcfirst "Hello World"   # => hello World
#
# @stdout String with first character lowercased
# @exitcode 0 Always
str_lcfirst() {
  requires BASH4
  local _input
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  printf -- '%s\n' "${_input,}"
}

# @description Uppercase the first character of each word. Requires bash 4+.
#
# @arg $@ string The string to convert
#
# @example
#   str_ucwords "hello world"   # => Hello World
#
# @stdout String with first character of each word uppercased
# @exitcode 0 Always
str_ucwords() {
  requires BASH4
  local _input
  local _word
  local _result
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${*}"
  fi
  _result=''
  for _word in ${_input}; do
    _result="${_result}${_result:+ }${_word^}"
  done
  printf -- '%s\n' "${_result}"
}

# @description Convert a lower_snake_case string to Title Case.
#   Splits on underscores and capitalises each word.
#   Requires bash 4+ for the ${^} case modifier.
#
# @arg $1 string Input string in snake_case or similar
#
# @example
#   str_title_case "slice_drive_size"   # => "Slice Drive Size"
#   str_title_case "foo_bar"            # => "Foo Bar"
#
# @stdout Title-cased string
# @exitcode 0 Always
str_title_case() {
  requires BASH4
  local _input
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _input
  else
    _input="${1:-}"
  fi
  [[ -z "${_input}" ]] && return 0
  printf -- '%s\n' "${_input^}" | sed 's/_\([a-z]\)/ \u\1/g'
}
