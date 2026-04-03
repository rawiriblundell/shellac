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

[ -n "${_SHELLAC_LOADED_core_is+x}" ] && return 0
_SHELLAC_LOADED_core_is=1

########## Bools
# @description Test whether a value represents a boolean false.
#   Accepts: 1, false, no, off (case-insensitive).
#
# @arg $1 string Value to test
#
# @exitcode 0 Value is a recognised false
# @exitcode 1 Value is not a recognised false
bool_is_false() {
    case "${1:-null}" in
        (1|[fF][aA][lL][sS][eE]|[nN][oO]|[oO][fF][fF]) return 0 ;;
        (''|*)                                            return 1 ;;
    esac
}

# @description Test whether a value represents a boolean true.
#   Accepts: 0, y, true, yes, on (case-insensitive).
#
# @arg $1 string Value to test
#
# @exitcode 0 Value is a recognised true
# @exitcode 1 Value is not a recognised true
bool_is_true() {
    case "${1:-null}" in
        (0|[yY]|[tT][rR][uU][eE]|[yY][eE][sS]|[oO][nN]) return 0 ;;
        (''|*)                                              return 1 ;;
    esac
}

# @description Evaluate a value or stdin as a boolean.
#   When stdin is a pipe, reads one line and evaluates it.
#   Otherwise evaluates $1. Thin wrapper around bool_is_true().
#
# @arg $1 string Value to evaluate (ignored when stdin is a pipe)
#
# @exitcode 0 Value is truthy
# @exitcode 1 Value is falsy or empty
bool() {
    local _val
    if [[ ! -t 0 ]]; then
        read -r _val
    else
        _val="${1:?No input provided}"
    fi
    bool_is_true "${_val}"
}

# @description Test whether a value is any recognised boolean representation.
#   Accepts: 0, 1, true, false, yes, no, on, off (case-insensitive).
#
# @arg $1 string Value to test
#
# @exitcode 0 Value is a valid boolean
# @exitcode 1 Value is not a valid boolean
bool_is_valid() {
    case "${1:-null}" in
        (0|1|[tT][rR][uU][eE]|[fF][aA][lL][sS][eE]|[yY][eE][sS]|[nN][oO]|[oO][nN]|[oO][fF][fF]) return 0 ;;
        (''|*) return 1 ;;
    esac
}

########## Vars
# @description Test whether a variable is set and non-empty.
#
# @arg $1 string Value to test
#
# @exitcode 0 Value is set and non-empty
# @exitcode 1 Value is unset or empty
var_is_set() {
    [ "${1+x}" = "x" ] && [ "${#1}" -gt "0" ]
}

# @description Test whether a variable is unset.
#
# @arg $1 string Value to test
#
# @exitcode 0 Value is unset
# @exitcode 1 Value is set (even if empty)
var_is_unset() {
    [ -z "${1+x}" ]
}

# @description Test whether a variable is set but empty.
#
# @arg $1 string Value to test
#
# @exitcode 0 Value is set and empty
# @exitcode 1 Value is unset or non-empty
var_is_empty() {
    [ "${1+x}" = "x" ] && [ "${#1}" -eq "0" ]
}

# @description Test whether a variable is unset or empty.
#
# @arg $1 string Value to test
#
# @exitcode 0 Value is unset or empty
# @exitcode 1 Value is set and non-empty
var_is_blank() {
    var_is_unset "${1}" || var_is_empty "${1}"
}

# @description Test whether a variable is exported (global).
#
# @arg $1 string Variable name
#
# @exitcode 0 Variable is exported
# @exitcode 1 Variable is not exported
var_is_global() {
    export -p | grep "declare -x ${1}=" >/dev/null 2>&1
}

# @description Test whether a variable is a local (non-exported) variable.
#
# @arg $1 string Variable name
#
# @exitcode 0 Variable is local
# @exitcode 1 Variable is not local
var_is_local() {
    declare -p "${1}" 2>/dev/null | grep -- "-- ${1}=" >/dev/null 2>&1
}

########## Shell / script introspection
# @description Test whether a name refers to an indexed array variable.
#
# @arg $1 string Variable name
#
# @exitcode 0 Variable is an indexed array
# @exitcode 1 Variable is not an indexed array
is_array() {
    declare -p "${1:-$RANDOM}" 2>/dev/null | grep -- "-a ${1:-$RANDOM}=" >/dev/null 2>&1
}

# @description Test whether a name resolves to a command in PATH or as a builtin/function.
#
# @arg $1 string Command name
#
# @exitcode 0 Command exists
# @exitcode 1 Command does not exist
is_command() {
    command -v "${1:-$RANDOM}" >/dev/null 2>&1
}

# @description Test whether a name is a defined shell function.
#
# @arg $1 string Name to test
#
# @exitcode 0 Name is a function
# @exitcode 1 Name is not a function
is_function() {
    typeset -f "${1:-grobblegobble}" >/dev/null 2>&1
}

# @description Test whether the shell is running interactively.
#
# @exitcode 0 Shell is interactive
# @exitcode 1 Shell is not interactive
is_interactive() {
    case "$-" in
        (*i*) return 0 ;;
        (*)   return 1 ;;
    esac
}

# @description Test whether the current process is running as root (EUID 0).
#
# @exitcode 0 Running as root
# @exitcode 1 Not running as root
is_root() {
    (( ${EUID:-$(id -u)} == 0 ))
}

# @description Test whether the current script is being sourced rather than executed.
#   Bash-only; behaviour on other shells is undefined.
#
# @exitcode 0 Script is sourced
# @exitcode 1 Script is being executed directly
is_sourced() {
    [ "${BASH_SOURCE[0]}" != "${0}" ]
}

########## Value tests
# @description Test whether a value is one of an allowed set of values.
#
# @arg $1 string The value to check
# @arg $@ string Allowed values (all arguments after $1)
#
# @example
#   var_is_one_of "${ENV}" dev staging prod
#
# @exitcode 0 Value is in the set; 1 Value is not in the set
var_is_one_of() {
    local _value _candidate
    _value="${1:?}"
    shift
    for _candidate in "${@}"; do
        [[ "${_value}" == "${_candidate}" ]] && return 0
    done
    return 1
}

# @description Test whether exactly one of the given values is non-empty.
#   Useful for validating mutually exclusive options.
#
# @arg $@ string Values to test (at least two required)
#
# @example
#   var_exactly_one_set "${opt_a}" "${opt_b}" "${opt_c}"
#
# @exitcode 0 Exactly one non-empty; 1 Zero or more than one non-empty
var_exactly_one_set() {
    local _count _value
    _count=0
    for _value in "${@}"; do
        [[ -n "${_value}" ]] && (( _count += 1 ))
    done
    (( _count == 1 ))
}
