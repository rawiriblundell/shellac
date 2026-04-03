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

[ -n "${_SHELLAC_LOADED_net_cidr+x}" ] && return 0
_SHELLAC_LOADED_net_cidr=1

# @description Convert a CIDR prefix length to a dotted-decimal subnet mask.
#   Accepts the prefix with or without a leading slash (e.g. /24 or 24).
#
# @arg $1 string CIDR prefix length, e.g. 24 or /24
#
# @example
#   net_cidr_to_mask 24   # => 255.255.255.0
#   net_cidr_to_mask /16  # => 255.255.0.0
#
# @stdout The subnet mask in dotted-decimal notation
# @exitcode 0 Success
# @exitcode 1 No valid argument supplied
net_cidr_to_mask() {
  local _subnet_mask
  case "${1}" in
    (/32|32)  _subnet_mask="255.255.255.255" ;;
    (/31|31)  _subnet_mask="255.255.255.254" ;;
    (/30|30)  _subnet_mask="255.255.255.252" ;;
    (/29|29)  _subnet_mask="255.255.255.248" ;;
    (/28|28)  _subnet_mask="255.255.255.240" ;;
    (/27|27)  _subnet_mask="255.255.255.224" ;;
    (/26|26)  _subnet_mask="255.255.255.192" ;;
    (/25|25)  _subnet_mask="255.255.255.128" ;;
    (/24|24)  _subnet_mask="255.255.255.0" ;;
    (/23|23)  _subnet_mask="255.255.254.0" ;;
    (/22|22)  _subnet_mask="255.255.252.0" ;;
    (/21|21)  _subnet_mask="255.255.248.0" ;;
    (/20|20)  _subnet_mask="255.255.240.0" ;;
    (/19|19)  _subnet_mask="255.255.224.0" ;;
    (/18|18)  _subnet_mask="255.255.192.0" ;;
    (/17|17)  _subnet_mask="255.255.128.0" ;;
    (/16|16)  _subnet_mask="255.255.0.0" ;;
    (/15|15)  _subnet_mask="255.254.0.0" ;;
    (/14|14)  _subnet_mask="255.252.0.0" ;;
    (/13|13)  _subnet_mask="255.248.0.0" ;;
    (/12|12)  _subnet_mask="255.240.0.0" ;;
    (/11|11)  _subnet_mask="255.224.0.0" ;;
    (/10|10)  _subnet_mask="255.192.0.0" ;;
    (/9|9)    _subnet_mask="255.128.0.0" ;;
    (/8|8)    _subnet_mask="255.0.0.0" ;;
    (/7|7)    _subnet_mask="254.0.0.0" ;;
    (/6|6)    _subnet_mask="252.0.0.0" ;;
    (/5|5)    _subnet_mask="248.0.0.0" ;;
    (/4|4)    _subnet_mask="240.0.0.0" ;;
    (/3|3)    _subnet_mask="224.0.0.0" ;;
    (/2|2)    _subnet_mask="192.0.0.0" ;;
    (/1|1)    _subnet_mask="128.0.0.0" ;;
    (/0|0)    _subnet_mask="0.0.0.0" ;;
    ('')
        printf -- 'net_cidr_to_mask: %s\n' "Usage: net_cidr_to_mask [/int|int]" >&2
        return 1
    ;;
    (*)
        printf -- 'net_cidr_to_mask: %s\n' "unrecognized CIDR prefix: ${1}" >&2
        return 1
    ;;
  esac
  printf -- '%s\n' "${_subnet_mask}"
  return 0
}

# I found this function in my code attic from 2015!
# Far less readable than the above and not more efficient either...
#
# Function to convert CIDR subnet extensions to octal style e.g.
# 192.1.1.1/{24} = 192.1.1.1 {255.255.255.0}
# cdr2mask () {
#   # Number of args to shift, 255..255, first non-255 byte, zeroes
#   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
#   [ $1 -gt 1 ] && shift $1 || shift
#   echo ${1-0}.${2-0}.${3-0}.${4-0}
# }

# @description Print a table of all CIDR prefix lengths and their corresponding
#   subnet masks, from /32 down to /0.
#
# @stdout Formatted table of prefix lengths and subnet masks
# @exitcode 0 Always
net_cidr_table() {
  local _prefix_int
  for (( _prefix_int=32; _prefix_int>=0; _prefix_int-- )); do
    printf -- '%s\n' "+-----+-----------------+"
    printf -- '| /%-2s | %-15s |\n' "${_prefix_int}" "$(net_cidr_to_mask "${_prefix_int}")"
  done
  printf -- '%s\n' "+-----+-----------------+"
}

