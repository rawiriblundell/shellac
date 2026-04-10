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

[ -n "${_SHELLAC_LOADED_utils_logging+x}" ] && return 0
_SHELLAC_LOADED_utils_logging=1

# Log level filter.  Uses the RFC 5424 syslog convention: lower number = more
# severe.  Valid values: EMERG ALERT CRIT ERR ERROR WARNING WARN NOTICE INFO DEBUG
# (default: INFO).  ERROR is an alias for ERR; WARN is an alias for WARNING.
: "${LOG_LEVEL:=INFO}"

# @internal
# Map a log level name to its RFC 5424 numeric severity.
# EMERG=0 ALERT=1 CRIT=2 ERR=3 WARNING=4 NOTICE=5 INFO=6 DEBUG=7
# Aliases: ERROR=ERR=3, WARN=WARNING=4.  Unknown values map to INFO (6).
_log_level_num() {
    case "${1}" in
        (EMERG)         printf -- '%s\n' '0' ;;
        (ALERT)         printf -- '%s\n' '1' ;;
        (CRIT)          printf -- '%s\n' '2' ;;
        (ERR|ERROR)     printf -- '%s\n' '3' ;;
        (WARN|WARNING)  printf -- '%s\n' '4' ;;
        (NOTICE)        printf -- '%s\n' '5' ;;
        (INFO)          printf -- '%s\n' '6' ;;
        (DEBUG)         printf -- '%s\n' '7' ;;
        (*)             printf -- '%s\n' '6' ;;
    esac
}

# @description Log an emergency-level message via logmsg.
#   Only suppressed when LOG_LEVEL is EMERG itself — in practice never filtered.
#
# @arg $@ string Message text
# @exitcode 0 Always
log_emerg() {
    (( 0 > $(_log_level_num "${LOG_LEVEL}") )) && return 0
    logmsg -p emerg -t "${0##*/}" "EMERG: ${*}"
}

# @description Log an alert-level message via logmsg.
#   Suppressed when LOG_LEVEL is EMERG.
#
# @arg $@ string Message text
# @exitcode 0 Always
log_alert() {
    (( 1 > $(_log_level_num "${LOG_LEVEL}") )) && return 0
    logmsg -p alert -t "${0##*/}" "ALERT: ${*}"
}

# @description Log a critical-level message via logmsg.
#   Suppressed when LOG_LEVEL is ALERT or EMERG.
#
# @arg $@ string Message text
# @exitcode 0 Always
log_crit() {
    (( 2 > $(_log_level_num "${LOG_LEVEL}") )) && return 0
    logmsg -p crit -t "${0##*/}" "CRIT: ${*}"
}

# @description Log an error message via logmsg.
#   Suppressed when LOG_LEVEL is CRIT, ALERT, or EMERG.
#
# @arg $@ string Message text
# @exitcode 0 Always
log_error() {
    (( 3 > $(_log_level_num "${LOG_LEVEL}") )) && return 0
    logmsg -p err -t "${0##*/}" "ERROR: ${*}"
}

# @description Alias for log_error (RFC 5424 priority name).
log_err() { log_error "${@}"; }

# @description Log a warning message via logmsg.
#   Suppressed when LOG_LEVEL is ERR/ERROR, CRIT, ALERT, or EMERG.
#
# @arg $@ string Message text
# @exitcode 0 Always
log_warn() {
    (( 4 > $(_log_level_num "${LOG_LEVEL}") )) && return 0
    logmsg -p warning -t "${0##*/}" "WARN: ${*}"
}

# @description Alias for log_warn (RFC 5424 priority name).
log_warning() { log_warn "${@}"; }

# @description Log a notice message via logmsg.
#   Suppressed when LOG_LEVEL is WARNING/WARN, ERR/ERROR, CRIT, ALERT, or EMERG.
#
# @arg $@ string Message text
# @exitcode 0 Always
log_notice() {
    (( 5 > $(_log_level_num "${LOG_LEVEL}") )) && return 0
    logmsg -p notice -t "${0##*/}" "NOTICE: ${*}"
}

