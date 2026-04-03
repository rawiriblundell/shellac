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

[ -n "${_SHELLAC_LOADED_crypto_ssh_fingerprint+x}" ] && return 0
_SHELLAC_LOADED_crypto_ssh_fingerprint=1

# @description Display the SSH key fingerprint(s) for one or more remote hosts.
#   With '-a' or '--append', the scanned keys are merged into ~/.ssh/known_hosts.
#   Prefers ed25519 where the local SSH client supports it.
#
# @arg $1 string Optional: '-a' or '--append' to add keys to known_hosts
# @arg $2 string One or more hostnames or IP addresses
#
# @example
#   ssh_fingerprint example.com
#   ssh_fingerprint --append example.com 10.0.0.1
#
# @stdout SSH key fingerprints (without --append)
# @exitcode 0 Success
# @exitcode 1 No host resolved or empty keyscan result
ssh_fingerprint() {
  local _fingerprint _keyscanargs
  _fingerprint=$(mktemp)

  trap 'rm -f "${_fingerprint:?}" 2>/dev/null' RETURN

  # Test if the local host supports ed25519
  # Older versions of ssh don't have '-Q' so also likely won't have ed25519
  # If you wanted a more portable test: 'man ssh | grep ed25519' might be it
  ssh -Q key 2>/dev/null | grep -q ed25519 && _keyscanargs=( -t "ed25519,rsa,ecdsa" )

  # If we have an arg "-a" or "--append", we add our findings to known_hosts
  case "${1}" in
    (-a|--append)
      shift 1
      ssh-keyscan "${_keyscanargs[@]}" "${*}" > "${_fingerprint}" 2> /dev/null
      # If the fingerprint file is empty, then quietly fail
      [[ -s "${_fingerprint}" ]] || return 1
      cp "${HOME}"/.ssh/known_hosts{,."$(date +%Y%m%d)"}
      cat "${_fingerprint}" ~/.ssh/known_hosts."$(date +%Y%m%d)" |
        sort | 
        uniq > "${HOME}"/.ssh/known_hosts
    ;;
    (''|-h|--help)
      printf -- '%s\n' "Usage: ssh_fingerprint (-a|--append) [list of hostnames]"
      return 1
    ;;
    (*)
      ssh-keyscan "${_keyscanargs[@]}" "${*}" > "${_fingerprint}" 2> /dev/null
      [[ -s "${_fingerprint}" ]] || return 1
      ssh-keygen -l -f "${_fingerprint}"
    ;;
  esac
}