# @description Convert a dotted-decimal subnet mask to a CIDR prefix length.
#   The mask must be a valid contiguous subnet mask (e.g. 255.255.255.0).
#   Non-contiguous masks (e.g. 255.255.1.0) are rejected.
#
# @arg $1 string Dotted-decimal subnet mask, e.g. 255.255.255.0
#
# @example
#   net_mask_to_cidr 255.255.255.0   # => 24
#   net_mask_to_cidr 255.255.0.0     # => 16
#
# @stdout The CIDR prefix length as a plain integer
# @exitcode 0 Success
# @exitcode 1 Invalid or non-contiguous mask supplied
net_mask_to_cidr() {
  local _prefix
  case "${1}" in
    (255.255.255.255) _prefix=32 ;;
    (255.255.255.254) _prefix=31 ;;
    (255.255.255.252) _prefix=30 ;;
    (255.255.255.248) _prefix=29 ;;
    (255.255.255.240) _prefix=28 ;;
    (255.255.255.224) _prefix=27 ;;
    (255.255.255.192) _prefix=26 ;;
    (255.255.255.128) _prefix=25 ;;
    (255.255.255.0)   _prefix=24 ;;
    (255.255.254.0)   _prefix=23 ;;
    (255.255.252.0)   _prefix=22 ;;
    (255.255.248.0)   _prefix=21 ;;
    (255.255.240.0)   _prefix=20 ;;
    (255.255.224.0)   _prefix=19 ;;
    (255.255.192.0)   _prefix=18 ;;
    (255.255.128.0)   _prefix=17 ;;
    (255.255.0.0)     _prefix=16 ;;
    (255.254.0.0)     _prefix=15 ;;
    (255.252.0.0)     _prefix=14 ;;
    (255.248.0.0)     _prefix=13 ;;
    (255.240.0.0)     _prefix=12 ;;
    (255.224.0.0)     _prefix=11 ;;
    (255.192.0.0)     _prefix=10 ;;
    (255.128.0.0)     _prefix=9  ;;
    (255.0.0.0)       _prefix=8  ;;
    (254.0.0.0)       _prefix=7  ;;
    (252.0.0.0)       _prefix=6  ;;
    (248.0.0.0)       _prefix=5  ;;
    (240.0.0.0)       _prefix=4  ;;
    (224.0.0.0)       _prefix=3  ;;
    (192.0.0.0)       _prefix=2  ;;
    (128.0.0.0)       _prefix=1  ;;
    (0.0.0.0)         _prefix=0  ;;
    ('')
      printf -- 'net_mask_to_cidr: %s\n' "Usage: net_mask_to_cidr <dotted-decimal-mask>" >&2
      return 1
    ;;
    (*)
      printf -- 'net_mask_to_cidr: %s\n' "unrecognized mask: ${1}" >&2
      return 1
    ;;
  esac
  printf -- '%d\n' "${_prefix}"
}

# @description Print the total number of addresses in a subnet for a given
#   CIDR prefix length.  Accepts the prefix with or without a leading slash.
#   Note: /32 = 1 address (host route); /31 = 2 addresses (point-to-point,
#   RFC 3021); all others include network and broadcast addresses in the count.
#
# @arg $1 string CIDR prefix length, e.g. 24 or /24
#
# @example
#   net_subnet_size 24   # => 256
#   net_subnet_size /16  # => 65536
#
# @stdout Total address count as a plain integer
# @exitcode 0 Success
# @exitcode 1 No valid argument supplied
net_subnet_size() {
  local _size
  case "${1}" in
    (/32|32) _size=1          ;;
    (/31|31) _size=2          ;;
    (/30|30) _size=4          ;;
    (/29|29) _size=8          ;;
    (/28|28) _size=16         ;;
    (/27|27) _size=32         ;;
    (/26|26) _size=64         ;;
    (/25|25) _size=128        ;;
    (/24|24) _size=256        ;;
    (/23|23) _size=512        ;;
    (/22|22) _size=1024       ;;
    (/21|21) _size=2048       ;;
    (/20|20) _size=4096       ;;
    (/19|19) _size=8192       ;;
    (/18|18) _size=16384      ;;
    (/17|17) _size=32768      ;;
    (/16|16) _size=65536      ;;
    (/15|15) _size=131072     ;;
    (/14|14) _size=262144     ;;
    (/13|13) _size=524288     ;;
    (/12|12) _size=1048576    ;;
    (/11|11) _size=2097152    ;;
    (/10|10) _size=4194304    ;;
    (/9|9)   _size=8388608    ;;
    (/8|8)   _size=16777216   ;;
    (/7|7)   _size=33554432   ;;
    (/6|6)   _size=67108864   ;;
    (/5|5)   _size=134217728  ;;
    (/4|4)   _size=268435456  ;;
    (/3|3)   _size=536870912  ;;
    (/2|2)   _size=1073741824 ;;
    (/1|1)   _size=2147483648 ;;
    (/0|0)   _size=4294967296 ;;
    ('')
      printf -- 'net_subnet_size: %s\n' "Usage: net_subnet_size [/int|int]" >&2
      return 1
    ;;
    (*)
      printf -- 'net_subnet_size: %s\n' "unrecognized CIDR prefix: ${1}" >&2
      return 1
    ;;
  esac
  printf -- '%d\n' "${_size}"
}

