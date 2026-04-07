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

[ -n "${_SHELLAC_LOADED_array_toarray+x}" ] && return 0
_SHELLAC_LOADED_array_toarray=1
requires BASH43

# toarray requires 'lastpipe' so that the array persists after the pipeline.
# This shopt is set at load time so it applies to all subsequent pipelines.
shopt -s lastpipe || {
  printf -- '%s\n' "toarray: requires bash 4.2+ (lastpipe support)" >&2
  return 1
}

# @description Collect stdin into a named array, for use as the last command in a pipeline.
#   Requires bash 4.2+ (lastpipe, enabled at load time).
#
# @arg $1 string Name of the array variable.
#
# @example
#   printf '%s\n' a b c | toarray myarr
#   printf '%s\n' "${myarr[@]}"
#   # => a
#   # => b
#   # => c
#
# @exitcode 0 Always
toarray() {
  local -n _arr="${1:?No array name given}"
  readarray -t _arr
}
