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
  local repo version url json
  repo="${1}"
  version="${2}"

  if [[ "${version}" = "latest" ]]; then
    url="https://api.github.com/repos/${repo}/releases/latest"
    json=$(curl -fsSL "${url}" 2>/dev/null) && printf -- '%s\n' "${json}" && return 0
    return 1
  fi

  local -a candidates
  candidates=( "${version}" "v${version}" "release-${version}" )
  # Avoid duplicate if version already starts with 'v'
  [[ "${version}" = v* ]] && candidates=( "${version}" "release-${version#v}" )

  local tag
  for tag in "${candidates[@]}"; do
    url="https://api.github.com/repos/${repo}/releases/tags/${tag}"
    json=$(curl -fsSL "${url}" 2>/dev/null) || continue
    # GitHub returns 200 with a message field on not-found; check for tag_name
    printf -- '%s\n' "${json}" | jq -e '.tag_name' >/dev/null 2>&1 || continue
    printf -- '%s\n' "${json}"
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
  local repo version arch
  local release_json asset_url asset_name
  local -a arch_aliases all_assets tarball_assets

  repo="${1:?git_fetch_release: owner/repo argument required}"
  version="${2:-latest}"
  arch="${3:-}"

  # Detect arch if not supplied
  if [[ -z "${arch}" ]]; then
    arch=$(uname -m 2>/dev/null)
    : "${arch:=x86_64}"
  fi

  # Fetch release metadata
  release_json=$(_git_fetch_release_json "${repo}" "${version}") || {
    printf -- '%s\n' "git_fetch_release: release '${version}' not found for ${repo}" >&2
    return 1
  }

  # Build ordered alias list for this arch
  local aliases_str
  aliases_str=$(_git_fetch_release_arch_aliases "${arch}")
  read -ra arch_aliases <<< "${aliases_str}"

  # Extract all browser_download_urls from the release
  mapfile -t all_assets < <(
    printf -- '%s\n' "${release_json}" |
      jq -r '.assets[].browser_download_url' 2>/dev/null
  )

  if (( ${#all_assets[@]} == 0 )); then
    printf -- '%s\n' "git_fetch_release: no assets found for ${repo} ${version}" >&2
    return 1
  fi

  # Filter: skip checksums, signatures, source archives
  local -a filtered_assets
  for asset_url in "${all_assets[@]}"; do
    case "${asset_url}" in
      (*.sha256|*.sha512|*.md5|*.asc|*.sig|*source.tar.gz|*_checksums.txt) continue ;;
    esac
    filtered_assets+=( "${asset_url}" )
  done

  # Select asset: iterate arch aliases, prefer tarballs over zip
  local selected=""
  local alias
  for alias in "${arch_aliases[@]}"; do
    # Collect candidates matching this alias
    tarball_assets=()
    for asset_url in "${filtered_assets[@]}"; do
      [[ "${asset_url}" != *"${alias}"* ]] && continue
      case "${asset_url}" in
        (*.tar.gz|*.tar.xz|*.tar.bz2|*.tgz) tarball_assets+=( "${asset_url}" ) ;;
      esac
    done
    if (( ${#tarball_assets[@]} > 0 )); then
      selected="${tarball_assets[0]}"
      break
    fi
    # No tarball — accept zip or bare binary for this alias
    for asset_url in "${filtered_assets[@]}"; do
      [[ "${asset_url}" != *"${alias}"* ]] && continue
      selected="${asset_url}"
      break
    done
    [[ -n "${selected}" ]] && break
  done

  if [[ -z "${selected}" ]]; then
    printf -- '%s\n' "git_fetch_release: no asset matching arch '${arch}' found for ${repo} ${version}" >&2
    printf -- '%s\n' "Available assets:" >&2
    printf -- '  %s\n' "${filtered_assets[@]}" >&2
    return 1
  fi

  asset_name="${selected##*/}"
  printf -- '%s\n' "Downloading: ${selected}" >&2
  curl -fL --progress-bar -o "${asset_name}" "${selected}"
}
