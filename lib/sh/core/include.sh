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

[ -n "${_SHELLAC_LOADED_core_include+x}" ] && return 0
_SHELLAC_LOADED_core_include=1

# TODO: include [url] --> download code to temporary location, source, destroy afterwards?

# @internal
# Source a file and, when verbose, print any functions newly defined by it.
_include_source() {
    local _file _verbose _before _after _func
    _file="${1}"
    _verbose="${2:-0}"
    (( _verbose )) && _before=$(declare -F | awk '{print $3}')
    # shellcheck disable=SC1090
    . "${_file}" || return 1
    if (( _verbose )); then
        _after=$(declare -F | awk '{print $3}')
        while IFS= read -r _func; do
            printf -- 'include: loaded function: %s\n' "${_func}"
        done < <(comm -13 <(printf '%s\n' "${_before}" | sort) \
                            <(printf '%s\n' "${_after}"  | sort))
    fi
}

# @internal
_include_sentinel() {
    local _path _rel _element
    _path="${1}"
    for _element in "${SH_LIBPATH_ARRAY[@]}"; do
        if [ "${_path#${_element}/}" != "${_path}" ]; then
            _rel="${_path#${_element}/}"
            break
        fi
    done
    # Fallback for full paths not under any known SH_LIBPATH element
    : "${_rel:=$(basename "$(dirname "${_path}")")/$(basename "${_path}")}"
    _rel="${_rel%.sh}"
    _rel="${_rel//\//_}"
    _rel="${_rel//-/_}"
    printf -- '%s\n' "_SHELLAC_LOADED_${_rel}"
}

# @internal
_include_is_loaded() {
    local _sentinel
    _sentinel=$(_include_sentinel "${1}")
    declare -p "${_sentinel}" >/dev/null 2>&1
}

