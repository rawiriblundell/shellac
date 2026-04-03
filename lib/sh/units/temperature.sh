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

[ -n "${_SHELLAC_LOADED_units_temperature+x}" ] && return 0
_SHELLAC_LOADED_units_temperature=1

if ! command -v bc >/dev/null 2>&1; then
    printf -- 'temperature: %s\n' "This library requires 'bc', which was not found in PATH" >&2
    return 1
fi

# @internal
_temp_validate() {
    printf -- '%d' "${1:-null}" >/dev/null 2>&1 && return 0
    printf -- '%f' "${1:-null}" >/dev/null 2>&1 && return 0
    return 1
}

# @internal
# Resolve temperature input from $1 or stdin (if stdin is not a terminal).
_temp_input() {
    if [[ -n "${1:-}" ]]; then
        printf -- '%s' "${1}"
    elif [[ ! -t 0 ]]; then
        IFS= read -r _temp_stdin_val
        printf -- '%s' "${_temp_stdin_val}"
    fi
}

########## Celsius <-> Fahrenheit
# @description Convert Celsius to Fahrenheit. Formula: F = (C * 9/5) + 32
#
# @arg $1 number Temperature in Celsius
#
# @stdout Temperature in Fahrenheit to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
celsius_to_fahrenheit() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;(${_t} * 9 / 5) + 32" | bc
}

# @description Convert Fahrenheit to Celsius. Formula: C = (F - 32) * 5/9
#
# @arg $1 number Temperature in Fahrenheit
#
# @stdout Temperature in Celsius to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
fahrenheit_to_celsius() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;(${_t} - 32) * 5 / 9" | bc
}

########## Celsius <-> Kelvin
# @description Convert Celsius to Kelvin. Formula: K = C + 273.15
#
# @arg $1 number Temperature in Celsius
#
# @stdout Temperature in Kelvin to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
celsius_to_kelvin() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} + 273.15" | bc
}

# @description Convert Kelvin to Celsius. Formula: C = K - 273.15
#
# @arg $1 number Temperature in Kelvin
#
# @stdout Temperature in Celsius to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
kelvin_to_celsius() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} - 273.15" | bc
}

########## Fahrenheit <-> Kelvin (via Celsius)
# @description Convert Fahrenheit to Kelvin via Celsius.
#
# @arg $1 number Temperature in Fahrenheit
#
# @stdout Temperature in Kelvin to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
fahrenheit_to_kelvin() {
    local _t
    local _c
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    _c=$(printf -- '%s\n' "scale=10;(${_t} - 32) * 5 / 9" | bc)
    printf -- '%s\n' "scale=2;${_c} + 273.15" | bc
}

# @description Convert Kelvin to Fahrenheit via Celsius.
#
# @arg $1 number Temperature in Kelvin
#
# @stdout Temperature in Fahrenheit to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
kelvin_to_fahrenheit() {
    local _t
    local _c
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    _c=$(printf -- '%s\n' "scale=10;${_t} - 273.15" | bc)
    printf -- '%s\n' "scale=2;(${_c} * 9 / 5) + 32" | bc
}

########## Celsius <-> Rankine
# @description Convert Celsius to Rankine. Formula: R = (C + 273.15) * 9/5
#
# @arg $1 number Temperature in Celsius
#
# @stdout Temperature in Rankine to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
celsius_to_rankine() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;(${_t} + 273.15) * 9 / 5" | bc
}

# @description Convert Rankine to Celsius. Formula: C = R * 5/9 - 273.15
#
# @arg $1 number Temperature in Rankine
#
# @stdout Temperature in Celsius to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
rankine_to_celsius() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} * 5 / 9 - 273.15" | bc
}

########## Fahrenheit <-> Rankine (direct: no intermediate needed)
# @description Convert Fahrenheit to Rankine. Formula: R = F + 459.67
#
# @arg $1 number Temperature in Fahrenheit
#
# @stdout Temperature in Rankine to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
fahrenheit_to_rankine() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} + 459.67" | bc
}

# @description Convert Rankine to Fahrenheit. Formula: F = R - 459.67
#
# @arg $1 number Temperature in Rankine
#
# @stdout Temperature in Fahrenheit to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
rankine_to_fahrenheit() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} - 459.67" | bc
}

########## Kelvin <-> Rankine (direct: no intermediate needed)
# @description Convert Kelvin to Rankine. Formula: R = K * 9/5
#
# @arg $1 number Temperature in Kelvin
#
# @stdout Temperature in Rankine to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
kelvin_to_rankine() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} * 9 / 5" | bc
}

# @description Convert Rankine to Kelvin. Formula: K = R * 5/9
#
# @arg $1 number Temperature in Rankine
#
# @stdout Temperature in Kelvin to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
rankine_to_kelvin() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} * 5 / 9" | bc
}

########## Celsius <-> Newton
# @description Convert Celsius to Newton. Formula: N = C * 33/100
#
# @arg $1 number Temperature in Celsius
#
# @stdout Temperature in Newton to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
celsius_to_newton() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} * 33 / 100" | bc
}

# @description Convert Newton to Celsius. Formula: C = N * 100/33
#
# @arg $1 number Temperature in Newton
#
# @stdout Temperature in Celsius to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
newton_to_celsius() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} * 100 / 33" | bc
}

########## Celsius <-> Rømer
# @description Convert Celsius to Rømer. Formula: Ro = C * 21/40 + 7.5
#
# @arg $1 number Temperature in Celsius
#
# @stdout Temperature in Rømer to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
celsius_to_romer() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} * 21 / 40 + 7.5" | bc
}

