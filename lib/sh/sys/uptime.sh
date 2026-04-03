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

[ -n "${_SHELLAC_LOADED_sys_uptime+x}" ] && return 0
_SHELLAC_LOADED_sys_uptime=1

include time/epoch

case $(uname -s) in
    ("AIX"|"HP-UX")
        # @description Print system uptime in seconds. Defined per-OS in a case block;
        #   output format varies by platform (Linux: /proc/uptime format, BSD/macOS: epoch
        #   difference, AIX: parsed uptime string, Solaris: includes additional sysinfo).
        #
        # @stdout Uptime in seconds (platform-dependent format)
        # @exitcode 0 Always
        # Known uptime formats
        # 12:55pm  up 105 days, 21 hrs,  2 users, load average: 0.26, 0.26, 0.26 --> 9147600
        # 1:41pm   up 105 days, 21:46,   2 users, load average: 0.28, 0.28, 0.27 --> 9150360
        # 05:26PM  up           1:16,    1 user,  load average: 0.33, 0.21, 0.20 --> 4560
        # 06:13PM  up           2:03,    1 user,  load average: 1.16, 1.07, 0.91 --> 7380
        # 08:43AM  up 29 mins,           1 user,  load average: 0.09, 0.18, 0.21 --> 1740
        # 08:47AM  up 66 days,  18:34,   1 user,  load average: 2.25, 2.43, 2.61 --> 5769240
        # 08:45AM  up 76 days,  34 mins, 1 user,  load average: 2.25, 2.43, 2.61 --> 5769240
        get_uptime() {
            local LC_ALL LANG
            local _uptime _up_days _up_hours _up_mins
            LC_ALL=C
            LANG=C

            _uptime=$(uptime | sed -e 's/^.*up//g' -e 's/[0-9]* user.*//g')
            case ${_uptime} in
                ( *day* ) _up_days=$(printf -- '%s\n' "${_uptime}" | sed -e 's/days\{0,1\},.*//g') ;;
                ( * ) _up_days="0" ;;
            esac

            case ${_uptime} in
                ( *:* )
                    _up_hours=$(printf -- '%s\n' "${_uptime}" | sed -e 's/.*days\{0,1\},//g' -e 's/:.*//g')
                    _up_mins=$(printf -- '%s\n' "${_uptime}" | sed -e 's/.*days\{0,1\},//g' -e 's/.*://g' -e 's/,.*//g')
                ;;
                ( *hr* )
                    _up_hours=$(printf -- '%s\n' "${_uptime}" | sed -e 's/hrs\{0,1\},.*//g' -e 's/.*,//g')
                    _up_mins=0
                ;;
                ( *min* )
                    _up_hours=0
                    _up_mins=$(printf -- '%s\n' "${_uptime}" | sed -e 's/mins\{0,1\},.*//g' -e 's/.*hrs\{0,1\},//g' -e 's/.*days\{0,1\},//g')
                ;;
                ( * )
                    _up_hours="0"
                    _up_mins=0
                ;;
            esac

            printf -- '%s\n' "$(( (_up_days*86400)+(_up_hours*3600)+(_up_mins*60) ))"
        }
    ;;
    ("Darwin"|"NetBSD"|"OpenBSD")
        get_uptime() {
            printf -- '%s\n' "$(time_epoch) - $(sysctl -n kern.boottime | cut -d' ' -f 4,7 | tr ',' '.' | tr -d ' ')" | bc
        }
    ;;
    ("FreeBSD")
        get_uptime() {
            local _up_seconds _idle_seconds
            # Calculate the uptime in seconds since epoch compatible to /proc/uptime in linux
            _up_seconds=$(( $(time_epoch) - $(sysctl -n kern.boottime  | cut -f1 -d\, | awk '{print $4}') ))
            # pgrep is not appropriate (or even available?) here
            # shellcheck disable=SC2009
            _idle_seconds=$(ps axw | grep "[i]dle" | awk '/idle/{print $4}' | cut -f1 -d':' )
            printf -- '%s\n' "${_up_seconds} ${_idle_seconds}"
        }
    ;;
    ("Linux"|"linux-gnu"|"GNU"*)
        get_uptime() {
            if [ -f /.dockerenv ] || grep -q 'docker\|lxc' /proc/1/cgroup 2>/dev/null; then
                printf -- '%s\n' "$(($(time_epoch) - $(stat -c %Z /dev/pts)))"
            else
                cat /proc/uptime
            fi
        }
    ;;
    ("SunOS"|"solaris")
        get_uptime() {
            local LC_ALL LANG
            local _ctime _btime
            LC_ALL=C
            LANG=C

            # Solaris doesn't always give a consistent output on uptime, thus include side information
            # Tested in VM for solaris 10/11
            _ctime=$(nawk 'BEGIN{print srand()}')
            _btime=$(kstat '-p' 'unix:::boot_time' 2>&1|grep 'boot_time'|awk '{print $2}')
            printf -- '%s\n' "$(( _ctime - _btime ))"
            printf -- '%s\n' '[uptime_solaris_start]'
            uname -a
            zonename
            uptime
            kstat -p unix:0:system_misc:snaptime
            printf -- '%s\n' '[uptime_solaris_end]'
        }
    ;;
    (*)
        get_uptime() {
            local LC_ALL LANG
            local _boot_line _boot_str _boot_epoch
            LC_ALL=C
            LANG=C

            _boot_line=$(who -b 2>/dev/null) || return 1
            [ -z "${_boot_line}" ] && return 1

            # Detect ISO date (YYYY-MM-DD HH:MM) vs traditional (Mon DD HH:MM[SS])
            case "${_boot_line}" in
                (*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*)
                    _boot_str=$(printf -- '%s\n' "${_boot_line}" | awk '{print $(NF-1), $NF}')
                ;;
                (*)
                    _boot_str=$(printf -- '%s\n' "${_boot_line}" | awk '{print $(NF-2), $(NF-1), $NF}')
                ;;
            esac

            # Try GNU date -d (Linux), then BSD date -j with and without seconds
            _boot_epoch=$(date -d "${_boot_str}" +%s 2>/dev/null) ||
                _boot_epoch=$(date -j -f "%b %d %H:%M:%S" "${_boot_str}" +%s 2>/dev/null) ||
                _boot_epoch=$(date -j -f "%b %d %H:%M" "${_boot_str}" +%s 2>/dev/null) ||
                return 1

            printf -- '%s\n' "$(( $(time_epoch) - _boot_epoch ))"
        }
    ;;
esac
