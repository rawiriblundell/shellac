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

[ -n "${_SHELLAC_LOADED_net_query+x}" ] && return 0
_SHELLAC_LOADED_net_query=1

# Public IP reflection services (for net_query_ip):
# http https IPv DNS
#            4 6
# y    y     4 6 -   ifconfig.co/
# y    *     4 n -   whatismyip.akamai.com/ # cert may not match
# y    y     4 6 -   icanhazip.com/
# y    y     4 n -   ipinfo.io/ip
# y    y     4 6 -   ifconfig.me/
# y    y     4 n -   echoip.xyz/
# -    -     4 6 y   ns1.google.com. o-o.myaddr.l.google.com. TXT
# -    -     4 6 y   resolver1.opendns.com. myip.opendns.com. A

# @description Query the public/external IP address of this host using a
#   reflection service. For the local IP address, use net_query_ip instead.
#
# @arg $1 string Optional: '-6' for IPv6 (default: IPv4)
#
# @stdout The public IP address
# @exitcode 0 Success
# @exitcode 1 curl failed
net_query_ip() {
  case "${1}" in
    (-6) curl -s -6 ifconfig.io ;;
    (*)  curl -s -4 ifconfig.io ;;
  esac
}

# @description Look up geo and network metadata for an IP address or hostname
#   using ipinfo.io. Requires IPINFO_TOKEN to be set in the environment.
#
# @arg $1 string Optional: '-b' or '--brief' for country code only
# @arg $2 string IP address or hostname to look up (default: caller's public IP)
#
# @example
#   net_query_ipinfo 8.8.8.8
#   net_query_ipinfo --brief 8.8.8.8
#
# @stdout JSON metadata, or 'IP: COUNTRY' in brief mode
# @exitcode 0 Success
# @exitcode 1 IPINFO_TOKEN not set
net_query_ipinfo() {
  local _target _mode _country
  (( "${#IPINFO_TOKEN}" == 0 )) && {
    printf -- '%s\n' "IPINFO_TOKEN not found in the environment" >&2
    return 1
  }
  while (( $# > 0 )); do
    case "${1}" in
      (-b|--brief) _mode=brief; shift 1 ;;
      (*)          _target="${1}"; shift 1 ;;
    esac
  done
  case "${_mode}" in
    (brief)
      _country=$(curl -s "https://ipinfo.io/${_target}/_country?token=${IPINFO_TOKEN}")
      printf -- '%s: %s\n' "${_target}" "${_country}"
    ;;
    (*)
      curl -s "https://ipinfo.io/${_target}?token=${IPINFO_TOKEN}"
    ;;
  esac
}

# @description Return the HTTP status code for a URL.
#
# @arg $1 string URL to query
#
# @stdout HTTP status code (e.g. 200, 404)
# @exitcode 0 curl succeeded
# @exitcode 1 curl failed
net_query_http_code() {
  curl ${CURL_OPTS} --silent --output /dev/null --write-out '%{http_code}' \
    "${1:?No URI specified}"
}

# @description Fetch AS numbers for a given search term from bgpview.io.
#
# @arg $1 string Search term (e.g. organisation name or IP)
#
# @stdout AS numbers, one per line
# @exitcode 0 Always
net_query_as_numbers() {
  curl -s "https://bgpview.io/search/${1:?No search term specified}" |
    awk -F '[><]' '/bgpview.io\/asn/{print $5}'
}

# @description Pull ASN info from riswhois.ripe.net for one or more AS numbers.
#
# @arg $@ string One or more AS numbers
#
# @stdout whois output with blank/comment lines stripped
# @exitcode 0 Always
net_query_asn_attr() {
  local _as_num
  for _as_num in "${@:?No AS number supplied}"; do
    whois -H -h riswhois.ripe.net -- -F -K -i "${_as_num}" | grep -Ev '^$|^%|::'
  done
}

# @description Parse a URL into its component parts.
#   With one argument, prints all components as key: value lines.
#   With a second argument, prints only the requested field.
#   Default ports are inferred for http, https, mysql, redis if not explicitly set.
#
# @arg $1 string URL to parse (e.g. "https://user:pw@example.com:8080/some/path")
# @arg $2 string Optional field: proto user pass host port path
#
# @example
#   net_parse_url 'https://user:pw@host.com:8080/path' host   # => host.com
#   net_parse_url 'https://example.com/foo' port               # => 443
#
# @stdout Requested field value, or all fields as key: value lines
# @exitcode 0 Success
# @exitcode 1 Unknown field selector
# @exitcode 2 Missing argument
# Adapted from kvz/bash3boilerplate (MIT) https://github.com/kvz/bash3boilerplate
# Original author: Kevin van Zonneveld
net_parse_url() {
  local _url _proto _userpass _user _pass _hostport _host _port _path _need

  (( ${#} == 0 )) && { printf -- '%s\n' "net_parse_url: missing argument" >&2; return 2; }

  _url="${1}"
  _need="${2:-}"

  _proto=""
  _userpass=""
  _user=""
  _pass=""
  _host=""
  _port=""
  _path=""

  if [[ "${_url}" = *"://"* ]]; then
    _proto="${_url%%://*}://"
    _url="${_url#*://}"
  fi

  if [[ "${_url}" = *"@"* ]]; then
    _userpass="${_url%%@*}"
    _url="${_url#*@}"
  fi

  _hostport="${_url%%/*}"
  if [[ "${_url}" = */* ]]; then
    _path="${_url#*/}"
  fi

  if [[ "${_userpass}" = *":"* ]]; then
    _user="${_userpass%%:*}"
    _pass="${_userpass#*:}"
  else
    _user="${_userpass}"
  fi

  if [[ "${_hostport}" = *":"* ]]; then
    _host="${_hostport%%:*}"
    _port="${_hostport#*:}"
  else
    _host="${_hostport}"
  fi

  [[ -z "${_user}" ]] && _user="${_userpass}"
  [[ -z "${_host}" ]] && _host="${_hostport}"

  if [[ -z "${_port}" ]]; then
    case "${_proto}" in
      (http://)  _port="80"   ;;
      (https://) _port="443"  ;;
      (mysql://) _port="3306" ;;
      (redis://) _port="6379" ;;
      (*) ;;
    esac
  fi

  if [[ -n "${_need}" ]]; then
    case "${_need}" in
      (_proto|_user|_pass|_host|_port|_path)
        printf -- '%s\n' "${!_need}"
      ;;
      (*)
        printf -- 'net_parse_url: unknown field selector: %s\n' "${_need}" >&2
        return 1
      ;;
    esac
  else
    printf -- '_proto: %s\n' "${_proto}"
    printf -- '_user:  %s\n' "${_user}"
    printf -- '_pass:  %s\n' "${_pass}"
    printf -- '_host:  %s\n' "${_host}"
    printf -- '_port:  %s\n' "${_port}"
    printf -- '_path:  %s\n' "${_path}"
  fi
}
