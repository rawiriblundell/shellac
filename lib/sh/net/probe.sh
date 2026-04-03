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

[ -n "${_SHELLAC_LOADED_net_probe+x}" ] && return 0
_SHELLAC_LOADED_net_probe=1

# @description Test basic internet connectivity by attempting a TCP connection
#   to a well-known host via bash's /dev/tcp device.
#
# @arg $1 string Optional: host to test (default: 8.8.8.8)
# @arg $2 int    Optional: port to test (default: 53)
#
# @exitcode 0 Connection succeeded
# @exitcode 1 Connection failed or timed out
net_probe_internet() {
  local _test_host _test_port
  _test_host="${1:-8.8.8.8}"
  _test_port="${2:-53}"
  _timeout 1 bash -c ">/dev/tcp/${_test_host}/${_test_port}" >/dev/null 2>&1
}

# @description Test connectivity to a remote host's port via bash /dev/tcp or /dev/udp.
#   Requires bash with /dev/tcp support. For environments where that is unavailable
#   (e.g. minimal containers) use net_probe_tcp instead.
#
# @arg $1 string Remote hostname or IP address
# @arg $2 int    Port number (default: 22)
# @arg $3 string Protocol: tcp or udp (default: tcp)
#
# @example
#   net_probe_port example.com 443
#   net_probe_port example.com 53 udp
#
# @exitcode 0 Port is reachable
# @exitcode 1 Port is unreachable or timed out
net_probe_port() {
  _timeout 1 bash -c "</dev/${3:-tcp}/${1:?No target}/${2:-22}" 2>/dev/null
}

# @description Poll a host/port until it becomes reachable or a timeout expires.
#   Retries once per second using net_probe_port.
#
# @arg $1 string Remote hostname or IP address
# @arg $2 int    Port number (default: 22)
# @arg $3 int    Timeout in seconds (default: 30)
#
# @example
#   net_probe_wait db.example.com 5432 60
#
# @exitcode 0 Port became reachable within the timeout
# @exitcode 1 Timeout expired before port was reachable
net_probe_wait() {
  local _host _port _timeout _i
  _host="${1:?No target}"
  _port="${2:-22}"
  _timeout="${3:-30}"

  for (( _i = 0; _i < _timeout; _i++ )); do
    net_probe_port "${_host}" "${_port}" && return 0
    sleep 1
  done
  return 1
}

# @description Test TCP connectivity to a host and port using curl's telnet:// scheme.
#   Works in minimal container environments that lack bash /dev/tcp, nslookup,
#   telnet, and nc. Reliable for server-speaks-first protocols (e.g. MySQL, Redis,
#   SQL Server) where curl exit code 28 is ambiguous — inspects verbose output for
#   "Connected to" to confirm the TCP handshake succeeded, then kills curl immediately.
#   Completely silent; callers are responsible for all messaging.
#
# @arg $1 string Hostname or IP address
# @arg $2 int    TCP port number
# @arg $3 int    Optional: connect timeout in seconds (default: 5)
#
# @example
#   net_probe_tcp db.internal 5432 && printf '%s\n' "reachable"
#   net_probe_tcp 10.0.0.1 6379 10
#
# @exitcode 0 TCP connection established
# @exitcode 1 Connection failed (refused, timed out, or DNS failure)
net_probe_tcp() {
  local _host _port _timeout _tmp_out _curl_pid _connected _elapsed _max_polls _poll_interval

  _host="${1:?net_probe_tcp: _host argument required}"
  _port="${2:?net_probe_tcp: _port argument required}"
  _timeout="${3:-5}"
  _poll_interval="0.1"

  # max_polls = timeout / poll_interval — use integer arithmetic (tenths of seconds)
  _max_polls="$(( _timeout * 10 ))"

  _tmp_out="$(mktemp)" || return 1
  trap 'rm -f "${_tmp_out}"' RETURN

  # Run curl in background, capturing verbose stderr to temp file.
  # stdout discarded — we only care about the connection, not any data received.
  curl --silent \
       --verbose \
       --connect-_timeout "${_timeout}" \
       --max-time "$(( _timeout + 1 ))" \
       "telnet://${_host}:${_port}" \
       >"${_tmp_out}" 2>&1 &
  _curl_pid="${!}"

  _connected=1
  _elapsed=0

  while (( _elapsed < _max_polls )); do
    if grep -q 'Connected to' "${_tmp_out}" 2>/dev/null; then
      _connected=0
      break
    fi
    sleep "${_poll_interval}"
    (( _elapsed += 1 ))
  done

  # Kill curl regardless of outcome — we have our answer
  kill "${_curl_pid}" 2>/dev/null
  wait "${_curl_pid}" 2>/dev/null

  return "${_connected}"
}
