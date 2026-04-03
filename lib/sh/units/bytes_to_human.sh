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
# Adapted from labbots/bash-utility (MIT) https://github.com/labbots/bash-utility

[ -n "${_SHELLAC_LOADED_units_bytes_to_human+x}" ] && return 0
_SHELLAC_LOADED_units_bytes_to_human=1

# @description Format a byte count as a human-readable size string.
#   Uses 1024-based divisions (KiB-style increments) with two decimal places.
#
# @arg $1 int Size in bytes
#
# @example
#   units_bytes_to_human 2240     # => "2.18 KB"
#   units_bytes_to_human 1610612736  # => "1.50 GB"
#
# @stdout Human-readable size string, e.g. "2.19 KB", "1.50 GB"
# @exitcode 0 Success; 2 Missing argument
units_bytes_to_human() {
  local b d s
  declare -a S
  if (( ${#} == 0 )); then
    if [[ ! -t 0 ]]; then
      IFS= read -r b
    else
      printf -- '%s\n' "units_bytes_to_human: missing argument" >&2
      return 2
    fi
  else
    b="${1}"
  fi
  d=""
  s=0
  S=( Bytes {K,M,G,T,P,E,Y,Z}B )
  while (( b > 1024 )); do
    d="$(printf -- '.%02d' "$(( b % 1024 * 100 / 1024 ))")"
    b=$(( b / 1024 ))
    (( s++ ))
  done
  printf -- '%s\n' "${b}${d} ${S[${s}]}"
}
