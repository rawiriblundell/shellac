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

[ -n "${_SHELLAC_LOADED_sys_info+x}" ] && return 0
_SHELLAC_LOADED_sys_info=1

# @description Print the system hardware manufacturer.
#   On Linux: tries /sys/devices/virtual/dmi/id/sys_vendor, then dmidecode.
#   On Solaris: tries smbios. Falls back to "Generic or unknown".
#
# @stdout Manufacturer name
# @exitcode 0 Always
sys_info_manufacturer() {
  case "${OSSTR:-$(uname -s)}" in
    ([lL]inux)
      if [[ -s /sys/devices/virtual/dmi/id/sys_vendor ]]; then
        printf -- '%s\n' "$(< /sys/devices/virtual/dmi/id/sys_vendor)"
        return "${?}"
      fi
      if dmidecode 2>/dev/null | grep -q -m 1 "Manufacturer"; then
        dmidecode 2>/dev/null | awk -F ': ' '/Manufacturer/ { print $2; exit }'
        return "${?}"
      fi
      if dmidecode 2>/dev/null | grep -q -m 1 "Vendor"; then
        dmidecode 2>/dev/null | awk -F ': ' '/Vendor/ { print $2; exit }'
        return "${?}"
      fi
      printf -- 'Generic or unknown\n'
    ;;
    (SunOS|solaris)
      if command -v smbios >/dev/null 2>&1 && smbios -t SMB_TYPE_SYSTEM >/dev/null 2>&1; then
        smbios -t SMB_TYPE_SYSTEM |
          awk -F ': ' '/Manufacturer|Product/ { printf "%s ", $2 }' |
          awk '{$1=$1; print}'
        return "${?}"
      fi
      printf -- 'Sun Inc\n'
    ;;
  esac
}

# @description Print the system hardware model/product name.
#   On Linux: tries /sys/devices/virtual/dmi/id/product_name, then dmidecode.
#   On Solaris: uses uname -i. Falls back to "Generic or unknown".
#
# @stdout Model name
# @exitcode 0 Always
sys_info_model() {
  case "${OSSTR:-$(uname -s)}" in
    ([lL]inux)
      if [[ -s /sys/devices/virtual/dmi/id/product_name ]]; then
        printf -- '%s\n' "$(< /sys/devices/virtual/dmi/id/product_name)"
        return "${?}"
      fi
      if dmidecode 2>/dev/null | grep -q -m 1 "Product"; then
        dmidecode 2>/dev/null | awk -F ': ' '/Product/ { print $2; exit }'
        return "${?}"
      fi
      printf -- 'Generic or unknown\n'
    ;;
    (SunOS|solaris)
      uname -i | cut -d, -f2- | tr '-' ' '
    ;;
  esac
}

