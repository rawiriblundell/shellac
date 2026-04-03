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
# Adapted from gruntwork-io/bash-commons (Apache-2.0) https://github.com/gruntwork-io/bash-commons
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_core_assert+x}" ] && return 0
_SHELLAC_LOADED_core_assert=1

include core/is

# @description Assert that a value is not empty.  Prints an error and returns 1
#   if the value is empty or unset.
#
# @arg $1 string The value to check
# @arg $2 string Human-readable name for the error message
#
# @example
#   assert_not_empty "${MY_VAR}" "MY_VAR"
#
# @exitcode 0 Value is non-empty; 1 Value is empty
assert_not_empty() {
  local _value _name
  _value="${1:-}"
  _name="${2:-_value}"
  if var_is_blank "${_value}"; then
    printf -- '%s\n' "assert_not_empty: ${_name} must not be empty" >&2
    return 1
  fi
}

# @description Assert that a command exists in PATH.
#
# @arg $1 string Command name
#
# @example
#   assert_is_installed curl
#
# @exitcode 0 Command found; 1 Command missing
assert_is_installed() {
  local _cmd
  _cmd="${1:?assert_is_installed: missing command argument}"
  if ! is_command "${_cmd}"; then
    printf -- '%s\n' "assert_is_installed: required command not found: ${_cmd}" >&2
    return 1
  fi
}

# @description Assert that a value is one of an allowed list of values.
#
# @arg $1 string The value to check
# @arg $@ string Allowed values (all arguments after $1)
#
# @example
#   assert_value_in_list "${ENV}" dev staging prod
#
# @exitcode 0 Value is in list; 1 Value not in list
assert_value_in_list() {
  local _value
  _value="${1:?assert_value_in_list: missing _value}"
  shift
  if ! var_is_one_of "${_value}" "${@}"; then
    printf -- '%s\n' "assert_value_in_list: '${_value}' is not in allowed list: ${*}" >&2
    return 1
  fi
}

# @description Assert that exactly one of the given values is non-empty.
#   Useful for validating mutually exclusive options.
#
# @arg $@ string Values to test (at least two required)
#
# @example
#   assert_exactly_one_of "${opt_a}" "${opt_b}" "${opt_c}"
#
# @exitcode 0 Exactly one non-empty; 1 Zero or more than one non-empty
assert_exactly_one_of() {
  if ! var_exactly_one_set "${@}"; then
    local _count _value
    _count=0
    for _value in "${@}"; do
      [[ -n "${_value}" ]] && (( _count += 1 ))
    done
    printf -- '%s\n' "assert_exactly_one_of: expected exactly 1 non-empty _value; got ${_count}" >&2
    return 1
  fi
}
