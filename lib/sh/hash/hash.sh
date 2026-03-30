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

[ -n "${_SHELLAC_LOADED_hash_hash+x}" ] && return 0
_SHELLAC_LOADED_hash_hash=1

# Requires bash 4.0+ for associative arrays (declare -A).

# @description Set a key in a named associative array.
#
# @arg $1 string Name of the associative array
# @arg $2 string Key
# @arg $3 string Value
#
# @exitcode 0 Success
# @exitcode 1 Missing argument
hash_set() {
  local -n _hash_set_ref="${1:?hash_set: array name required}"
  # shellcheck disable=SC2034
  _hash_set_ref["${2:?hash_set: key required}"]="${3?hash_set: value required}"
}

# @description Print the value for a key in a named associative array.
#   Exits 1 if the key does not exist.
#
# @arg $1 string Name of the associative array
# @arg $2 string Key
#
# @stdout Value for the key
# @exitcode 0 Key exists
# @exitcode 1 Key not found
hash_get() {
  local -n _hash_get_ref="${1:?hash_get: array name required}"
  local key
  key="${2:?hash_get: key required}"
  if [[ ! -v _hash_get_ref["${key}"] ]]; then
    return 1
  fi
  printf -- '%s\n' "${_hash_get_ref["${key}"]}"
}

# @description Return 0 if a key exists in a named associative array.
#
# @arg $1 string Name of the associative array
# @arg $2 string Key
#
# @exitcode 0 Key exists
# @exitcode 1 Key not found
hash_has() {
  local -n _hash_has_ref="${1:?hash_has: array name required}"
  [[ -v _hash_has_ref["${2:?hash_has: key required}"] ]]
}

# @description Delete a key from a named associative array.
#   No-op if the key does not exist.
#
# @arg $1 string Name of the associative array
# @arg $2 string Key
#
# @exitcode 0 Always
hash_del() {
  local -n _hash_del_ref="${1:?hash_del: array name required}"
  unset '_hash_del_ref['"${2:?hash_del: key required}"']'
}

# @description Print all keys of a named associative array, one per line.
#   Output order is not guaranteed (bash associative arrays are unordered).
#
# @arg $1 string Name of the associative array
#
# @stdout Keys, one per line
# @exitcode 0 Always
hash_keys() {
  local -n _hash_keys_ref="${1:?hash_keys: array name required}"
  printf -- '%s\n' "${!_hash_keys_ref[@]}"
}

# @description Print all values of a named associative array, one per line.
#   Output order is not guaranteed (bash associative arrays are unordered).
#
# @arg $1 string Name of the associative array
#
# @stdout Values, one per line
# @exitcode 0 Always
hash_values() {
  local -n _hash_values_ref="${1:?hash_values: array name required}"
  printf -- '%s\n' "${_hash_values_ref[@]}"
}

# @description Call a function with each key and value in a named associative array.
#   The function receives two arguments: key and value.
#   Iteration order is not guaranteed.
#
# @arg $1 string Name of the associative array
# @arg $2 string Name of the function to call
#
# @example
#   print_pair() { printf '%s => %s\n' "${1}" "${2}"; }
#   hash_each mymap print_pair
#
# @exitcode 0 Always
# @exitcode 1 Missing argument
hash_each() {
  local -n _hash_each_ref="${1:?hash_each: array name required}"
  local func key
  func="${2:?hash_each: function name required}"
  for key in "${!_hash_each_ref[@]}"; do
    "${func}" "${key}" "${_hash_each_ref["${key}"]}"
  done
}
