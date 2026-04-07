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

[ -n "${_SHELLAC_LOADED_array_readlist+x}" ] && return 0
_SHELLAC_LOADED_array_readlist=1
requires BASH43

# @description Read a comma-separated list into an indexed array, modelled on
#   readarray/mapfile. Accepts bare words, quoted strings, or Python-style
#   bracket notation. Strips commas, brackets, and surrounding whitespace from
#   each element. Defaults to READLIST as the target array name.
#
# @arg $1 string Optional: '-n <name>' to specify target array name
# @arg $@ string One or more comma-separated values, optionally enclosed in []
#
# @example
#   readlist dev, prod, test
#   printf '%s\n' "${READLIST[@]}"
#   # => dev
#   # => prod
#   # => test
#
#   readlist -n envs "[dev, prod, test]"
#   printf '%s\n' "${envs[@]}"
#   # => dev
#   # => prod
#   # => test
#
# @exitcode 0 Always
readlist() {
  local _arr_name _input _elem
  local -a _elements _cleaned

  _arr_name="READLIST"

  if [[ "${1}" = "-n" ]]; then
    _arr_name="${2:?readlist: -n requires an array name}"
    shift 2
  fi

  # Join all args, strip optional surrounding brackets
  _input="${*}"
  _input="${_input#\[}"
  _input="${_input%\]}"

  # Split on commas
  IFS=',' read -ra _elements <<< "${_input}"

  # Trim leading and trailing whitespace from each element
  for _elem in "${_elements[@]}"; do
    _elem="${_elem#"${_elem%%[! ]*}"}"
    _elem="${_elem%"${_elem##*[! ]}"}"
    _cleaned+=( "${_elem}" )
  done

  # Assign via nameref so the target array lives in the caller's scope
  local -n _readlist_target="${_arr_name}"
  # shellcheck disable=SC2034
  _readlist_target=( "${_cleaned[@]}" )
}
