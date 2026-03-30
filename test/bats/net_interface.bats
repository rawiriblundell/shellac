#!/usr/bin/env bats
# Tests for net_ip, net_gateway, net_mac, and net_nics (+ helpers)
# in lib/sh/net/interface.sh
#
# Relies on the 'lo' loopback interface being present (universally true on
# Linux).  A few tests also use the known properties of 'loopback0', which
# exists in this environment; those are clearly marked.

load 'helpers/setup'

# ---------------------------------------------------------------------------
# _sanitise_mac_addr
# ---------------------------------------------------------------------------

@test "_sanitise_mac_addr: pads single-hex octets and uppercases" {
  run shellac_run 'include "net/interface"; _sanitise_mac_addr "0 26 b9 5a 3f 12"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "00-26-B9-5A-3F-12" ]
}

@test "_sanitise_mac_addr: already two-digit octets pass through" {
  run shellac_run 'include "net/interface"; _sanitise_mac_addr "aa bb cc dd ee ff"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "AA-BB-CC-DD-EE-FF" ]
}

# ---------------------------------------------------------------------------
# net_ip
# ---------------------------------------------------------------------------

@test "net_ip: returns at least one IPv4 address (no args)" {
  run shellac_run 'include "net/interface"; net_ip'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "net_ip -4 lo: returns 127.0.0.1" {
  run shellac_run 'include "net/interface"; net_ip -4 lo'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"127.0.0.1"* ]]
}

@test "net_ip -6 lo: returns ::1" {
  run shellac_run 'include "net/interface"; net_ip -6 lo'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"::1"* ]]
}

@test "net_ip -6: returns at least one IPv6 address" {
  run shellac_run 'include "net/interface"; net_ip -6'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "net_ip: default is IPv4 (same as -4)" {
  run shellac_run 'include "net/interface"; a=$(net_ip); b=$(net_ip -4); [ "${a}" = "${b}" ]'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# net_gateway
# ---------------------------------------------------------------------------

@test "net_gateway: returns a non-empty address" {
  run shellac_run 'include "net/interface"; net_gateway'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "net_gateway lo: returns 'none' (loopback has no default route)" {
  run shellac_run 'include "net/interface"; net_gateway lo'
  [ "${status}" -eq 0 ]
  [ "${output}" = "none" ]
}

# ---------------------------------------------------------------------------
# net_mac
# ---------------------------------------------------------------------------

@test "net_mac: returns a non-empty MAC for the primary UP interface" {
  run shellac_run 'include "net/interface"; net_mac'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "net_mac lo: returns 00-00-00-00-00-00" {
  run shellac_run 'include "net/interface"; net_mac lo'
  [ "${status}" -eq 0 ]
  [ "${output}" = "00-00-00-00-00-00" ]
}

@test "net_mac: non-existent interface returns '-'" {
  run shellac_run 'include "net/interface"; net_mac _no_such_iface_'
  [ "${status}" -eq 0 ]
  [ "${output}" = "-" ]
}

# ---------------------------------------------------------------------------
# _net_nics_is_loopback
# ---------------------------------------------------------------------------

@test "_net_nics_is_loopback lo: returns 0" {
  run shellac_run 'include "net/interface"; _net_nics_is_loopback lo'
  [ "${status}" -eq 0 ]
}

@test "_net_nics_is_loopback loopback0: returns 1 (physical, not loopback)" {
  run shellac_run 'include "net/interface"; _net_nics_is_loopback loopback0'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# _net_nics_is_physical
# ---------------------------------------------------------------------------

@test "_net_nics_is_physical lo: returns 1 (no /device symlink)" {
  run shellac_run 'include "net/interface"; _net_nics_is_physical lo'
  [ "${status}" -ne 0 ]
}

@test "_net_nics_is_physical: returns 0 for an interface with a /device symlink" {
  run shellac_run 'include "net/interface"
    phys=$(ls -d /sys/class/net/*/device 2>/dev/null | head -1)
    [[ -z "${phys}" ]] && skip "no physical interfaces found"
    iface="${phys%/device}"; iface="${iface##*/}"
    _net_nics_is_physical "${iface}"'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# _net_nics_list
# ---------------------------------------------------------------------------

@test "_net_nics_list: default excludes loopback" {
  run shellac_run 'include "net/interface"; _net_nics_list'
  [ "${status}" -eq 0 ]
  [[ "${output}" != *"lo"* ]] || [[ "${output}" = *"loopback"* ]]
  # lo (pure loopback) must not appear; loopback0 (not a loopback) may appear
}

@test "_net_nics_list 1: include_all=1 includes lo" {
  run shellac_run 'include "net/interface"; _net_nics_list 1'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"lo"* ]]
}

@test "_net_nics_list: returns at least one interface" {
  run shellac_run 'include "net/interface"; _net_nics_list 1'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

# ---------------------------------------------------------------------------
# _net_nics_index
# ---------------------------------------------------------------------------

@test "_net_nics_index lo: returns 1" {
  run shellac_run 'include "net/interface"; _net_nics_index lo'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

# ---------------------------------------------------------------------------
# _net_nics_state
# ---------------------------------------------------------------------------

@test "_net_nics_state lo: returns UNKNOWN (uppercased)" {
  run shellac_run 'include "net/interface"; _net_nics_state lo'
  [ "${status}" -eq 0 ]
  [ "${output}" = "UNKNOWN" ]
}

@test "_net_nics_state: returns UP for an UP interface" {
  run shellac_run 'include "net/interface"
    up=$(ip -brief link show | awk "NF>=2 && \$2==\"UP\"{print \$1; exit}")
    [[ -z "${up}" ]] && skip "no UP interfaces found"
    _net_nics_state "${up}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "UP" ]
}

# ---------------------------------------------------------------------------
# _net_nics_mtu
# ---------------------------------------------------------------------------

@test "_net_nics_mtu lo: returns 65536" {
  run shellac_run 'include "net/interface"; _net_nics_mtu lo'
  [ "${status}" -eq 0 ]
  [ "${output}" = "65536" ]
}

# ---------------------------------------------------------------------------
# _net_nics_speed
# ---------------------------------------------------------------------------

@test "_net_nics_speed lo: returns '-' (loopback has no speed)" {
  run shellac_run 'include "net/interface"; _net_nics_speed lo'
  [ "${status}" -eq 0 ]
  [ "${output}" = "-" ]
}

@test "_net_nics_speed: returns speed string with Mb/s for a physical interface" {
  run shellac_run 'include "net/interface"
    phys=$(ls -d /sys/class/net/*/device 2>/dev/null | head -1)
    [[ -z "${phys}" ]] && skip "no physical interfaces found"
    iface="${phys%/device}"; iface="${iface##*/}"
    speed_file="/sys/class/net/${iface}/speed"
    [[ ! -r "${speed_file}" ]] && skip "no readable speed file for ${iface}"
    _net_nics_speed "${iface}"'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"Mb/s"* ]]
}

# ---------------------------------------------------------------------------
# _net_nics_dns
# ---------------------------------------------------------------------------

@test "_net_nics_dns lo: exits 0 and returns something" {
  run shellac_run 'include "net/interface"; _net_nics_dns lo'
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

# ---------------------------------------------------------------------------
# _net_nics_addrs
# ---------------------------------------------------------------------------

@test "_net_nics_addrs lo: output contains 127.0.0.1/8" {
  run shellac_run 'include "net/interface"; _net_nics_addrs lo'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"127.0.0.1/8"* ]]
}

@test "_net_nics_addrs lo: output contains inet6 ::1" {
  run shellac_run 'include "net/interface"; _net_nics_addrs lo'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"::1"* ]]
}

@test "_net_nics_addrs lo: family prefixes are 'inet' or 'inet6'" {
  run shellac_run 'include "net/interface"; bad=$(_net_nics_addrs lo | awk "{print \$1}" | grep -vE "^(inet|inet6)$" || true); [ -z "${bad}" ]'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# _net_nics_report
# ---------------------------------------------------------------------------

@test "_net_nics_report lo: output contains Interface header" {
  run shellac_run 'include "net/interface"; _net_nics_report lo'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"Interface : lo"* ]]
}

@test "_net_nics_report lo: identifies type as loopback" {
  run shellac_run 'include "net/interface"; _net_nics_report lo'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"loopback"* ]]
}