# @description Log an informational message via logmsg.
#   Suppressed when LOG_LEVEL is NOTICE or more severe.
#
# @arg $@ string Message text
# @exitcode 0 Always
log_info() {
    (( 6 > $(_log_level_num "${LOG_LEVEL}") )) && return 0
    logmsg -p info -t "${0##*/}" "INFO: ${*}"
}

# @description Log a debug message via logmsg. Suppressed unless LOG_LEVEL=DEBUG.
#
# @arg $@ string Message text
# @exitcode 0 Always
log_debug() {
    (( 7 > $(_log_level_num "${LOG_LEVEL}") )) && return 0
    logmsg -p debug -t "${0##*/}" "DEBUG: ${*}"
}

# @description Log a message to the system log using systemd-cat, logger, or a
#   fallback file.  Accepts an optional -p priority, -t tag, and -s flag to
#   also print to stdout.
#
#   When -p is given, the priority is forwarded to the underlying transport:
#   systemd-cat receives --priority=<level>; logger receives -p user.<level>.
#
# @option -p string  Syslog priority name (emerg alert crit err warning notice info debug)
# @option -s         Also print to stdout
# @option -t string  Syslog identifier / tag
# @arg $@ string     Message text
#
# @stdout Message line when -s is given
# @exitcode 0 Message logged successfully
# @exitcode 1 Invalid option
logmsg() {
    local _opt
    local _log_ident
    local _log_priority
    local _print_fmt
    local _std_out
    local _log_file
    local _dispatch_args
    local OPTIND
    _std_out=0

    while getopts ":p:t:s" _opt; do
        case "${_opt}" in
            (p)     _log_priority="${OPTARG}" ;;
            (s)     _std_out=1 ;;
            (t)     _log_ident="${OPTARG}" ;;
            (\?|:|*)
                printf -- '%s\n' "Usage: logmsg [-p priority] [-s] [-t tag] message" >&2
                return 1
            ;;
        esac
    done
    shift "$(( OPTIND - 1 ))"

    case "${_log_ident:-}" in
        ('')  _print_fmt="$(date '+%b %d %T') ${HOSTNAME%%.*}:" ;;
        (*)   _print_fmt="$(date '+%b %d %T') ${HOSTNAME%%.*} ${_log_ident}:" ;;
    esac

    if command -v systemd-cat >/dev/null 2>&1; then
        (( _std_out )) && printf -- '%s\n' "${_print_fmt} ${*}"
        _dispatch_args=()
        [[ -n "${_log_ident:-}" ]]    && _dispatch_args+=( -t "${_log_ident}" )
        [[ -n "${_log_priority:-}" ]] && _dispatch_args+=( --priority="${_log_priority}" )
        systemd-cat "${_dispatch_args[@]}" <<< "${*}"
        return "${?}"
    fi

    if command -v logger >/dev/null 2>&1; then
        (( _std_out )) && printf -- '%s\n' "${_print_fmt} ${*}"
        _dispatch_args=()
        [[ -n "${_log_ident:-}" ]]    && _dispatch_args+=( -t "${_log_ident}" )
        [[ -n "${_log_priority:-}" ]] && _dispatch_args+=( -p "user.${_log_priority}" )
        logger "${_dispatch_args[@]}" "${*}"
        return "${?}"
    fi

   # If neither systemd-cat or logger are present, we fall-back to this. 
    [[ -w /var/log/messages ]] && _log_file=/var/log/messages
    [[ -z "${_log_file}" && -w /var/log/syslog ]] && _log_file=/var/log/syslog
    : "${_log_file:=/var/log/logmsg}"
    if (( _std_out )); then
        printf -- '%s\n' "${_print_fmt} ${*}" | tee -a "${_log_file}"
    else
        printf -- '%s\n' "${_print_fmt} ${*}" >> "${_log_file}"
    fi
}
