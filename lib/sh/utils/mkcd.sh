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
# Adapted from modernish (ISC) https://github.com/modernish/modernish

[ -n "${_SHELLAC_LOADED_utils_mkcd+x}" ] && return 0
_SHELLAC_LOADED_utils_mkcd=1

# @description Create a directory (including parents) and change into it.
#   No-op on the mkdir if the directory already exists.
#
# @arg $1 string Directory path to create and enter
#
# @example
#   mkcd /tmp/my-project/src    # equivalent to: mkdir -p /tmp/my-project/src && cd /tmp/my-project/src
#
# @exitcode 0 Success; 1 mkdir or cd failed; 2 Missing argument
mkcd() {
  local _dir
  _dir="${1:?mkcd: missing directory argument}"
  mkdir -p -- "${_dir}" || return 1
  cd -- "${_dir}" || return 1
}