# @description Source a library from SH_LIBPATH or a full path.
#
# @arg $1 string Full path, subdirectory name, or relative path (with or without extension)
#
# @example
#   include /opt/company/libs/sh/library.sh   # full path
#   include units                              # load all .sh files in a subdir
#   include text/puts                          # relative path, defaults to .sh
#   include text/puts.bash                     # relative path with explicit extension
#
# @exitcode 0 Library loaded successfully
# @exitcode 1 Library not found, unreadable, or failed to source
include() {
    local _include_target
    local _element
    local _subdir
    local _load_target
    local _verbose
    local _force

    _verbose=0
    _force=0
    while [ "${1}" = '-v' ] || [ "${1}" = '-f' ] || [ "${1}" = '--force' ]; do
        case "${1}" in
            (-v)         _verbose=1 ;;
            (-f|--force) _force=1 ;;
        esac
        shift
    done

    sh_stack_add "Entering 'include()' and processing ${#} found arg(s): '${*}'"

    # Ensure that SH_LIBPATH has some substance, otherwise why bother?
    if (( "${#SH_LIBPATH}" == 0 )); then
        _shellac_stack dump
        printf -- 'include: %s\n' "SH_LIBPATH appears to be empty" >&2
        return 1
    fi

    # Ensure that we have an arg to parse
    if (( "${#}" == 0 )); then
        _shellac_stack dump
        printf -- 'include: %s\n' "No args given" >&2
        return 1
    fi

    _include_target="${1}"

    # Is it a full path to a readable file?
    # Example: include /opt/something/specific/library.sh
    sh_stack_add "Is '${_include_target}' a full path to a file?"
    if [ -f "${_include_target}" ]; then
        sh_stack_add "Full path: '${_include_target}' exists.  Is it readable?"
        if [ -r "${_include_target}" ]; then
            (( _force )) || { _include_is_loaded "${_include_target}" && return 0; }
            sh_stack_add "Full path: '${_include_target}' readable.  Loading."
            if _include_source "${_include_target}" "${_verbose}"; then
                return 0
            else
                sh_stack_add "Full path: '${_include_target}' readable but not loadable.  Failing."
                _shellac_stack dump
                printf -- 'include: %s\n' "Error while including '${_include_target}'" >&2
                return 1
            fi
        else
            sh_stack_add "Full path: '${_include_target}' unreadable.  Failing."
            _shellac_stack dump
            printf -- 'include: %s\n' "Insufficient permissions while including '${_include_target}'" >&2
            return 1
        fi
    fi
    sh_stack_add "'${_include_target}' is apparently not a full path to a file."

    # If the target is an absolute path but the file doesn't exist, fail here
    # rather than falling through SH_LIBPATH resolution with a confusing error.
    if [[ "${_include_target}" = /* ]]; then
        _shellac_stack dump
        printf -- 'include: %s\n' "'${_include_target}' not found or not a regular file" >&2
        return 1
    fi

    # If it's not a full path, we work through a sequence of tests:
    # Is it a subdir within SH_LIBPATH e.g. include text
    # Is it a subdir/library with an explicit extension e.g. include text/puts.bash
    # Is it a subdir/library with an implicit extension (i.e. ".sh" default) e.g. include text/puts
    for _element in "${SH_LIBPATH_ARRAY[@]}"; do
        # Is the given target a subdir within $_element?  If so, load everything within that path.
        # Note: we only load everything with a .sh extension
        # We don't want to try loading library.zsh into bash, for example
        sh_stack_add "Is '${_include_target}' a sub-directory within ${_element}?"
        if [ -d "${_element}/${_include_target}" ]; then
            _subdir="${_element}/${_include_target}"
            sh_stack_add "Loading all libraries and functions from '${_subdir}'"
            for _load_target in "${_subdir}"/*.sh; do
                (( _force )) || { _include_is_loaded "${_load_target}" && continue; }
                if [ -r "${_load_target}" ]; then
                    _include_source "${_load_target}" "${_verbose}" || {
                        _shellac_stack dump
                        printf -- 'include: %s\n' "Failed to load '${_load_target}'" >&2
                        return 1
                    }
                else
                    _shellac_stack dump
                    printf -- 'include: %s\n' "Insufficient permissions while including '${_load_target}'" >&2
                    return 1
                fi
            done
            return 0
        fi
        sh_stack_add "'${_include_target}' is apparently not a sub-directory within ${_element}."

        # With the above scenario out of the way, we now assess the following in order:
        # include subdir/library.extension (e.g. include text/tolower.sh)
        #     This scenario allows us to load shell specific libs e.g. text/tolower.zsh
        # include subdir/library           (e.g. include text/tolower)
        #     This scenario defaults to the .sh extension i.e. text/tolower = text/tolower.sh
        sh_stack_add "Is '${_include_target}' a relative path within ${_element}?"
        if [ -f "${_element}/${_include_target}" ] || [ -f "${_element}/${_include_target}.sh" ]; then
            sh_stack_add "Relative path: '${_element}/${_include_target}' exists.  Is it readable?"
            if [ -r "${_element}/${_include_target}" ]; then
                _load_target="${_element}/${_include_target}"
            elif [ -r "${_element}/${_include_target}.sh" ]; then
                _load_target="${_element}/${_include_target}.sh"
            else
                _shellac_stack dump
                printf -- 'include: %s\n' "Insufficient permissions while including '${_include_target}' from '${_element}'" >&2
                return 1
            fi

            (( _force )) || { _include_is_loaded "${_load_target}" && return 0; }

            _include_source "${_load_target}" "${_verbose}" || {
                printf -- 'include: %s\n' "Failed to load '${_load_target}'" >&2
                return 1
            }
            return 0
        else
            sh_stack_add "'${_include_target}' is apparently not a relative path within ${_element}."
        fi
    done

    # If we're here, then 'include()' wasn't called correctly
    _shellac_stack dump
    printf -- 'include: %s\n' "Unspecified error while executing 'include ${*}'" >&2
    return 1
}
