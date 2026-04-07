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

[ -n "${_SHELLAC_LOADED_net_interface+x}" ] && return 0
_SHELLAC_LOADED_net_interface=1

# @description Get the local IP address of the host. Supports IPv4 (default)
#   and IPv6 via flags. Falls back through 'ip', 'ifconfig', and 'nslookup'.
#   Optionally scope to a specific interface. For the public/external IP
#   address, use net_query_ip instead.
#
# @arg $1 string Optional: '-4' for IPv4 (default); '-6' for IPv6
# @arg $2 string Optional: interface name to scope the query
#
# @example
#   net_ip           # => local IPv4 addresses
#   net_ip -6        # => local IPv6 addresses
#   net_ip -4 eth0   # => IPv4 addresses on eth0
#
# @stdout The IP address(es), one per line
# @exitcode 0 Success
# @exitcode 1 Could not determine address
net_ip() {
  # ifconfig outputs in either of these formats:
  # inet addr:192.168.2.1  Bcast:192.168.1.255  Mask:255.255.255.0
  # inet 172.19.243.193  netmask 255.255.240.0  broadcast 172.19.255.255
  # Both are handled by searching for 'inet' and stripping any 'addr:' prefix.
  local _family _iface
  _family=4
  case "${1:-}" in
    (-4) shift ;;
    (-6) _family=6; shift ;;
  esac
  _iface="${1:-}"

  if (( _family == 6 )); then
    if command -v ip >/dev/null 2>&1; then
      if [[ -n "${_iface}" ]]; then
        ip -o -6 addr show dev "${_iface}" 2>/dev/null | awk -F '[ /]' '{print $7}'
      else
        ip -o -6 a show up 2>/dev/null | awk -F '[ /]' '$2 != "lo" {print $7; exit}'
      fi
      return "${?}"
    elif command -v ifconfig >/dev/null 2>&1; then
      if [[ -n "${_iface}" ]]; then
        ifconfig "${_iface}" 2>/dev/null
      else
        ifconfig -a 2>/dev/null
      fi |
        sed -e '/^docker/{N;N;d;}' |
        awk '/inet6 / && $2 !~ /::1/ {print $2; exit}' |
        sed 's/addr://g'
      return "${?}"
    fi
    return 1
  fi

  # IPv4 path
  if command -v ip >/dev/null 2>&1; then
    if [[ -n "${_iface}" ]]; then
      ip -o -4 addr show dev "${_iface}" 2>/dev/null | awk -F '[ /]' '{print $7}'
    else
      ip -o -4 a show up 2>/dev/null | awk -F '[ /]' '$2 != "lo" {print $7}'
    fi
    return "${?}"
  elif command -v ifconfig >/dev/null 2>&1; then
    if [[ -n "${_iface}" ]]; then
      ifconfig "${_iface}" 2>/dev/null
    else
      ifconfig -a 2>/dev/null
    fi |
      sed -e '/^docker/{N;N;d;}' |
      awk '/inet / && $2 !~ /127.0.0.1/ {print $2; exit}' |
      sed 's/addr://g'
    return "${?}"
  fi

  # nslookup fallback — only useful for global (no interface specified) lookups
  if [[ -z "${_iface}" ]] && command -v nslookup >/dev/null 2>&1; then
    if nslookup "$(hostname)" 2>&1 |
         grep -E "Server failed|SERVFAIL|can't find" >/dev/null 2>&1; then
      printf -- '%s\n' "Could not determine the local IP address" >&2
      return 1
    else
      nslookup "$(hostname)" |
        awk -F ':' '/Address:/{gsub(/ /, "", $2); print $2}' |
        grep -v "#" |
        sed 's/^ *//g'
      return "${?}"
    fi
  fi

  return 1
}

