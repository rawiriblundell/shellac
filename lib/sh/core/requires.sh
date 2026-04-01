#!/bin/false
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
# Provenance: https://github.com/rawiriblundell/sh_libpath
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_core_requires+x}" ] && return 0
_SHELLAC_LOADED_core_requires=1

# @internal
_requires_get_version() {
    local _cmd
    local _ver
    _cmd="${1}"

    _ver=$("${_cmd}" --version 2>&1 | grep -Eo '([0-9]+\.){1,2}[0-9]+' | head -1)
    [ -n "${_ver}" ] && { printf -- '%s\n' "${_ver}"; return 0; }

    _ver=$("${_cmd}" version 2>&1 | grep -Eo '([0-9]+\.){1,2}[0-9]+' | head -1)
    [ -n "${_ver}" ] && { printf -- '%s\n' "${_ver}"; return 0; }

    _ver=$("${_cmd}" -version 2>&1 | grep -Eo '([0-9]+\.){1,2}[0-9]+' | head -1)
    [ -n "${_ver}" ] && { printf -- '%s\n' "${_ver}"; return 0; }

    return 1
}

# @internal
_requires_version_cmp() {
    local _have _op _want _lesser
    _have="${1}"
    _op="${2}"
    _want="${3}"

    _lesser=$(printf -- '%s\n%s\n' "${_have}" "${_want}" | sort -V | head -1)

    case "${_op}" in
        ('==') [ "${_have}" =  "${_want}" ] ;;
        ('!=') [ "${_have}" != "${_want}" ] ;;
        ('>=') [ "${_lesser}" = "${_want}" ] ;;
        ('<=') [ "${_lesser}" = "${_have}" ] ;;
        ('>')  [ "${_lesser}" = "${_want}" ] && [ "${_have}" != "${_want}" ] ;;
        ('<')  [ "${_lesser}" = "${_have}" ] && [ "${_have}" != "${_want}" ] ;;
        (*)    return 1 ;;
    esac
}

# @internal
_requires_check_constraints() {
    local _cmd _constraints _remaining _constraint _op _ver _found_ver
    _cmd="${1}"
    _constraints="${2}"

    command -v "${_cmd}" >/dev/null 2>&1 || return 1

    _found_ver=$(_requires_get_version "${_cmd}")
    [ -z "${_found_ver}" ] && return 2

    _remaining="${_constraints}"
    while [ -n "${_remaining}" ]; do
        _constraint="${_remaining%%,*}"
        [ "${_constraint}" = "${_remaining}" ] && _remaining="" || _remaining="${_remaining#*,}"

        if [[ "${_constraint}" =~ ^([><!]?=|[><])([0-9][0-9.]*)$ ]]; then
            _op="${BASH_REMATCH[1]}"
            _ver="${BASH_REMATCH[2]}"
        else
            return 1
        fi

        _requires_version_cmp "${_found_ver}" "${_op}" "${_ver}" || return 1
    done

    return 0
}

