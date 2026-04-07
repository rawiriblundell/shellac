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

[ -n "${_SHELLAC_LOADED_git_releases+x}" ] && return 0
_SHELLAC_LOADED_git_releases=1
requires BASH4

# Requires: curl, jq

# @description Resolve a GitHub release version tag to a JSON blob via the API.
#   Tries the tag as-is, then with a 'v' prefix, then with 'release-' prefix.
#   Writes JSON to stdout. Completely silent on failure.
#
# @arg $1 string owner/repo slug
# @arg $2 string Version tag, or 'latest'
#
# @stdout Release JSON from the GitHub API
# @exitcode 0 Release found
# @exitcode 1 No matching release found
_git_fetch_release_json() {
  local _repo _version _url _json
  _repo="${1}"
  _version="${2}"

  local _max_time
  _max_time="${SHELLAC_CURL_MAX_TIME:-30}"

  if [[ "${_version}" = "latest" ]]; then
    _url="https://api.github.com/repos/${_repo}/releases/latest"
    _json=$(curl -fsSL --max-time "${_max_time}" "${_url}" 2>/dev/null) && printf -- '%s\n' "${_json}" && return 0
    return 1
  fi

  local -a candidates
  candidates=( "${_version}" "v${_version}" "release-${_version}" )
  # Avoid duplicate if version already starts with 'v'
  [[ "${_version}" = v* ]] && candidates=( "${_version}" "release-${_version#v}" )

  local _tag
  for _tag in "${candidates[@]}"; do
    _url="https://api.github.com/repos/${_repo}/releases/tags/${_tag}"
    _json=$(curl -fsSL --max-time "${_max_time}" "${_url}" 2>/dev/null) || continue
    # GitHub returns 200 with a message field on not-found; check for tag_name
    printf -- '%s\n' "${_json}" | jq -e '.tag_name' >/dev/null 2>&1 || continue
    printf -- '%s\n' "${_json}"
    return 0
  done
  return 1
}

# @description Return the arch aliases to try when matching release asset filenames.
#
# @arg $1 string Normalised OS_ARCH value (x86_64, aarch64, arm, ...)
#
# @stdout Space-separated alias list, highest-priority first
_git_fetch_release_arch_aliases() {
  case "${1}" in
    (x86_64)  printf -- '%s\n' "x86_64 amd64 x64" ;;
    (aarch64) printf -- '%s\n' "aarch64 arm64" ;;
    (arm)     printf -- '%s\n' "armv7l armv7 arm" ;;
    (*)       printf -- '%s\n' "${1}" ;;
  esac
}

# @description Fetch a release asset from a GitHub repository.
#   Downloads the asset to the current directory. Does not extract archives.
#   Requires curl and jq.
#
# @arg $1 string owner/repo slug (required)
# @arg $2 string Version tag, or 'latest' (default: latest)
# @arg $3 string Architecture override (default: detected from uname -m)
#
# @example
#   git_fetch_release cli/cli
#   git_fetch_release cli/cli v2.40.0
#   git_fetch_release cli/cli latest arm64
#
# @stdout Download progress from curl
# @exitcode 0 Asset downloaded successfully
# @exitcode 1 Error (missing args, no matching asset, download failure)
git_fetch_release() {
  local _repo _version _arch
  local _release_json _asset_url _asset_name
  local -a arch_aliases all_assets tarball_assets

  _repo="${1:?git_fetch_release: owner/_repo argument required}"
  _version="${2:-latest}"
  _arch="${3:-}"

  # Detect arch if not supplied
  if [[ -z "${_arch}" ]]; then
    _arch=$(uname -m 2>/dev/null)
    : "${_arch:=x86_64}"
  fi

  # Fetch release metadata
  _release_json=$(_git_fetch_release_json "${_repo}" "${_version}") || {
    printf -- '%s\n' "git_fetch_release: release '${_version}' not found for ${_repo}" >&2
    return 1
  }

  # Build ordered alias list for this arch
  local _aliases_str
  _aliases_str=$(_git_fetch_release_arch_aliases "${_arch}")
  read -ra arch_aliases <<< "${_aliases_str}"

  # Extract all browser_download_urls from the release
  mapfile -t all_assets < <(
    printf -- '%s\n' "${_release_json}" |
      jq -r '.assets[].browser_download_url' 2>/dev/null
  )

  if (( ${#all_assets[@]} == 0 )); then
    printf -- '%s\n' "git_fetch_release: no assets found for ${_repo} ${_version}" >&2
    return 1
  fi

  # Filter: skip checksums, signatures, source archives
  local -a filtered_assets
  for _asset_url in "${all_assets[@]}"; do
    case "${_asset_url}" in
      (*.sha256|*.sha512|*.md5|*.asc|*.sig|*source.tar.gz|*_checksums.txt) continue ;;
    esac
    filtered_assets+=( "${_asset_url}" )
  done

  # Select asset: iterate arch aliases, prefer tarballs over zip
  local _selected=""
  local _alias
  for _alias in "${arch_aliases[@]}"; do
    # Collect candidates matching this alias
    tarball_assets=()
    for _asset_url in "${filtered_assets[@]}"; do
      [[ "${_asset_url}" != *"${_alias}"* ]] && continue
      case "${_asset_url}" in
        (*.tar.gz|*.tar.xz|*.tar.bz2|*.tgz) tarball_assets+=( "${_asset_url}" ) ;;
      esac
    done
    if (( ${#tarball_assets[@]} > 0 )); then
      _selected="${tarball_assets[0]}"
      break
    fi
    # No tarball — accept zip or bare binary for this alias
    for _asset_url in "${filtered_assets[@]}"; do
      [[ "${_asset_url}" != *"${_alias}"* ]] && continue
      _selected="${_asset_url}"
      break
    done
    [[ -n "${_selected}" ]] && break
  done

  if [[ -z "${_selected}" ]]; then
    printf -- '%s\n' "git_fetch_release: no asset matching _arch '${_arch}' found for ${_repo} ${_version}" >&2
    printf -- '%s\n' "Available assets:" >&2
    printf -- '  %s\n' "${filtered_assets[@]}" >&2
    return 1
  fi

  local _download_max_time
  _download_max_time="${SHELLAC_CURL_DOWNLOAD_MAX_TIME:-120}"

  _asset_name="${_selected##*/}"
  printf -- '%s\n' "Downloading: ${_selected}" >&2
  curl -fL --progress-bar --max-time "${_download_max_time}" -o "${_asset_name}" "${_selected}"
}