# @description Derive the network address from an IP address and CIDR prefix.
#   Accepts combined notation (ip/prefix) or two separate arguments.
#
# @arg $1 string IP address with optional prefix (e.g. 192.168.1.50/24), or bare IP
# @arg $2 int    CIDR prefix length when not embedded in $1 (e.g. 24)
#
# @example
#   net_network_address 192.168.1.50/24   # => 192.168.1.0
#   net_network_address 10.0.3.7 8        # => 10.0.0.0
#
# @stdout Network address in dotted-decimal notation
# @exitcode 0 Success
# @exitcode 1 Missing argument
net_network_address() {
  local _ip _prefix _o1 _o2 _o3 _o4 _ip_int _mask _net

  case "${1}" in
    (*/*) _ip="${1%%/*}"; _prefix="${1##*/}" ;;
    (*)   _ip="${1}";     _prefix="${2}"     ;;
  esac

  if [[ -z "${_ip}" || -z "${_prefix}" ]]; then
    printf -- 'net_network_address: %s\n' "Usage: net_network_address <ip/prefix|ip prefix>" >&2
    return 1
  fi

  IFS=. read -r _o1 _o2 _o3 _o4 <<< "${_ip}"
  (( _ip_int = (_o1 << 24) | (_o2 << 16) | (_o3 << 8) | _o4 ))
  (( _mask   = (0xFFFFFFFF << (32 - _prefix)) & 0xFFFFFFFF ))
  (( _net    = _ip_int & _mask ))

  printf -- '%d.%d.%d.%d\n' \
    "$(( (_net >> 24) & 0xFF ))" \
    "$(( (_net >> 16) & 0xFF ))" \
    "$(( (_net >>  8) & 0xFF ))" \
    "$(( (_net      ) & 0xFF ))"
}

# @description Derive the broadcast address from an IP address and CIDR prefix.
#   Accepts combined notation (ip/prefix) or two separate arguments.
#
# @arg $1 string IP address with optional prefix (e.g. 192.168.1.50/24), or bare IP
# @arg $2 int    CIDR prefix length when not embedded in $1 (e.g. 24)
#
# @example
#   net_broadcast_address 192.168.1.50/24   # => 192.168.1.255
#   net_broadcast_address 10.0.3.7 8        # => 10.255.255.255
#
# @stdout Broadcast address in dotted-decimal notation
# @exitcode 0 Success
# @exitcode 1 Missing argument
net_broadcast_address() {
  local _ip _prefix _o1 _o2 _o3 _o4 _ip_int _mask _net _bcast

  case "${1}" in
    (*/*) _ip="${1%%/*}"; _prefix="${1##*/}" ;;
    (*)   _ip="${1}";     _prefix="${2}"     ;;
  esac

  if [[ -z "${_ip}" || -z "${_prefix}" ]]; then
    printf -- 'net_broadcast_address: %s\n' "Usage: net_broadcast_address <ip/prefix|ip prefix>" >&2
    return 1
  fi

  IFS=. read -r _o1 _o2 _o3 _o4 <<< "${_ip}"
  (( _ip_int = (_o1 << 24) | (_o2 << 16) | (_o3 << 8) | _o4 ))
  (( _mask   = (0xFFFFFFFF << (32 - _prefix)) & 0xFFFFFFFF ))
  (( _net    = _ip_int & _mask ))
  (( _bcast  = _net | (_mask ^ 0xFFFFFFFF) ))

  printf -- '%d.%d.%d.%d\n' \
    "$(( (_bcast >> 24) & 0xFF ))" \
    "$(( (_bcast >> 16) & 0xFF ))" \
    "$(( (_bcast >>  8) & 0xFF ))" \
    "$(( (_bcast      ) & 0xFF ))"
}
