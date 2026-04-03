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

[ -n "${_SHELLAC_LOADED_sys_mount+x}" ] && return 0
_SHELLAC_LOADED_sys_mount=1

if ! command -v mount >/dev/null 2>&1; then
  printf -- 'sys_mounts: %s\n' "'mount' was not found in PATH" >&2
  return 1
fi

# @description Print all currently mounted filesystems using 'mount'.
#
# @stdout Output of 'mount', or a warning to stderr if mount returns nothing
# @exitcode 0 Always
sys_mounts() {
  local output
  output="$(mount)"
  if [[ -n "${output}" ]]; then
    printf -- '%s\n' "${output}"
  else
    printf -- "sys_mounts: 'mount' returned no output\n" >&2
  fi
}