# @description Convert Rømer to Celsius. Formula: C = (Ro - 7.5) * 40/21
#
# @arg $1 number Temperature in Rømer
#
# @stdout Temperature in Celsius to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
romer_to_celsius() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;(${_t} - 7.5) * 40 / 21" | bc
}

########## Celsius <-> Delisle
# @description Convert Celsius to Delisle. Formula: De = (100 - C) * 3/2
#   Note: Delisle is an inverted scale — water boils at 0°De, freezes at 150°De.
#
# @arg $1 number Temperature in Celsius
#
# @stdout Temperature in Delisle to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
celsius_to_delisle() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;(100 - ${_t}) * 3 / 2" | bc
}

# @description Convert Delisle to Celsius. Formula: C = 100 - De * 2/3
#
# @arg $1 number Temperature in Delisle
#
# @stdout Temperature in Celsius to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
delisle_to_celsius() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;100 - ${_t} * 2 / 3" | bc
}

########## Celsius <-> Réaumur
# @description Convert Celsius to Réaumur. Formula: Ré = C * 4/5
#
# @arg $1 number Temperature in Celsius
#
# @stdout Temperature in Réaumur to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
celsius_to_reaumur() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} * 4 / 5" | bc
}

# @description Convert Réaumur to Celsius. Formula: C = Ré * 5/4
#
# @arg $1 number Temperature in Réaumur
#
# @stdout Temperature in Celsius to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input
reaumur_to_celsius() {
    local _t
    _t="$(_temp_input "${1:-}")"
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    printf -- '%s\n' "scale=2;${_t} * 5 / 4" | bc
}

########## Dispatcher helpers (internal)

# @internal
_temp_to_celsius() {
    case "${2}" in
        ([Cc])       printf -- '%s\n' "${1}" ;;
        ([Ff])       fahrenheit_to_celsius "${1}" ;;
        ([Kk])       kelvin_to_celsius "${1}" ;;
        ([Rr])       rankine_to_celsius "${1}" ;;
        ([Nn])       newton_to_celsius "${1}" ;;
        ([Rr][Oo])   romer_to_celsius "${1}" ;;
        ([Dd][Ee])   delisle_to_celsius "${1}" ;;
        ([Rr][Ee])   reaumur_to_celsius "${1}" ;;
        (*) printf -- 'temperature: unknown unit: %s\n' "${2}" >&2; return 1 ;;
    esac
}

# @internal
_temp_from_celsius() {
    case "${2}" in
        ([Cc])       printf -- '%s\n' "${1}" ;;
        ([Ff])       celsius_to_fahrenheit "${1}" ;;
        ([Kk])       celsius_to_kelvin "${1}" ;;
        ([Rr])       celsius_to_rankine "${1}" ;;
        ([Nn])       celsius_to_newton "${1}" ;;
        ([Rr][Oo])   celsius_to_romer "${1}" ;;
        ([Dd][Ee])   celsius_to_delisle "${1}" ;;
        ([Rr][Ee])   celsius_to_reaumur "${1}" ;;
        (*) printf -- 'temperature: unknown unit: %s\n' "${2}" >&2; return 1 ;;
    esac
}

########## Public API

# @description Convert a temperature value between any two supported units.
#   Supported units: C, F, K, R (Rankine), N (Newton), Ro (Rømer), De (Delisle), Re (Réaumur).
#
# @arg $1 number Temperature value to convert
# @arg $2 string Source unit (case-insensitive)
# @arg $3 string Target unit (case-insensitive)
#
# @example
#   temp_convert 100 C F   # => 212.00
#
# @stdout Converted temperature to 2 decimal places, or "null" on invalid input
# @exitcode 0 Success
# @exitcode 1 Invalid input or unknown unit
temp_convert() {
    local _t
    local _from
    local _to
    local _celsius
    if (( ${#} == 2 )); then
        # value from stdin, units as $1 and $2
        _t="$(_temp_input "")"
        _from="${1}"
        _to="${2}"
    else
        _t="${1:-}"
        _from="${2}"
        _to="${3}"
    fi
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    _celsius=$(_temp_to_celsius "${_t}" "${_from}") || return 1
    _temp_from_celsius "${_celsius}" "${_to}"
}

# @description Display a temperature converted from a given unit to all supported units.
#
# @arg $1 number Temperature value to convert
# @arg $2 string Source unit (case-insensitive)
#
# @example
#   temp_convert_all 100 C
#
# @stdout Labelled conversion for each supported unit
# @exitcode 0 Success
# @exitcode 1 Invalid input or unknown unit
temp_convert_all() {
    local _t
    local _from
    local _celsius
    if (( ${#} == 1 )); then
        # value from stdin, unit as $1
        _t="$(_temp_input "")"
        _from="${1}"
    else
        _t="${1:-}"
        _from="${2}"
    fi
    _temp_validate "${_t}" || { printf -- '%s\n' "null"; return 1; }
    _celsius=$(_temp_to_celsius "${_t}" "${_from}") || return 1
    printf -- 'Celsius    = %s°C\n'  "${_celsius}"
    printf -- 'Fahrenheit = %s°F\n'  "$(celsius_to_fahrenheit "${_celsius}")"
    printf -- 'Kelvin     = %s°K\n'  "$(celsius_to_kelvin     "${_celsius}")"
    printf -- 'Rankine    = %s°R\n'  "$(celsius_to_rankine    "${_celsius}")"
    printf -- 'Newton     = %s°N\n'  "$(celsius_to_newton     "${_celsius}")"
    printf -- 'Rømer      = %s°Ro\n' "$(celsius_to_romer      "${_celsius}")"
    printf -- 'Delisle    = %s°De\n' "$(celsius_to_delisle    "${_celsius}")"
    printf -- 'Réaumur    = %s°Ré\n' "$(celsius_to_reaumur    "${_celsius}")"
}
