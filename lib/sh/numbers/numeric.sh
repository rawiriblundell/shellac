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
# Adapted from labbots/bash-utility (MIT) https://github.com/labbots/bash-utility
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_numbers_numeric+x}" ] && return 0
_SHELLAC_LOADED_numbers_numeric=1

# @description Parse a string into a base-10 integer.
#   Auto-detects numeric representation from prefix or format, or accepts an explicit source base.
#   Handles: decimal, hex (0x/0X), binary (0b/0B), octal (0o/0O), scientific notation, floats (truncated).
#
# @arg $1 string The value to parse
# @arg $2 int    Optional: source base for the input string (default: auto-detect)
#
# @example
#   num_parse "0xFF"    # => 255
#   num_parse "FF" 16   # => 255
#   num_parse "1.5e3"   # => 1500
#   num_parse "3.7"     # => 3
#
# @stdout Base-10 integer
# @exitcode 0 Always
# @exitcode 1 No input given
num_parse() {
    local _input _base _stripped
    if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
        IFS= read -r _input
    else
        _input="${1:?No value given}"
    fi
    _base="${2:-}"

    # Explicit base: use bash's base#value arithmetic syntax
    if [[ -n "${_base}" ]]; then
        printf -- '%d\n' "$(( ${_base}#${_input} ))"
        return
    fi

    # Auto-detect representation from prefix or format
    case "${_input}" in
        # Scientific notation: 1.5e3, 2E10, -1.0e-3 etc.
        (*[eE]*)
            awk -v v="${_input}" 'BEGIN { printf "%d\n", v }'
        ;;
        # Hex prefix 0x or 0X
        (0[xX]*)
            _stripped="${_input#0[xX]}"
            printf -- '%d\n' "$(( 16#${_stripped} ))"
        ;;
        # Binary prefix 0b or 0B
        (0[bB]*)
            _stripped="${_input#0[bB]}"
            printf -- '%d\n' "$(( 2#${_stripped} ))"
        ;;
        # Octal prefix 0o or 0O
        (0[oO]*)
            _stripped="${_input#0[oO]}"
            printf -- '%d\n' "$(( 8#${_stripped} ))"
        ;;
        # Float: truncate (do not round) the fractional part
        (*.*)
            printf -- '%s\n' "${_input}" | awk -F '.' '{print $1}'
        ;;
        # Plain integer (possibly signed)
        (*)
            printf -- '%d\n' "${_input}"
        ;;
    esac
}

# @description Convenience alias for num_parse(). Parses a string to a base-10 integer.
#   Equivalent to Go's strconv.Atoi.
#
# @arg $@ Forwarded to num_parse
#
# @stdout Base-10 integer
# @exitcode 0 Always
# @exitcode 1 No input given
int() {
    num_parse "${@}"
}

# @description Format an integer in the given base.
#   Supports bases 2-36. Bases 8, 10, and 16 use printf directly; others use a digit-string loop.
#
# @arg $1 int The integer to format
# @arg $2 int Target base (default: 10)
#
# @example
#   num_format 255 16   # => ff
#   num_format 255 2    # => 11111111
#   num_format 255 8    # => 377
#
# @stdout Integer represented in the target base
# @exitcode 0 Always
# @exitcode 1 No input given
num_format() {
    local _n _base _digits _result _rem _neg
    if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
        IFS= read -r _n
    else
        _n="${1:?No integer given}"
    fi
    _base="${2:-10}"
    _neg=""

    case "${_base}" in
        (10) printf -- '%d\n' "${_n}" ;;
        (16) printf -- '%x\n' "${_n}" ;;
        (8)  printf -- '%o\n' "${_n}" ;;
        (*)
            _digits="0123456789abcdefghijklmnopqrstuvwxyz"
            _result=""
            if (( _n < 0 )); then
                _n=$(( _n * -1 ))
                _neg="-"
            fi
            if (( _n == 0 )); then
                printf -- '0\n'
                return
            fi
            while (( _n > 0 )); do
                _rem=$(( _n % _base ))
                _result="${_digits:${_rem}:1}${_result}"
                _n=$(( _n / _base ))
            done
            printf -- '%s\n' "${_neg}${_result}"
        ;;
    esac
}

