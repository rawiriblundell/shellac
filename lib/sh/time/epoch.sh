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
# Adapted from kigster/bash-orb (MIT) https://github.com/kigster/bash-orb

[ -n "${_SHELLAC_LOADED_time_epoch+x}" ] && return 0
_SHELLAC_LOADED_time_epoch=1

# @description Return the current Unix epoch in seconds.
#   Selects the fastest available method at load time:
#   EPOCHSECONDS (bash 5+ / zsh), printf %T (bash 4.2+), date, perl,
#   or a portable pure-shell fallback.
#
# @stdout Current Unix epoch as an integer
# @exitcode 0 Always
#
# Prioritise builtin approaches over externals to improve performance
# We start by testing for the EPOCHSECONDS shell var (bash 5.0 and newer, zsh w/ datetime module)
if [ -n "${EPOCHSECONDS}" ]; then
    time_epoch() { printf -- '%d\n' "${EPOCHSECONDS}"; }

# Next, we try for 'printf' (bash 4.2 and newer, some ksh)
elif printf '%(%s)T\n' -1 | grep "^[0-9].*$" >/dev/null 2>&1; then
    time_epoch() { printf '%(%s)T\n' -1; }

# Next we try for 'date'
# Because some 'date' variants will return a literal '+%s', we perform a capability check
elif date -u +%s | grep "^[0-9].*$" >/dev/null 2>&1; then
    time_epoch() { date -u +%s; }

# Next we try for 'perl', fairly ubiquitous but fading away slowly...
elif command -v perl >/dev/null 2>&1; then
    time_epoch() { perl -e 'print($^T."\n");'; }
    # Alternative: time_epoch() { perl -e 'print time."\n";'; }

# There are internet based options like
# curl -s http://worldtimeapi.org/api/timezone/UTC/ | jq -r '.unixtime'
# But they are less guaranteed to be present long-term, and/or responding promptly

