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

[ -n "${_SHELLAC_LOADED_net_download+x}" ] && return 0
_SHELLAC_LOADED_net_download=1
requires BASH4

# @description Follow redirects on a URL and download the final target file,
#   saving it under its remote filename in the current directory.
#
# @arg $1 string URL to download
#
# @stdout Progress from curl
# @exitcode 0 Download succeeded
# @exitcode 1 Download failed
net_download() {
  local _remote_target _local_target
  _remote_target="${1:?No target specified}"
  _remote_target="$(curl "${_remote_target}" -s -L -I -o /dev/null -w '%{url_effective}')"
  _local_target="${_remote_target##*/}"
  printf -- '%s\n' "Attempting to download ${_remote_target}..."
  curl -- "${_remote_target}" -o "${_local_target}" || return 1
}

# @description Download the best release of a SourceForge project for the current
#   (or specified) platform. Requires 'curl' and 'jq'.
#
# @arg $1 string SourceForge project name
# @arg $2 string Target OS: linux, mac, or windows (default: auto-detect)
#
# @example
#   net_download_sourceforge omegat
#   net_download_sourceforge omegat linux
#
# @exitcode 0 Success
# @exitcode 1 Missing dependency or download failure
net_download_sourceforge() {
  local _binary _fail_count
  _fail_count=0
  for _binary in curl jq; do
    if ! command -v "${_binary}" >/dev/null 2>&1; then
      printf -- '%s\n' "${_binary} is required but was not found in PATH" >&2
      (( _fail_count++ ))
    fi
  done
  (( _fail_count > 0 )) && return 1

  local _sf_proj _os_str _curl_opts _curl_target _element _remote_target
  local _linux_src _mac_src _win_src
  _sf_proj="${1:?No sourceforge project defined}"
  _os_str="${2:-auto}"
  _curl_opts=( -s -L -I -o /dev/null -w '%{url_effective}' )

  mapfile -t < <(
    curl -s "https://sourceforge.net/projects/${_sf_proj}/best_release.json" |
      jq -r '.platform_releases[].url'
  )

  # shellcheck disable=SC2068
  for _element in ${MAPFILE[@]}; do
    case "${_element}" in
      (*[lL]inux*)           _linux_src="${_element}" ;;
      (*[mM]ac*|*[dD]arwin*) _mac_src="${_element}" ;;
      (*[wW]in*)             _win_src="${_element}" ;;
    esac
  done

  case "${_os_str}" in
    ([lL]inux) _curl_target="${_linux_src}" ;;
    ([mM]ac*)  _curl_target="${_mac_src}" ;;
    ([wW]in*)  _curl_target="${_win_src}" ;;
    (auto)
      case "$(uname)" in
        (Linux)      _curl_target="${_linux_src}" ;;
        (Darwin)     _curl_target="${_mac_src}" ;;
        (Win*|*WIN*) _curl_target="${_win_src}" ;;
      esac
    ;;
  esac

  _remote_target="$(curl "${_curl_opts[@]}" "${_curl_target}")"
  printf -- '%s\n' "Attempting to download ${_remote_target}..."
  curl -O "${_remote_target}" || return 1
}
