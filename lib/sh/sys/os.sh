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

[ -n "${_SHELLAC_LOADED_sys_os+x}" ] && return 0
_SHELLAC_LOADED_sys_os=1

# Detect the OS and populate OS information variables.
# Sets OSSTR (short OS tag), OSVER (PRETTY_NAME-style version string),
# OS_DISTRO (mirrors ansible_distribution: Ubuntu, AlmaLinux, Debian ...),
# OS_FAMILY (mirrors ansible_os_family: RedHat, Debian, Suse ...),
# OS_ARCH (normalised arch: x86_64, aarch64, arm, x86, ppc64le, s390x, mips),
# OS, KERNEL, RELEASE, MACHTYPE, HOSTTYPE, OSBOOTTIME.
# Sets LC_ALL=C and LANG=C for consistent parsing (restored on exit).
# Provides open() and net_open_link() as platform-appropriate helpers
# (defined in core/open.sh and net/open_link.sh respectively).

_os_LC_ALL="${LC_ALL:-}"
_os_LANG="${LANG:-}"
LC_ALL=C
LANG=C
export LANG LC_ALL

OS=$(uname -s)
OSVER=$(uname -sr)  # default; overridden per-OS below where we can do better
OS_DISTRO=
OS_FAMILY=
OS_ARCH=

case "${OS}" in
    ("AIX")
        OSSTR="${OS} $(oslevel) ($(oslevel -r))"
        [ -z "${OSSTR}" ] && OSSTR=aix
        OSVER="AIX $(oslevel)"
    ;;
    ("Darwin")
        OSSTR=mac
        OSVER="$(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null)"
    ;;
    ("FreeBSD")
        OSSTR=freebsd
    ;;
    ("HP-UX")
        OSSTR=hpux
    ;;
    ("Linux"|"linux-gnu"|"GNU"*)
        OSSTR=linux

        # OSVER = PRETTY_NAME from os-release (systemd standard, ~2012+),
        # then lsb_release, then legacy files, then uname -sr fallback.
        # OS_DISTRO/OS_FAMILY extracted from the same file in one pass.
        _os_release=
        [ -f /etc/os-release ]     && _os_release=/etc/os-release
        [ -f /usr/lib/os-release ] && : "${_os_release:=/usr/lib/os-release}"
        if [ -n "${_os_release}" ]; then
            OSVER=$(awk -F= '/^PRETTY_NAME=/{gsub(/"/, "", $2); print $2}' "${_os_release}")
            _os_id=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2; exit}' "${_os_release}")
            unset -v _os_release
        elif command -v lsb_release >/dev/null 2>&1; then
            OSVER=$(lsb_release -sd 2>/dev/null)
        elif [ -f /etc/redhat-release ]; then
            OSVER=$(cat /etc/redhat-release)
        elif [ -f /etc/debian_version ]; then
            OSVER="Debian $(cat /etc/debian_version)"
        fi
        # uname -sr default stands if all of the above yield nothing

        # Map ID field to ansible_distribution / ansible_os_family equivalents
        case "${_os_id:-}" in
            (ubuntu)           OS_DISTRO=Ubuntu    ; OS_FAMILY=Debian    ;;
            (debian)           OS_DISTRO=Debian    ; OS_FAMILY=Debian    ;;
            (centos)           OS_DISTRO=CentOS    ; OS_FAMILY=RedHat    ;;
            (rhel)             OS_DISTRO=RedHat    ; OS_FAMILY=RedHat    ;;
            (almalinux)        OS_DISTRO=AlmaLinux ; OS_FAMILY=RedHat    ;;
            (amzn)             OS_DISTRO=Amazon    ; OS_FAMILY=RedHat    ;;
            (fedora)           OS_DISTRO=Fedora    ; OS_FAMILY=RedHat    ;;
            (opensuse*|sles*)  OS_DISTRO=openSUSE  ; OS_FAMILY=Suse      ;;
            (arch)             OS_DISTRO=Archlinux ; OS_FAMILY=Archlinux ;;
            (gentoo)           OS_DISTRO=Gentoo    ; OS_FAMILY=Gentoo    ;;
            (alpine)           OS_DISTRO=Alpine    ; OS_FAMILY=Alpine    ;;
            (*)                OS_DISTRO="${_os_id:-}"                   ;;
        esac
        unset -v _os_id
    ;;
    ("NetBSD")
        OSSTR=netbsd
    ;;
    ("OpenBSD")
        OSSTR=openbsd
    ;;
    ("SunOS"|"solaris")
        OSSTR=solaris
    ;;
    (*"BSD"|*"bsd"|"DragonFly"|"Bitrig")
        OSSTR=bsd
    ;;
    ("CYGWIN"* | "MSYS"* | "MINGW"*)
        OSSTR=windows
    ;;
    ("Haiku")
        OSSTR=haiku
    ;;
    ("MINIX")
        OSSTR=minix
    ;;
    ("IRIX64")
        OSSTR=irix
    ;;
    (*)
        OSSTR=$(uname -s)
    ;;
esac

who -b > /dev/null 2>&1 && OSBOOTTIME="$(who -b)"

[ -z "${KERNEL}" ]  && KERNEL=$(uname -r)
[ -z "${RELEASE}" ] && RELEASE="${KERNEL}"

# Machine Type - identifies the system hardware
# This typically displays CPU architecture e.g. i686, ia64, sparc etc
if [ -z "${MACHTYPE}" ]; then
    # -p works on Linux, Solaris and AIX
    if uname -p >/dev/null 2>&1; then
        MACHTYPE=$(uname -p)
        # It works on Linux etc until it doesn't
        [ "${MACHTYPE}" = 'unknown' ] && MACHTYPE=$(uname -m)
    # -p is not available on HP-UX, until I know better, we use -m
    elif uname -m >/dev/null 2>&1; then
        MACHTYPE=$(uname -m)
    fi
fi

[ -z "${HOSTTYPE}" ] && HOSTTYPE="${MACHTYPE}"

# Normalise MACHTYPE to a short portable arch tag
case "${MACHTYPE}" in
    (x86_64|amd64)     OS_ARCH=x86_64  ;;
    (i?86)             OS_ARCH=x86     ;;
    (aarch64|arm64)    OS_ARCH=aarch64 ;;
    (armv*|arm)        OS_ARCH=arm     ;;
    (ppc64le)          OS_ARCH=ppc64le ;;
    (s390x)            OS_ARCH=s390x   ;;
    (mips*)            OS_ARCH=mips    ;;
    (*)                OS_ARCH="${MACHTYPE}" ;;
esac

readonly OSSTR OSVER OSBOOTTIME OS_DISTRO OS_FAMILY OS_ARCH
export OSSTR OSVER OSBOOTTIME OS_DISTRO OS_FAMILY OS_ARCH
export HOSTTYPE KERNEL MACHTYPE OS RELEASE

LC_ALL="${_os_LC_ALL}"
LANG="${_os_LANG}"
export LANG LC_ALL
unset -v _os_LC_ALL _os_LANG