# @description Get the default _gateway address. Optionally scoped to a specific
#   interface. Tries 'ip route', then 'netstat', then 'route' in order.
#   Handles Linux and Solaris differences via OSSTR.
#
# @arg $1 string Optional: interface name for per-interface _gateway lookup
#
# @stdout The _gateway IP, 'none' if no route exists, or 'unknown' if indeterminate
# @exitcode 0 On success or 'none' sentinel
# @exitcode 1 When interface specified but 'ip' is unavailable
net_gateway() {
  local _iface _get_gwaddr
  _iface="${1:-}"

  if [[ -n "${_iface}" ]]; then
    if command -v ip >/dev/null 2>&1; then
      _get_gwaddr=$(ip route show default dev "${_iface}" 2>/dev/null | awk '/^default/{print $3; exit}')
      if [[ -z "${_get_gwaddr}" ]]; then
        printf -- '%s\n' "none"
        return 0
      fi
      printf -- '%s\n' "${_get_gwaddr}"
      return 0
    fi
    printf -- '%s\n' "unknown"
    return 1
  fi

  # Global _gateway lookup
  if command -v ip >/dev/null 2>&1; then
    _get_gwaddr=$(ip route show | awk '/^default|^0.0.0.0/{ print $3 }')
  fi
  if [[ -z "${_get_gwaddr}" ]]; then
    case "${OSSTR:-$(uname -s)}" in
      (linux|Linux)
        _get_gwaddr=$(netstat -nrv | awk '/^default|^0.0.0.0/{ print $2; exit }')
      ;;
      (solaris|SunOS)
        _get_gwaddr=$(netstat -nrv | awk '/^default|^0.0.0.0/{ print $3; exit }')
      ;;
    esac
  fi
  if [[ -z "${_get_gwaddr}" ]]; then
    _get_gwaddr=$(route -n | awk '/^default|^0.0.0.0/{ print $2 }')
  fi
  printf -- '%s\n' "${_get_gwaddr}"
}

