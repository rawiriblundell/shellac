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

[ -n "${_SHELLAC_LOADED_utils_choose+x}" ] && return 0
_SHELLAC_LOADED_utils_choose=1

# @description Pick one element at random from the given arguments.
#
# @arg $@ string Elements to choose from
#
# @example
#   choose apple banana cherry    # prints one of the three
#   day=$(choose Mon Tue Wed Thu Fri)
#
# @stdout The chosen element
# @exitcode 0 Always; 1 No arguments
choose() {
  (( ${#} == 0 )) && { printf -- '%s\n' "choose: no elements provided" >&2; return 1; }
  printf -- '%s\n' "${@:$(( (RANDOM % $#) + 1 )):1}"
}
