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
# Provenance: https://raw.githubusercontent.com/rawiriblundell/dotfiles/master/.bashrc
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_array_aggregate+x}" ] && return 0
_SHELLAC_LOADED_array_aggregate=1
requires BASH43

# @description Sum all numeric elements in a named array.
#
# @arg $1 string Name of the array variable.
#
# @example
#   nums=( 1 2 3 4 5 )
#   array_sum nums  # => 15
#
# @stdout The sum of all elements.
# @exitcode 0 Always
array_sum() {
  local -n _arr="${1:?No array name given}"
  local _item _total
  _total=0
  for _item in "${_arr[@]}"; do
    (( _total += _item ))
  done
  printf -- '%s\n' "${_total}"
}

# @description Print the minimum numeric value in a named array.
#
# @arg $1 string Name of the array variable.
#
# @example
#   nums=( 3 1 4 1 5 9 )
#   array_min nums  # => 1
#
# @stdout The minimum element value.
# @exitcode 0 Always
array_min() {
  local -n _arr="${1:?No array name given}"
  local _item _min
  _min="${_arr[0]}"
  for _item in "${_arr[@]}"; do
    (( _item < _min )) && _min="${_item}"
  done
  printf -- '%s\n' "${_min}"
}

# @description Print the maximum numeric value in a named array.
#
# @arg $1 string Name of the array variable.
#
# @example
#   nums=( 3 1 4 1 5 9 )
#   array_max nums  # => 9
#
# @stdout The maximum element value.
# @exitcode 0 Always
array_max() {
  local -n _arr="${1:?No array name given}"
  local _item _max
  _max="${_arr[0]}"
  for _item in "${_arr[@]}"; do
    (( _item > _max )) && _max="${_item}"
  done
  printf -- '%s\n' "${_max}"
}

# @description Multiply all numeric elements in a named array.
#
# @arg $1 string Name of the array variable.
#
# @example
#   nums=( 2 3 4 )
#   array_product nums  # => 24
#
# @stdout The product of all elements.
# @exitcode 0 Always
array_product() {
  local -n _arr="${1:?No array name given}"
  local _item _total
  _total=1
  for _item in "${_arr[@]}"; do
    (( _total *= _item ))
  done
  printf -- '%s\n' "${_total}"
}