# @internal Normalise a MAC address to XX-YY-ZZ-AA-BB-CC format (uppercase).
_sanitise_mac_addr() {
  local _raw_mac _octet
  _raw_mac="${1:?No MAC data}"
  for _octet in ${_raw_mac}; do
    if (( ${#_octet} == 1 )); then
      printf -- '0%s-' "${_octet}"
    else
      printf -- '%s-' "${_octet}"
    fi
  done | tr '[:lower:]' '[:upper:]' | cut -d- -f1-6
}

# @description Get the MAC address of a network interface.
#   With no argument, returns the MAC of the primary UP interface.
#   With an interface name, returns the MAC of that specific interface.
#   Tries 'ip' first, then 'ifconfig', then 'dladm' (Solaris), then 'arp'.
#   ifconfig has unexplored issues in Azure/OpenShift.
#   AIX may need netstat -ia; HPUX may need lanscan.
#
# @arg $1 string Optional: interface name
#
# @stdout The MAC address in XX-YY-ZZ-AA-BB-CC format
# @exitcode 0 Always
net_mac() {
  local _mac_addr _raw_mac _iface
  _iface="${1:-}"

  if [[ -n "${_iface}" ]]; then
    if command -v ip >/dev/null 2>&1; then
      _mac_addr=$(ip -brief link show dev "${_iface}" 2>/dev/null | awk '{print $3}' | tr ':' '-')
    elif command -v ifconfig >/dev/null 2>&1; then
      _mac_addr=$(ifconfig "${_iface}" 2>/dev/null | awk '$0 ~ /HWaddr/ {print $5}' | tr ':' '-')
      if [[ -z "${_mac_addr}" ]]; then
        _mac_addr=$(ifconfig "${_iface}" 2>/dev/null | awk '$0 ~ /ether/ {print $2; exit}' | tr ':' '-')
      fi
    fi
    printf -- '%s\n' "${_mac_addr:--}"
    return 0
  fi

  # No interface specified: primary UP interface
  if command -v ip >/dev/null 2>&1; then
    _mac_addr=$(ip -brief link | awk '$2 == "UP" {print $3; exit}' | tr ":" "-")
  elif command -v ifconfig >/dev/null 2>&1; then
    _mac_addr=$(ifconfig | awk '$0 ~ /HWaddr/ {print $5}' | tr ":" "-" | head -n 1)
    # If we're here, then we might have a different ifconfig output format.  Yay.
    if [[ -z "${_mac_addr}" ]]; then
      _mac_addr=$(ifconfig | awk '$0 ~ /ether/ {print $2; exit}' | tr ":" "-")
    fi
  # Solaris
  elif command -v dladm >/dev/null 2>&1; then
    _mac_addr=$(dladm show-linkprop -p mac-address | awk '/^LINK/{print $4; exit}' | tr ":" " ")
  elif arp "$(hostname)" >/dev/null 2>&1; then
    _raw_mac=$(arp "$(hostname)" | awk '{ print $4 }' | tr ":" " ")
    _mac_addr=$(_sanitise_mac_addr "${_raw_mac}")
  fi
  printf -- '%s\n' "${_mac_addr}"
}

# @internal Check if an interface is a loopback device.
_net_nics_is_loopback() {
  local _iface _iftype
  _iface="${1:?}"
  if [[ -r "/sys/class/net/${_iface}/type" ]]; then
    _iftype=$(< "/sys/class/net/${_iface}/type")
    (( _iftype == 772 )) && return 0
  fi
  if command -v ip >/dev/null 2>&1; then
    ip link show dev "${_iface}" 2>/dev/null | grep -q 'LOOPBACK' && return 0
  fi
  return 1
}

# @internal Check if an interface is backed by physical hardware.
_net_nics_is_physical() {
  local _iface
  _iface="${1:?}"
  [[ -e "/sys/class/net/${_iface}/device" ]]
}

# @internal List interface names. Skips loopback unless _include_all=1.
_net_nics_list() {
  local _include_all _iface
  _include_all="${1:-0}"

  if [[ -d /sys/class/net ]]; then
    for _iface in /sys/class/net/*/; do
      _iface="${_iface%/}"
      _iface="${_iface##*/}"
      if (( _include_all == 0 )); then
        _net_nics_is_loopback "${_iface}" && continue
      fi
      printf -- '%s\n' "${_iface}"
    done
    return 0
  fi

  if command -v ip >/dev/null 2>&1; then
    while read -r _iface; do
      if (( _include_all == 0 )); then
        _net_nics_is_loopback "${_iface}" && continue
      fi
      printf -- '%s\n' "${_iface}"
    done < <(ip -o link show 2>/dev/null | awk -F': ' '{print $2}')
    return 0
  fi

  if command -v ifconfig >/dev/null 2>&1; then
    while read -r _iface; do
      if (( _include_all == 0 )); then
        _net_nics_is_loopback "${_iface}" && continue
      fi
      printf -- '%s\n' "${_iface}"
    done < <(ifconfig -a 2>/dev/null | awk '/^[a-zA-Z]/{gsub(/:/,"",$1); print $1}')
    return 0
  fi

  return 1
}

# @internal Return the ifindex for an interface.
_net_nics_index() {
  local _iface
  _iface="${1:?}"
  if [[ -r "/sys/class/net/${_iface}/ifindex" ]]; then
    printf -- '%s\n' "$(<"/sys/class/net/${_iface}/ifindex")"
    return 0
  fi
  if command -v ip >/dev/null 2>&1; then
    ip link show dev "${_iface}" 2>/dev/null | awk -F: 'NR==1{print $1+0; exit}'
    return 0
  fi
  printf -- '%s\n' "-"
}

# @internal Return the operational _state of an interface (uppercased).
_net_nics_state() {
  local _iface _state
  _iface="${1:?}"
  if [[ -r "/sys/class/net/${_iface}/operstate" ]]; then
    _state=$(< "/sys/class/net/${_iface}/operstate")
    printf -- '%s\n' "${_state}" | tr '[:lower:]' '[:upper:]'
    return 0
  fi
  if command -v ip >/dev/null 2>&1; then
    _state=$(ip link show dev "${_iface}" 2>/dev/null |
      awk '{for(i=1;i<=NF;i++) if($i=="state"){print $(i+1); exit}}')
    printf -- '%s\n' "${_state:-unknown}"
    return 0
  fi
  printf -- '%s\n' "unknown"
}

# @internal Return the MTU for an interface.
_net_nics_mtu() {
  local _iface
  _iface="${1:?}"
  if [[ -r "/sys/class/net/${_iface}/_mtu" ]]; then
    printf -- '%s\n' "$(<"/sys/class/net/${_iface}/_mtu")"
    return 0
  fi
  if command -v ip >/dev/null 2>&1; then
    ip link show dev "${_iface}" 2>/dev/null |
      awk '{for(i=1;i<=NF;i++) if($i=="mtu"){print $(i+1); exit}}'
    return 0
  fi
  printf -- '%s\n' "-"
}

# @internal Return the link _speed and _duplex for an interface.
#   Reads /sys/class/net first, falls back to ethtool. Returns '-' if unknown.
_net_nics_speed() {
  local _iface _speed _duplex _eth_speed _eth_duplex
  _iface="${1:?}"
  if [[ -r "/sys/class/net/${_iface}/_speed" ]]; then
    _speed=$(< "/sys/class/net/${_iface}/_speed")
    # -1 = _speed not reported (common for virtual/loopback interfaces)
    if (( _speed > 0 )); then
      _duplex="-"
      if [[ -r "/sys/class/net/${_iface}/_duplex" ]]; then
        _duplex=$(< "/sys/class/net/${_iface}/_duplex")
      fi
      printf -- '%s Mb/s (%s _duplex)\n' "${_speed}" "${_duplex}"
      return 0
    fi
  fi
  if command -v ethtool >/dev/null 2>&1; then
    _eth_speed=$(ethtool "${_iface}" 2>/dev/null | awk '/Speed:/{print $2}')
    _eth_duplex=$(ethtool "${_iface}" 2>/dev/null | awk '/Duplex:/{print $2}')
    if [[ -n "${_eth_speed}" ]]; then
      printf -- '%s (%s _duplex)\n' "${_eth_speed}" "${_eth_duplex:--}"
      return 0
    fi
  fi
  printf -- '%s\n' "-"
}

# @internal Return DNS server(s) for an interface.
#   Tries resolvectl for per-interface DNS, then falls back to resolv.conf
#   (checked in multiple locations for different DNS implementations).
_net_nics_dns() {
  local _iface _dns_servers _resolv_file
  _iface="${1:?}"

  if command -v resolvectl >/dev/null 2>&1; then
    _dns_servers=$(resolvectl status "${_iface}" 2>/dev/null |
      awk '/DNS Servers:/{
        sub(/.*DNS Servers:[[:space:]]*/,"")
        n=split($0,a," ")
        s=""
        for(i=1;i<=n;i++) s = s (s?", ":"") a[i]
        print s
      }')
    if [[ -n "${_dns_servers}" ]]; then
      printf -- '%s\n' "${_dns_servers}"
      return 0
    fi
  fi

  for _resolv_file in \
    /etc/resolv.conf \
    /var/run/systemd/resolve/resolv.conf \
    /run/systemd/resolve/resolv.conf; do
    if [[ -r "${_resolv_file}" ]]; then
      _dns_servers=$(awk '/^nameserver/{s = s (s?", ":"") $2} END{print s}' "${_resolv_file}")
      if [[ -n "${_dns_servers}" ]]; then
        printf -- '%s (global)\n' "${_dns_servers}"
        return 0
      fi
    fi
  done

  printf -- '%s\n' "-"
}

# @internal Emit 'family addr/prefix (type)' lines for all addresses on an interface.
#   type is one of: dhcp, link, static.
_net_nics_addrs() {
  local _iface
  _iface="${1:?}"
  if command -v ip >/dev/null 2>&1; then
    ip -o addr show dev "${_iface}" 2>/dev/null |
      awk '{
        family = "inet"; addr = ""
        for (i = 1; i <= NF; i++) {
          if ($i == "inet" || $i == "inet6") { family = $i; addr = $(i+1); break }
        }
        if (addr == "") next
        type = ($0 ~ /dynamic/) ? "dhcp" : (addr ~ /^fe80:/) ? "link" : "static"
        print family, addr, "(" type ")"
      }'
    return 0
  fi
  return 1
}

# @internal Print a verbose labelled block for a single interface.
_net_nics_report() {
  local _iface _idx _state _iftype _mac _mtu _speed _gateway _dns
  local _addr_family _addr_cidr _addr_tag _addr_line
  local -a _ipv4_addrs _ipv6_addrs

  _iface="${1:?}"
  _idx=$(_net_nics_index "${_iface}")
  _state=$(_net_nics_state "${_iface}")

  if _net_nics_is_loopback "${_iface}"; then
    _iftype="loopback"
  elif _net_nics_is_physical "${_iface}"; then
    _iftype="physical"
  else
    _iftype="virtual"
  fi

  _mac=$(net_mac "${_iface}")
  _mtu=$(_net_nics_mtu "${_iface}")
  _speed=$(_net_nics_speed "${_iface}")
  _gateway=$(net_gateway "${_iface}")
  _dns=$(_net_nics_dns "${_iface}")

  _ipv4_addrs=()
  _ipv6_addrs=()
  while read -r _addr_family _addr_cidr _addr_tag; do
    if [[ "${_addr_family}" = "inet" ]]; then
      _ipv4_addrs+=( "${_addr_cidr} ${_addr_tag}" )
    else
      _ipv6_addrs+=( "${_addr_cidr} ${_addr_tag}" )
    fi
  done < <(_net_nics_addrs "${_iface}")

  printf -- '\n'
  printf -- 'Interface : %s (index %s)\n' "${_iface}" "${_idx}"
  printf -- '  %-12s: %s\n' "State"   "${_state}"
  printf -- '  %-12s: %s\n' "Type"    "${_iftype}"
  printf -- '  %-12s: %s\n' "MAC"     "${_mac:--}"
  printf -- '  %-12s: %s\n' "MTU"     "${_mtu}"
  printf -- '  %-12s: %s\n' "Speed"   "${_speed}"

  if (( ${#_ipv4_addrs[@]} == 0 )); then
    printf -- '  %-12s: %s\n' "IPv4" "-"
  else
    printf -- '  %-12s: %s\n' "IPv4" "${_ipv4_addrs[0]}"
    for _addr_line in "${_ipv4_addrs[@]:1}"; do
      printf -- '                %s\n' "${_addr_line}"
    done
  fi

  if (( ${#_ipv6_addrs[@]} == 0 )); then
    printf -- '  %-12s: %s\n' "IPv6" "-"
  else
    printf -- '  %-12s: %s\n' "IPv6" "${_ipv6_addrs[0]}"
    for _addr_line in "${_ipv6_addrs[@]:1}"; do
      printf -- '                %s\n' "${_addr_line}"
    done
  fi

  printf -- '  %-12s: %s\n' "Gateway" "${_gateway}"
  printf -- '  %-12s: %s\n' "DNS"     "${_dns}"
}

# @internal Print a single summary row for the brief table.
_net_nics_brief_line() {
  local _iface _state _mac _speed _first_ipv4 _extra_count _addr_family _addr_cidr _addr_tag

  _iface="${1:?}"
  _state=$(_net_nics_state "${_iface}")
  _mac=$(net_mac "${_iface}")
  _speed=$(_net_nics_speed "${_iface}")
  _speed="${_speed%% *}"

  _first_ipv4="-"
  _extra_count=0
  while read -r _addr_family _addr_cidr _addr_tag; do
    if [[ "${_addr_family}" = "inet" ]]; then
      if [[ "${_first_ipv4}" = "-" ]]; then
        _first_ipv4="${_addr_cidr}"
      else
        (( _extra_count++ ))
      fi
    fi
  done < <(_net_nics_addrs "${_iface}")

  if (( _extra_count > 0 )); then
    _first_ipv4="${_first_ipv4} (+${_extra_count} more)"
  fi

  printf -- '%-16s %-8s %-20s %-26s %s\n' \
    "${_iface}" "${_state}" "${_mac:--}" "${_first_ipv4}" "${_speed}"
}

# @description Print information about network interfaces on the host.
#   By default shows all non-loopback interfaces in verbose labelled blocks.
#
# @arg -a,--all    Include loopback interfaces
# @arg -b,--brief  Compact summary table instead of verbose blocks
# @arg [_iface...]  Limit output to named interfaces
#
# @example
#   net_nics              # => verbose blocks for all non-loopback interfaces
#   net_nics --brief      # => compact table
#   net_nics -a           # => include loopback
#   net_nics eth0 eth1    # => only eth0 and eth1
#
# @stdout Network interface details
# @exitcode 0 Always
net_nics() {
  local _include_all _show_brief _iface
  _include_all=0
  _show_brief=0

  while (( ${#} > 0 )); do
    case "${1}" in
      (-a|--all)   _include_all=1; shift ;;
      (-b|--brief) _show_brief=1; shift ;;
      (--)         shift; break ;;
      (-*)
        printf -- 'net_nics: unknown option: %s\n' "${1}" >&2
        return 1
      ;;
      (*) break ;;
    esac
  done

  local -a _iface_list
  if (( ${#} > 0 )); then
    _iface_list=( "${@}" )
  else
    readarray -t _iface_list < <(_net_nics_list "${_include_all}")
  fi

  if (( ${#_iface_list[@]} == 0 )); then
    printf -- 'net_nics: no interfaces found\n' >&2
    return 1
  fi

  if (( _show_brief )); then
    printf -- '%-16s %-8s %-20s %-26s %s\n' "NAME" "STATE" "MAC" "IPv4" "SPEED"
    printf -- '%s\n' "--------------------------------------------------------------------------------"
    for _iface in "${_iface_list[@]}"; do
      _net_nics_brief_line "${_iface}"
    done
  else
    for _iface in "${_iface_list[@]}"; do
      _net_nics_report "${_iface}"
    done
    printf -- '\n'
  fi
}

# @internal Return 0 if ${1} is in use (listening), non-zero if free, 2 if no tool found.
#   Selected at load time: ss (iproute2/Linux) -> netstat (portable) -> lsof (macOS/Linux).
#   Note: the bash /dev/tcp pseudo-device was not used here — it was unreliable in WSL2
#   and is not available in all shells or sandbox environments.
if command -v ss >/dev/null 2>&1; then
    _net_port_in_use() { ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${1}$"; }
elif command -v netstat >/dev/null 2>&1; then
    _net_port_in_use() { netstat -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${1}$"; }
elif command -v lsof >/dev/null 2>&1; then
    _net_port_in_use() { lsof -iTCP:"${1}" -sTCP:LISTEN 2>/dev/null | grep -q .; }
else
    _net_port_in_use() {
        printf -- 'net_next_port: no supported port-check tool found (ss, netstat, lsof)\n' >&2
        return 2
    }
fi

# @description Find the next available local port starting from a given number.
#   Uses the best available port-check tool (ss, netstat, or lsof).
#
# @arg $1 int Starting port number (default: 9000)
# @arg $2 int Number of ports to scan before giving up (default: 100)
#
# @example
#   net_next_port          # => 9000 (or next available above 9000)
#   net_next_port 8080 50
#
# @stdout The first available port number
# @exitcode 0 An available port was found
# @exitcode 1 No available port found within the scan range, or no tool available
net_next_port() {
  local _test_port _max_port _in_use
  _test_port="${1:-9000}"
  # Set an upper bound.  100 cycles should be plenty.
  _max_port="$(( _test_port + "${2:-100}" ))"
  while true; do
    if (( _test_port == _max_port )); then
      printf -- '%s\n' "net_next_port: no available port found in range" >&2
      return 1
    fi
    _net_port_in_use "${_test_port}"
    _in_use=$?
    if (( _in_use == 2 )); then
      return 1
    elif (( _in_use != 0 )); then
      printf -- '%d\n' "${_test_port}"
      break
    fi
    (( _test_port++ ))
  done
}
