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
# Provenance: https://github.com/rawiriblundell/shellac
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_core_wants+x}" ] && return 0
_SHELLAC_LOADED_core_wants=1

# @internal
# Warn if a file is world-writable, add a trace entry, then source the file.
_wants_source() {
    local _target
    _target="${1}"

    if [ -n "$(find "${_target}" -maxdepth 0 -perm -o+w 2>/dev/null)" ]; then
        printf -- 'wants: warning: %s is world-writable\n' "${_target}" >&2
    fi

    sh_stack_add "Reading config from ${_target}"
    # shellcheck disable=SC1090
    . "${_target}" || {
        printf -- 'wants: failed to load %s\n' "${_target}" >&2
        return 1
    }
}

# @description Source a file only if it exists; silently skip if it does not.
#   When given a bare filename (no path separator), searches SH_CONFPATH_ARRAY
#   in order and sources all matches, allowing later entries to override earlier
#   ones. When given a path, sources that specific file if it exists.
#   Unlike include(), a missing file is not an error. An existing but unreadable
#   or broken file still causes a failure.
#
# @arg $1 string Path to file, or bare filename to search across SH_CONFPATH_ARRAY
#
# @stderr Warning if a file is world-writable
# @stderr Error if a file exists but is unreadable or fails to source
# @exitcode 0 File(s) sourced successfully, or not found
# @exitcode 1 File exists but is unreadable or failed to source
wants() {
    local _fstarget
    local _conf_element
    local _candidate
    _fstarget="${1:?No target specified}"

    case "${_fstarget}" in
        (*/*)
            # Has a path separator — treat as a direct path
            [ -e "${_fstarget}" ] || return 0
            if [ ! -r "${_fstarget}" ]; then
                printf -- 'wants: %s exists but is not readable\n' "${_fstarget}" >&2
                return 1
            fi
            _wants_source "${_fstarget}" || return 1
        ;;
        (*)
            # Bare filename — search all SH_CONFPATH_ARRAY entries in order.
            # Every match is sourced so higher-precedence entries can override lower ones.
            for _conf_element in "${SH_CONFPATH_ARRAY[@]}"; do
                _candidate="${_conf_element}/${_fstarget}"
                [ -e "${_candidate}" ] || continue
                if [ ! -r "${_candidate}" ]; then
                    printf -- 'wants: %s exists but is not readable\n' "${_candidate}" >&2
                    return 1
                fi
                _wants_source "${_candidate}" || return 1
            done
        ;;
    esac
}
