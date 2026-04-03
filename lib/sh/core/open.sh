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
# Adapted from timo-reymann/bash-tui-framework (Apache-2.0)
#   https://github.com/timo-reymann/bash-tui-framework

[ -n "${_SHELLAC_LOADED_core_open+x}" ] && return 0
_SHELLAC_LOADED_core_open=1

# @description Open a file, directory, or URL using the platform-appropriate
#   opener command: xdg-open (Linux), open (macOS), start (Windows/Cygwin).
#   Named open() by deliberate convention — the same verb used on macOS and
#   Windows, and by xdg-open on Linux.
#   Detected once at source time; on macOS the native open(1) is used as-is.
#
# @arg $1 string File path, directory, or URL to open
#
# @example
#   open report.html
#   open /etc/hosts
#   open "https://example.com"
#
# @exitcode 0 Opened; 1 No suitable opener found; 2 Missing argument
# If open(1) already exists (e.g. macOS /usr/bin/open), nothing to define
command -v open >/dev/null 2>&1 && return 0

if command -v xdg-open >/dev/null 2>&1; then
  open() { xdg-open "${1:?open: missing argument}" >/dev/null 2>&1 & }
elif command -v start >/dev/null 2>&1; then
  open() { start "${1:?open: missing argument}" >/dev/null 2>&1 & }
else
  open() {
    printf -- '%s\n' "open: no suitable opener available (tried xdg-open, open, start)" >&2
    return 1
  }
fi