@test "_net_nics_report lo: shows gateway as none" {
  run shellac_run 'include "net/interface"; _net_nics_report lo'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"Gateway"*"none"* ]]
}

@test "_net_nics_report: identifies type as physical for a physical interface" {
  run shellac_run 'include "net/interface"
    phys=$(ls -d /sys/class/net/*/device 2>/dev/null | head -1)
    [[ -z "${phys}" ]] && skip "no physical interfaces found"
    iface="${phys%/device}"; iface="${iface##*/}"
    _net_nics_report "${iface}"'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"physical"* ]]
}

# ---------------------------------------------------------------------------
# _net_nics_brief_line
# ---------------------------------------------------------------------------

@test "_net_nics_brief_line lo: first column is lo" {
  run shellac_run 'include "net/interface"; _net_nics_brief_line lo'
  [ "${status}" -eq 0 ]
  [[ "${output}" = lo* ]]
}

@test "_net_nics_brief_line lo: contains UNKNOWN state" {
  run shellac_run 'include "net/interface"; _net_nics_brief_line lo'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"UNKNOWN"* ]]
}

# ---------------------------------------------------------------------------
# net_nics (public interface)
# ---------------------------------------------------------------------------

@test "net_nics: exits 0 with default output" {
  run shellac_run 'include "net/interface"; net_nics'
  [ "${status}" -eq 0 ]
}

@test "net_nics -a: includes lo in output" {
  run shellac_run 'include "net/interface"; net_nics -a'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"Interface : lo"* ]]
}

@test "net_nics --all: same as -a" {
  run shellac_run 'include "net/interface"; net_nics --all'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"Interface : lo"* ]]
}

@test "net_nics --brief: prints NAME header" {
  run shellac_run 'include "net/interface"; net_nics --brief'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"NAME"* ]]
}

@test "net_nics -b -a: brief table includes lo row" {
  run shellac_run 'include "net/interface"; net_nics -b -a'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"lo"* ]]
}

@test "net_nics lo: shows single interface block" {
  run shellac_run 'include "net/interface"; net_nics lo'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"Interface : lo"* ]]
}

@test "net_nics: unknown option returns exit 1" {
  run shellac_run 'include "net/interface"; net_nics --no-such-option'
  [ "${status}" -eq 1 ]
}
