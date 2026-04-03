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

[ -n "${_SHELLAC_LOADED_sys_service+x}" ] && return 0
_SHELLAC_LOADED_sys_service=1

if command -v systemctl >/dev/null 2>&1; then
  # @description Start a named system service. Dispatches to systemctl, sysvinit,
  #   or init.d depending on what is available on the host.
  #
  # @arg $1 string Service name
  #
  # @exitcode 0 Service started successfully
  # @exitcode 1 No service specified or start failed
  svc_start() {
    /bin/systemctl start "${1:?No service specified}"
  }
  # @description Restart a named system service. Dispatches to systemctl, sysvinit,
  #   or init.d depending on what is available on the host.
  #
  # @arg $1 string Service name
  #
  # @exitcode 0 Service restarted successfully
  # @exitcode 1 No service specified or restart failed
  svc_restart() {
    /bin/systemctl restart "${1:?No service specified}"
  }
  # @description Check whether a named system service is currently active.
  #   Dispatches to systemctl, sysvinit, or init.d depending on availability.
  #
  # @arg $1 string Service name
  #
  # @exitcode 0 Service is active
  # @exitcode 1 Service is inactive or not found
  svc_status() {
    /bin/systemctl --quiet is-active "${1:?No service specified}"
  }

  # @description Check whether a systemd service unit is enabled.
  #
  # @arg $1 string Service name
  #
  # @exitcode 0 Service is enabled
  # @exitcode 1 Service is not enabled or not found
  svc_enabled() {
    systemctl list-unit-files | grep -q "${1:?svc unset}.*enabled"
  }

  # @description Check whether a systemd service unit is currently running.
  #
  # @arg $1 string Service name
  #
  # @exitcode 0 Service is running
  # @exitcode 1 Service is not running or not found
  svc_active() {
    systemctl | grep -q "${1:?svc unset}.service.*running"
  }

elif [[ -x /sbin/service ]]; then
  svc_start() {
    /sbin/service "${1:?No service specified}" start >/dev/null 2>&1
  }
  svc_restart() {
    /sbin/service "${1:?No service specified}" restart >/dev/null 2>&1
  }
  svc_status() {
    /sbin/service "${1:?No service specified}" status >/dev/null 2>&1
  }

elif [[ -d /etc/init.d ]]; then
  svc_start() {
    /etc/init.d/"${1:?No service specified}" start >/dev/null 2>&1
  }
  svc_restart() {
    /etc/init.d/"${1:?No service specified}" restart >/dev/null 2>&1
  }
  svc_status() {
    /etc/init.d/"${1:?No service specified}" status >/dev/null 2>&1
  }
  
else
  svc_start() {
    printf -- '%s\n' "No service specified, or service control method not found" >&2
  }
  svc_restart() {
    printf -- '%s\n' "No service specified, or service control method not found" >&2
  }
  svc_status() {
    printf -- '%s\n' "No service specified, or service control method not found" >&2
  }
fi

