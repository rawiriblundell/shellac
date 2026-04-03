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
# Provenance: https://github.com/rawiriblundell/sh_libpath
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_net_dns+x}" ] && return 0
_SHELLAC_LOADED_net_dns=1

# @description Get the DNS server addresses for the current host. Tries a range of
#   methods in order: scutil (macOS), resolvectl, systemd-resolve, nm-tool, nmcli,
#   host, and finally parsing /etc/resolv.conf or /var/run/resolv.conf.
#
# @stdout Comma-separated DNS server IP addresses
# @exitcode 0 Success
# @exitcode 1 Unable to determine any DNS servers
net_dns() {
  case "${OSSTR:-$(uname -s)}" in
    (mac|Darwin)
      printf -- '%s\n' "Attempting lookup test using 'scutil' command..." >&2
      scutil --dns |
        awk '/nameserver/{ a[$3]++} END { for (b in a) {print b } }'
      return 0
    ;;
    ([Ll]inux)
      if command -v resolvectl >/dev/null 2>&1; then
        printf -- '%s\n' "Attempting lookup test using 'resolvectl' command..." >&2
        resolvectl dns | awk -F ': ' '{print $2}' | grep . | paste -sd ' ' -
        return 0
      fi
      if command -v systemd-resolve >/dev/null 2>&1; then
        printf -- '%s\n' "Attempting lookup test using 'systemd-resolve' command..." >&2
        systemd-resolve --status | awk -F ': ' '/DNS Servers/{print $2}' | paste -sd ' ' -
        return 0
      fi
      if command -v nm-tool >/dev/null 2>&1; then
        nm-tool | awk '/DNS/{print $2}' | paste -sd ',' -
        return 0
      fi
      if command -v nmcli >/dev/null 2>&1; then
        # printf -- '%s\n' "Attempting lookup test using 'nmcli' command..." >&2
        if nmcli dev list >/dev/null 2>&1; then
          nmcli dev list | awk 'tolower($0) ~ /dns/{print $2}' | paste -sd ',' -
          return 0
        elif nmcli device show >/dev/null 2>&1; then
          nmcli --fields ip4.dns dev show | awk '/./{print $2}' | paste -sd ',' -
          return 0
        fi
      fi
    ;;
  esac
  if command -v host >/dev/null 2>&1; then
    printf -- '%s\n' "Attempting lookup test using 'host' command..." >&2
    host -v something.unknown | awk -F "[ #]" '/Received /{print$5}' | uniq
    return 0
  fi
  if [ -r /etc/resolv.conf ]; then
    printf -- '%s\n' "Parsing /etc/resolv.conf..." >&2
    awk '/nameserver/{print $2}' /etc/resolv.conf | paste -sd ',' -
    return 0
  fi
  # As above, but for OSX
  if [ -r /var/run/resolv.conf ]; then
    printf -- '%s\n' "Parsing /var/run/resolv.conf..." >&2
    awk '/nameserver/{print $2}' /etc/resolv.conf | paste -sd ',' -
    return 0
  fi
  # If we get to this point, we have failed.
  printf -- '%s\n' "Unable to determine any dns servers" >&2
  return 1
}

# @description Resolve a hostname to an IPv4 address, or reverse-resolve an IP
#   to its hostname. Uses 'host -4' for lookups.
#
# @arg $1 string Hostname or IPv4 address to look up
#
# @stdout The resolved IP address, or the hostname from a reverse lookup
# @exitcode 0 Success
# @exitcode 1 No argument supplied or unrecognised input
net_dns_resolve() {
  case "${1:-}" in
    ('')
      printf -- 'Usage: net_dns_resolve [hostname|ip.add.re.ss]\n' >&2
      return 1
    ;;
    ([a-zA-Z]*)
      host -4 -W 1 "${1}" | awk '{ print $4 }'
    ;;
    ([0-9]*.[0-9]*.[0-9]*.[0-9]*)
      host -4 -W 1 "${1}" | awk '{ print $NF }' | cut -d '.' -f1
    ;;
    (*)
      printf -- 'net_dns_resolve: unrecognised input: %s\n' "${1}" >&2
      return 1
    ;;
  esac
}
