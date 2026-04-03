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

[ -n "${_SHELLAC_LOADED_net_open_link+x}" ] && return 0
_SHELLAC_LOADED_net_open_link=1

include core/open

# @description Open a URL in the default browser using the platform opener.
#   A thin wrapper around open() that validates the argument looks like a URL.
#
# @arg $1 string URL to open (must begin with a scheme, e.g. https://)
#
# @example
#   net_open_link "https://example.com"
#   net_open_link "http://localhost:8080"
#
# @exitcode 0 Opened; 1 Invalid URL or no opener; 2 Missing argument
net_open_link() {
  local _url
  _url="${1:?net_open_link: missing URL argument}"
  case "${_url}" in
    (*://*) open "${_url}" ;;
    (*)
      printf -- '%s\n' "net_open_link: not a URL (no scheme): ${_url}" >&2
      return 1
    ;;
  esac
}
