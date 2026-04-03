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

[ -n "${_SHELLAC_LOADED_text_csvwrap+x}" ] && return 0
_SHELLAC_LOADED_text_csvwrap=1

# @description Wrap long comma-separated lists by element count.
#   Reads from stdin. Inserts a line continuation after every nth comma.
#
# @arg $1 int Optional: number of elements per line (default: 8)
#
# @stdout Wrapped comma-separated list with backslash continuations
# @exitcode 0 Always
csvwrap() {
  local _split_count
  _split_count="${1:-8}"
  _split_count="${_split_count}" perl -pe 's{,}{++$n % $ENV{_split_count} ? $& : ",\\\n"}ge'
}