# @description Print the system serial number.
#   On Linux: tries /sys DMI, dmidecode, lshw, facter; falls back to UUID then
#   hostid. On Solaris: tries sneep, smbios, eeprom, ipmitool, prtfru, hostid.
#   A blank or literal "0" serial is treated as absent and the next fallback tried.
#
# @stdout Serial number string
# @exitcode 0 Always
sys_info_serial() {
  local _serial_number

  case "${OSSTR:-$(uname -s)}" in
    ([lL]inux)
      if [[ -s /sys/devices/virtual/dmi/id/product_serial ]]; then
        _serial_number="$(< /sys/devices/virtual/dmi/id/product_serial)"
      elif command -v dmidecode >/dev/null 2>&1; then
        _serial_number="$(dmidecode 2>/dev/null | awk -F ': ' '/Serial Number/ { print $2; exit }')"
      elif command -v lshw >/dev/null 2>&1; then
        _serial_number="$(lshw 2>/dev/null | awk -F ': ' '/serial/ { print $2; exit }')"
      elif command -v facter >/dev/null 2>&1; then
        _serial_number="$(facter 2>/dev/null | awk '/serialnumber/ { print $3 }')"
      fi

      if [[ -z "${_serial_number}" ]] || [[ "${_serial_number}" = "0" ]]; then
        _serial_number="$(dmidecode 2>/dev/null | awk -F ': ' '/UUID/ { print $2; exit }')"
        if [[ -z "${_serial_number}" ]] || [[ "${_serial_number}" = "0" ]]; then
          if command -v hostid >/dev/null 2>&1; then
            _serial_number="$(hostid)"
          fi
        fi
      fi
    ;;
    (SunOS|solaris)
      if command -v sneep >/dev/null 2>&1; then
        _serial_number="$(sneep)"
      elif smbios -t SMB_TYPE_SYSTEM >/dev/null 2>&1; then
        _serial_number="$(smbios -t SMB_TYPE_SYSTEM | awk '/Serial/ { print $3 }')"
        if [[ "${_serial_number}" = "0" ]] || [[ -z "${_serial_number}" ]]; then
          _serial_number="$(smbios -t SMB_TYPE_SYSTEM | awk '/UUID/ { print $2 }')"
        fi
      elif eeprom 2>/dev/null | grep -q ChassisSerialNumber; then
        _serial_number="$(eeprom | awk '/ChassisSerialNumber/ { print $3 }')"
      elif ipmitool fru >/dev/null 2>&1; then
        _serial_number="$(
          ipmitool fru print |
            grep -E 'Mainboard|/SYS' |
            awk '{ print $7 }' |
            cut -d ')' -f1 |
            awk '/Product Serial/ { print $4 }'
        )"
      elif command -v prtfru >/dev/null 2>&1; then
        _serial_number="sneep not found"
      else
        _serial_number="$(hostid)"
      fi
    ;;
  esac

  printf -- '%s\n' "${_serial_number:-Unknown}"
}

# @description Print BIOS vendor, version, and release date as a single line.
#   On Linux: uses dmidecode -t bios. On Solaris: uses prtdiag or smbios.
#
# @stdout Space-separated BIOS info string
# @exitcode 0 Always
sys_info_bios() {
  case "${OSSTR:-$(uname -s)}" in
    ([lL]inux)
      if command -v dmidecode >/dev/null 2>&1; then
        dmidecode -t bios 2>/dev/null |
          awk -F ': ' '/(Vendor|Version|Release Date)/ { printf "%s ", $2 }' |
          awk '{$1=$1; print}'
      fi
    ;;
    (SunOS|solaris)
      if command -v prtdiag >/dev/null 2>&1 && prtdiag >/dev/null 2>&1; then
        prtdiag -v | grep -E '^OBP|^BIOS'
        return "${?}"
      fi
      if smbios -t SMB_TYPE_BIOS >/dev/null 2>&1; then
        smbios -t SMB_TYPE_BIOS |
          awk -F ': ' '/Vendor|Version|Release/ { printf "%s ", $2 }' |
          awk '{$1=$1; print}'
        return "${?}"
      fi
      printf -- 'unknown\n'
    ;;
  esac
}

# @description Print hardware identity information. With no argument prints all
#   fields. Use a flag to select a single field.
#
# @arg $1 string Optional: --manufacturer, --model, --serial, --bios
#
# @example
#   sys_info
#   sys_info --serial
#
# @stdout Labelled hardware info (no-arg), or a single field value (with flag)
# @exitcode 0 Always
# @exitcode 1 Unrecognised argument
sys_info() {
  case "${1:-}" in
    (--manufacturer) sys_info_manufacturer ;;
    (--model)        sys_info_model ;;
    (--serial)       sys_info_serial ;;
    (--bios)         sys_info_bios ;;
    ('')
      printf -- 'Manufacturer: %s\n' "$(sys_info_manufacturer)"
      printf -- 'Model:        %s\n' "$(sys_info_model)"
      printf -- 'Serial:       %s\n' "$(sys_info_serial)"
      printf -- 'BIOS:         %s\n' "$(sys_info_bios)"
    ;;
    (*)
      printf -- 'Usage: sys_info [--manufacturer|--model|--serial|--bios]\n' >&2
      return 1
    ;;
  esac
}