# @description Assert that a list of commands, files, shell versions or
#   env variable values are all available. Fails with a summary of unmet items.
#   Supports version constraints and a requirements file via -r.
#
# @arg $1 string Optional: -r <file> to read requirements from a file
# @arg $@ string Requirements: commands, paths, version specs, or KEY=VALUE pairs
#
# @example
#   requires curl sed awk /etc/someconf.cfg
#   requires 'curl>=7.0' 'git>=2.30,<3.0'
#   requires -r requirements.txt
#
# @stderr List of unmet requirements
# @exitcode 0 All requirements met
# @exitcode 1 One or more requirements not met
requires() {
    local OPTIND
    local _opt
    local _req_file
    local _req_line
    local _item
    local _key
    local _val
    local _bashver
    local _target_lib
    local _found_lib
    local _failures
    local _req_cmd
    local _req_constraints
    local _req_status
    local _req_found_ver
    local -a _items

    while getopts ':r:' _opt; do
        case "${_opt}" in
            (r)
            _req_file="${OPTARG}"
            if [ ! -r "${_req_file}" ]; then
                printf -- 'requires: %s\n' "Cannot read requirements file: ${_req_file}" >&2
                return 1
            fi
            ;;
            (:)
            printf -- 'requires: %s\n' "Option -${OPTARG} requires an argument" >&2
            return 1
            ;;
            (?)
            printf -- 'requires: %s\n' "Unknown option: -${OPTARG}" >&2
            return 1
            ;;
        esac
    done
    shift $(( OPTIND - 1 ))

    _items=()

    if [ -n "${_req_file}" ]; then
        while IFS= read -r _req_line; do
            case "${_req_line}" in
                ('#'*|'') continue ;;
            esac
            _items+=( "${_req_line}" )
        done < "${_req_file}"
    fi

    _items+=( "${@}" )

    for _item in "${_items[@]}"; do
        case "${_item}" in
            # Version constraints must come before *=* to avoid misparse.
            # Operators >, < are unambiguous; == and != contain = so must be
            # listed explicitly to take priority over the variable-check branch.
            (*'>'*|*'<'*|*'!='*|*'=='*)
            if [[ "${_item}" =~ ^([A-Za-z0-9_./-]+)([><=!].*)$ ]]; then
                _req_cmd="${BASH_REMATCH[1]}"
                _req_constraints="${BASH_REMATCH[2]}"
                _requires_check_constraints "${_req_cmd}" "${_req_constraints}"
                _req_status="${?}"
                case "${_req_status}" in
                    (0) ;;
                    (2) _failures="${_failures} ${_item} (version undetermined)" ;;
                    (*)
                    _req_found_ver=$(_requires_get_version "${_req_cmd}" 2>/dev/null)
                    if [ -n "${_req_found_ver}" ]; then
                        _failures="${_failures} ${_item} (found ${_req_found_ver})"
                    else
                        _failures="${_failures} ${_item}"
                    fi
                    ;;
                esac
            else
                _failures="${_failures} ${_item}"
            fi
            continue
            ;;

            # Variable check: KEY=VALUE
            (*=*)
            _key="${_item%%=*}" # Everything left of the first '='
            _val="${_item#*=}"  # Everything right of the first '='
            # Note: eval used intentionally for portability (POSIX sh compatible).
            # In bash-only contexts ${!_key} indirect expansion would be cleaner.
            eval [ \$"${_key}" = "${_val}" ] && continue
            ;;

            (BASH*)
            # Shell version check e.g. 'requires BASH32' = we check for bash 3.2 or newer
            # To strictly require a specific version, you could use the keyval test above
            # TODO: Expand the "is greater than" logic, add extra shells
            if (( ${#BASH_VERSION} > 0 )); then
                # Get first three chars e.g. '4.3'
                _bashver="${BASH_VERSION%${BASH_VERSION#???}}"
                # Concat and remove dot e.g. 'BASH43'
                _bashver="BASH${_bashver/./}"
                # Test on string (e.g. BASH44 = BASH44)
                [ "${_item}" = "${_bashver}" ] && continue
                # Test on integer by stripping "BASH" (e.g. current 51 >= required 44)
                (( ${_bashver/BASH/} >= ${_item/BASH/} )) && continue
            fi
            ;;

            (KSH)
            # At present we just check that we have one of the following env vars
            (( ${#KSH_VERSION} > 0 )) && continue
            [ "${#.sh.version}" -gt 0 ] && continue
            ;;

            (ZSH*)
            if (( ${#ZSH_VERSION} > 0 )); then
                # ZSH_VERSION outputs a semantic number e.g. 5.7.1
                # We use parameter expansion to pull out the dots e.g. ZSH571
                # We do a string, then an int comparison just as with bash
                [ "${_item}" = "ZSH${ZSH_VERSION//./}" ] && continue
                (( ${_item/ZSH/} >= ${ZSH_VERSION//./} )) && continue
            fi
            ;;

            (root)
            (( ${EUID:-$(id -u)} == 0 )) && continue
            ;;
        esac

        # Next, try to determine if it's a command
        command -v "${_item}" >/dev/null 2>&1 && continue

        # Next, see if it's an executable file e.g. a script to call
        [ -x "./${_item}" ] && continue

        # Next, let's see if it's a library in SH_LIBPATH
        _found_lib=0
        for _target_lib in ${SH_LIBPATH//://$_item }/${_item}; do
            if [ -r "${_target_lib}" ]; then
                _found_lib=1
                break
            fi
        done
        (( _found_lib )) && continue

        # Next, let's see if it's a readable file e.g. a cfg file to load
        [ -r "${_item}" ] && continue

        # If we get to this point, add it to our list of failures
        _failures="${_failures} ${_item}"
    done

    _failures="${_failures# }"

    if (( ${#_failures} == 0 )); then
        return 0
    else
        printf -- '%s\n' "The following requirements were not met:" "${_failures}" >&2
        return 1
    fi
}