# So we failover to a portable-ish shell method
else

    # Calculate how many seconds since epoch
    # Portable version based on http://www.etalabs.net/sh_tricks.html
    # We strip leading 0's in order to prevent unwanted octal math
    # This seems terse, but the vars are the same as their 'date' formats
    time_epoch() {
        local _year _julian_day _hour _minute _second _year_offset _year_secs

        # set -- splits date output into positional params, avoiding heredoc indentation traps.
        # Unquoted intentionally: word splitting on spaces separates the five fields.
        # The 10# prefix below strips leading zeros to prevent octal interpretation.
        # shellcheck disable=SC2046
        set -- $(date -u '+%Y %j %H %M %S')
        _year="${1}"; _julian_day="${2}"; _hour="${3}"; _minute="${4}"; _second="${5}"

        # year_offset: years elapsed since 1600 (the algorithm's base year)
        _year_offset=$(( _year - 1600 ))
        # _year_secs: seconds from Unix epoch to the start of the current day
        _year_secs=$(( (_year_offset * 365 + _year_offset / 4 - _year_offset / 100 + _year_offset / 400 + $(( 10#${_julian_day} )) - 135140) * 86400 ))

        printf -- '%s\n' "$(( _year_secs + ($(( 10#${_hour} )) * 3600) + ($(( 10#${_minute} )) * 60) + $(( 10#${_second} )) ))"
    }
fi

# @description Return the current Unix epoch expressed in a larger time unit.
#
# @arg $1 string Unit: seconds, minutes, hours, or days
#
# @example
#   time_epoch_in days
#   time_epoch_in hours
#
# @stdout Integer epoch value in the requested unit
# @exitcode 0 Always
# @exitcode 1 Unrecognised unit
time_epoch_in() {
  case "${1:-}" in
    (seconds) time_epoch ;;
    (minutes) printf -- '%s\n' "$(( $(time_epoch) / 60 ))" ;;
    (hours)   printf -- '%s\n' "$(( $(time_epoch) / 3600 ))" ;;
    (days)    printf -- '%s\n' "$(( $(time_epoch) / 86400 ))" ;;
    (*)
      printf -- 'Usage: time_epoch_in [seconds|minutes|hours|days]\n' >&2
      return 1
    ;;
  esac
}

# To get the epoch date at particular times
#BSD $(date -j -f "%Y-%m-%dT%T" "$1" "+%s")
#Busybox $(date -d "${1//T/ }" +%s)


# @description Convert a Windows/LDAP 100-nanosecond interval timestamp to a Unix epoch.
#   The LDAP timestamp counts 100ns intervals since 1 January 1601.
#
# @arg $1 int LDAP timestamp (100-nanosecond intervals since 1601-01-01)
#
# @example
#   time_ldaptime_to_epoch 132000000000000000   # => Unix epoch integer
#
# @stdout Unix epoch as an integer
# @exitcode 0 Always
time_ldaptime_to_epoch() {
  local _ldap_timestamp _ldap_offset
  _ldap_timestamp="${1:?No ldap timestamp supplied}"
  _ldap_timestamp=$(( _ldap_timestamp / 10000000 ))
  # Calculated as '( (1970-1601) * 365 -3 + ((1970-1601)/4) ) * 86400'
  _ldap_offset=11644473600
  printf -- '%s\n' "$(( _ldap_timestamp - _ldap_offset ))"
}

# @description Convert an SSL-style date/time string to a Unix epoch using perl.
#   Intended for systems where date(1) does not support the -d flag.
#   Expected input format: "Nov 10 2034 21:19:01"
#
# @arg $1 string Month (e.g. Nov)
# @arg $2 int Day of month
# @arg $3 int Four-digit year
# @arg $4 string Time as HH:MM:SS
#
# @stdout Unix epoch integer
# @exitcode 0 Always
# @exitcode 1 perl not available
time_date_to_epoch() {
    local _sec _min _hours _day _month _year _timestamp
    if ! command -v perl >/dev/null 2>&1; then
        printf -- 'time_date_to_epoch: %s\n' "This function requires 'perl', which was not found in PATH" >&2
        return 1
    fi
    # Read our incoming date/time information into our variables
    _month="${1:?No date provided}"; _day="${2}"; _year="${3}"; _timestamp="${4}"
    printf -- '%s\n' "${_timestamp}" | while IFS=':' read -r _hours _min _sec; do
        # Convert the month to 0..11 range
        case "${_month}" in
            ([jJ]an*) _month=0 ;;
            ([fF]eb*) _month=1 ;;
            ([mM]ar*) _month=2 ;;
            ([aA]pr*) _month=3 ;;
            ([mM]ay)  _month=4 ;;
            ([jJ]un*) _month=5 ;;
            ([jJ]ul*) _month=6 ;;
            ([aA]ug*) _month=7 ;;
            ([sS]ep*) _month=8 ;;
            ([oO]ct*) _month=9 ;;
            ([nN]ov*) _month=10 ;;
            ([dD]ec*) _month=11 ;;
        esac

        # Pass our variables to the mighty 'perl'
        perl -e 'use Time::Local; print timegm(@ARGV[0,1,2,3,4], $ARGV[5]-1900)."\n";' \
            "${_sec}" "${_min}" "${_hours}" "${_day}" "${_month}" "${_year}"
    done
}

# @description Get the current Unix epoch in milliseconds.
#   Uses date %3N (milliseconds) when available; falls back to seconds * 1000
#   for systems where %N is unsupported (e.g. macOS date).
#
# @example
#   time_epoch_ms    # => 1710000000123
#
# @stdout Current epoch in milliseconds
# @exitcode 0 Always
time_epoch_ms() {
  local _ns
  _ns="$(date +%s%3N 2>/dev/null)"
  # If %3N is unsupported (macOS date), fall back to seconds * 1000
  if [[ "${_ns}" == *N* ]] || [[ -z "${_ns}" ]]; then
    printf -- '%d000\n' "$(date +%s)"
  else
    printf -- '%s\n' "${_ns}"
  fi
}

# @description Sleep until a given Unix epoch second (or epoch millisecond).
#   If the target time is in the past, returns immediately.
#   Pass --ms to treat the argument as milliseconds.
#
# @arg [--ms] flag  Treat $1 as epoch milliseconds rather than seconds
# @arg $1 int       Target epoch (seconds, or ms when --ms given)
#
# @example
#   time_sleep_until $(( $(date +%s) + 30 ))   # sleep ~30s from now
#   time_sleep_until --ms $(( $(time_epoch_ms) + 5000 ))
#
# @exitcode 0 Awoke at or after target; 1 Bad argument
time_sleep_until() {
  local _target _now _diff _use_ms
  _use_ms=0

  case "${1:-}" in
    (--ms) _use_ms=1; shift ;;
  esac

  _target="${1:?time_sleep_until: missing _target epoch argument}"

  if (( _use_ms )); then
    _now="$(time_epoch_ms)"
    _diff=$(( _target - _now ))
    (( _diff <= 0 )) && return 0
    sleep "$(printf -- '0.%03d\n' "$(( _diff % 1000 ))")" 2>/dev/null || true
    _diff=$(( _diff / 1000 ))
    (( _diff > 0 )) && sleep "${_diff}"
  else
    _now="$(date +%s)"
    _diff=$(( _target - _now ))
    (( _diff <= 0 )) && return 0
    sleep "${_diff}"
  fi
}