# @description Format one or more numbers to two decimal places.
#
# @arg $@ number One or more numeric values
#
# @stdout Each value formatted to two decimal places, one per line
# @exitcode 0 Always
num_2dp() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    local _val
    IFS= read -r _val
    printf -- '%0.2f\n' "${_val}"
  else
    printf -- '%0.2f\n' "${@}"
  fi
}

# @description Format an integer with thousands separators (commas).
#
# @arg $1 int Integer to format
#
# @example
#   num_thousands 1234567   # => 1,234,567
#   num_thousands -9876543  # => -9,876,543
#   num_thousands 999       # => 999
#
# @stdout Formatted integer string
# @exitcode 0 Success
# @exitcode 1 No argument supplied
num_thousands() {
  local _n _neg _result
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    IFS= read -r _n
  else
    _n="${1:?No number given}"
  fi
  _neg=""

  if [[ "${_n}" = -* ]]; then
    _neg="-"
    _n="${_n#-}"
  fi

  _result=""
  while (( ${#_n} > 3 )); do
    _result=",${_n: -3}${_result}"
    _n="${_n:0:$(( ${#_n} - 3 ))}"
  done

  printf -- '%s\n' "${_neg}${_n}${_result}"
}

# @description Right-pad an integer with zeros to reach a minimum length.
#   If the integer is already at or above the target length, it is printed unchanged.
#
# @arg $1 int The integer to pad
# @arg $2 int Optional: target minimum length (default: 3)
#
# @stdout Zero-right-padded integer
# @exitcode 0 Always
num_zeropad_right() {
    local _int _len
    if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
        IFS= read -r _int
    else
        _int="${1:?No number provided}"
    fi
    _len="${2:-3}"

    if (( "${#_int}" >= _len )); then
        printf -- '%d\n' "${_int}"
        return 0
    fi

    printf -- '%d%0*d\n' "${_int}" "$(( _len - "${#_int}" ))" 0
}

# @description Test whether a value can be interpreted as an integer.
#
#   Two modes, selected by optional first argument:
#
#   Default (printf probe): passes if printf %d can parse the value.
#     Accepts signed integers; rejects leading quote characters that
#     printf %d would otherwise treat as an ASCII codepoint.
#
#   --regex (strict pattern): passes only if the value matches ^[+-]?[0-9]+$.
#     No format coercions; rejects hex, octal, scientific notation.
#     Use this when you need to validate raw user input.
#
# @arg [--regex] flag  Use strict regex matching instead of printf
# @arg $1 string       Value to test
#
# @example
#   num_is_integer "42"        # => 0 (true)
#   num_is_integer -- "-5"     # => 0 (true)
#   num_is_integer "1e5"       # => 1 (false; printf %d rejects it)
#   num_is_integer --regex "42"   # => 0 (true)
#   num_is_integer --regex "-5"   # => 0 (true)
#   num_is_integer --regex "1e5"  # => 1 (false)
#
# @exitcode 0 Value is an integer
# @exitcode 1 Value is not an integer
num_is_integer() {
    local _regex _value
    _regex=0
    case "${1:-}" in
        (--regex) _regex=1; shift ;;
    esac
    _value="${1:-}"
    if (( _regex )); then
        [[ "${_value}" =~ ^[+-]?[0-9]+$ ]]
    else
        case "${_value}" in
            ("'"*|'"'*) return 1 ;;
        esac
        printf -- '%d' "${_value:-null}" >/dev/null 2>&1
    fi
}

# @description Test whether a value can be interpreted as a float.
#
#   Two modes, selected by optional first argument:
#
#   Default (printf probe): passes if printf %f can parse the value.
#     Accepts scientific notation (1e5), plain integers, decimals with
#     leading or trailing dot (.5, 5.).
#
#   --regex (strict pattern): passes only if the value matches
#     ^[+-]?[0-9]+\.?[0-9]*$. Rejects scientific notation and leading-dot
#     decimals. Use this when you need to validate a specific decimal format.
#
# @arg [--regex] flag  Use strict regex matching instead of printf
# @arg $1 string       Value to test
#
# @example
#   num_is_float "1.5"           # => 0 (true)
#   num_is_float "1e5"           # => 0 (true; printf %f accepts it)
#   num_is_float ".5"            # => 0 (true; printf %f accepts it)
#   num_is_float --regex "1.5"   # => 0 (true)
#   num_is_float --regex "1e5"   # => 1 (false; regex rejects scientific notation)
#   num_is_float --regex ".5"    # => 1 (false; regex requires leading digit)
#
# @exitcode 0 Value is a float
# @exitcode 1 Value is not a float
num_is_float() {
    local _regex _value
    _regex=0
    case "${1:-}" in
        (--regex) _regex=1; shift ;;
    esac
    _value="${1:-}"
    if (( _regex )); then
        [[ "${_value}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
    else
        printf -- '%f' "${_value:-null}" >/dev/null 2>&1
    fi
}

# @description Test whether a value is a non-negative integer (digits only, no sign).
#   Uses strict regex: ^[0-9]+$. Does not accept leading +/-.
#   Equivalent to Python's str.isdigit() for integer strings.
#   Returns exit 2 if called with no argument.
#
# @arg $1 string Value to test
#
# @example
#   num_is_numeric "42"    # => 0 (true)
#   num_is_numeric "0"     # => 0 (true)
#   num_is_numeric "-1"    # => 1 (false; sign not allowed)
#   num_is_numeric "1.5"   # => 1 (false)
#
# @exitcode 0 Value is a non-negative integer
# @exitcode 1 Value is not
# @exitcode 2 Missing argument
num_is_numeric() {
    (( ${#} == 0 )) && { printf -- '%s\n' "num_is_numeric: missing argument" >&2; return 2; }
    printf -- '%d' "${1:-null}" >/dev/null 2>&1 && (( ${1} >= 0 ))
}

# @description Test whether a value is a positive integer (1 or greater, no sign).
#   Uses strict regex: ^[1-9][0-9]*$. Useful for validating array indices, counts.
#   Returns exit 2 if called with no argument.
#
# @arg $1 string Value to test
#
# @example
#   num_is_positive_integer "1"    # => 0 (true)
#   num_is_positive_integer "0"    # => 1 (false; zero is not positive)
#   num_is_positive_integer "-1"   # => 1 (false)
#   num_is_positive_integer "01"   # => 1 (false; leading zero not allowed)
#
# @exitcode 0 Value is a positive integer
# @exitcode 1 Value is not
# @exitcode 2 Missing argument
num_is_positive_integer() {
    (( ${#} == 0 )) && { printf -- '%s\n' "num_is_positive_integer: missing argument" >&2; return 2; }
    printf -- '%d' "${1:-null}" >/dev/null 2>&1 || return 1
    (( ${1} > 0 )) || return 1
    case "${1}" in
      (0*) return 1 ;;
    esac
}

# @description Test whether an integer is odd.
#
# @arg $1 int Integer to test
#
# @exitcode 0 Number is odd
# @exitcode 1 Number is even
num_is_odd() {
    (( (${1:?No number specified} % 2) != 0 ))
}

# @description Test whether an integer is even.
#
# @arg $1 int Integer to test
#
# @exitcode 0 Number is even
# @exitcode 1 Number is odd
num_is_even() {
    (( (${1:?No number specified} % 2) == 0 ))
}

# Backward-compatible aliases preserving the original is_numeric.sh API.
# Each routes to the corresponding num_* function in --regex mode to maintain
# the original strict pattern-matching behaviour.
is_integer()          { num_is_integer --regex "${@}"; }
is_float()            { num_is_float --regex "${@}"; }
is_numeric()          { num_is_numeric "${@}"; }
is_positive_integer() { num_is_positive_integer "${@}"; }
