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

[ -n "${_SHELLAC_LOADED_numbers_primes+x}" ] && return 0
_SHELLAC_LOADED_numbers_primes=1

# @description Test whether an integer is prime using the 6k±1 algorithm.
#   Numbers less than 2 are not prime. 2 and 3 are prime.
#   All other primes satisfy n mod 6 == 1 or 5.
#   Accepts optional -v/--verbose flag to print a human-readable verdict.
#
# @arg $1 string Optional: -v or --verbose to print a verdict message
# @arg $1 int The integer to test (or $2 when -v is given)
#
# @stdout When --verbose: "N is [not] a prime"
# @exitcode 0 Number is prime
# @exitcode 1 Number is not prime
is_prime() {
    local _prime_verbose _prime_test _i
    # Check whether we're in verbose mode or not
    case "${1}" in
        (-v|--verbose)
            _prime_verbose="true"
            shift 1
        ;;
    esac
    # Ensure that _prime_verbose is set - default to 'false'
    _prime_verbose="${_prime_verbose:-false}"

    # Ensure that what's to be tested is actually a number
    _prime_test="${1:?No input number specified}"
    if ! printf -- '%d' "${_prime_test}" >/dev/null 2>&1; then
        if [[ "${_prime_verbose}" = "true" ]]; then
            printf -- '%s\n' "'${_prime_test}' does not appear to be a number" >&2
        fi
        return 1
    fi

    # Less than 2?  Not a prime.
    # Also prevents divide-by-0 opening up a rift in space/time.
    if (( _prime_test < 2 )); then
        if [[ "${_prime_verbose}" = "true" ]]; then
            printf -- '%s\n' "'${_prime_test}' is not a prime"
        fi
        return 1
    fi

    # 2 or 3?  Prime.
    if (( _prime_test == 2 )) || (( _prime_test == 3 )); then
        if [[ "${_prime_verbose}" = "true" ]]; then
            printf -- '%s\n' "'${_prime_test}' is a prime"
        fi
        return 0
    fi

    case "$(( _prime_test % 6 ))" in
        (0|2|3|4)
            if [[ "${_prime_verbose}" = "true" ]]; then
                printf -- '%s\n' "'${_prime_test}' is not a prime"
            fi
            return 1
        ;;
        (*)
            # Candidate passes the 6k±1 filter; trial-divide by factors of
            # the form 6k±1 up to √n to confirm (catches 25, 35, 49, etc.)
            _i=5
            while (( _i * _i <= _prime_test )); do
                if (( _prime_test % _i == 0 )) || (( _prime_test % (_i + 2) == 0 )); then
                    if [[ "${_prime_verbose}" = "true" ]]; then
                        printf -- '%s\n' "'${_prime_test}' is not a prime"
                    fi
                    return 1
                fi
                _i=$(( _i + 6 ))
            done
            if [[ "${_prime_verbose}" = "true" ]]; then
                printf -- '%s\n' "'${_prime_test}' is a prime"
            fi
            return 0
        ;;
    esac
}
