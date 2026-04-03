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
# Adapted from juan131/bash-libraries (Apache-2.0) https://github.com/juan131/bash-libraries

[ -n "${_SHELLAC_LOADED_users_provision+x}" ] && return 0
_SHELLAC_LOADED_users_provision=1

# @description Return 0 if the given username exists on the system.
#
# @arg $1 string Username
#
# @exitcode 0 User exists; 1 Not found
user_exists() {
  id -- "${1:?user_exists: missing username}" >/dev/null 2>&1
}

# @description Return 0 if the given group name exists on the system.
#
# @arg $1 string Group name
#
# @exitcode 0 Group exists; 1 Not found
group_exists() {
  getent group -- "${1:?group_exists: missing group name}" >/dev/null 2>&1
}

# @description Ensure a group exists, creating it if it does not.
#   No-op if the group already exists (idempotent).
#
# @arg $1 string Group name
#
# @exitcode 0 Group exists (or was created); 1 Creation failed; 2 Missing argument
ensure_group_exists() {
  local group
  group="${1:?ensure_group_exists: missing group name}"
  group_exists "${group}" && return 0
  groupadd -- "${group}"
}

# @description Ensure a user exists, creating it if it does not.
#   No-op if the user already exists (idempotent).
#   Extra arguments are passed to useradd.
#
# @arg $1 string  Username
# @arg $@ string  Additional useradd arguments (e.g. -m, -s /bin/bash, -G wheel)
#
# @example
#   ensure_user_exists deploy -m -s /bin/bash -G wheel
#
# @exitcode 0 User exists (or was created); 1 Creation failed; 2 Missing argument
ensure_user_exists() {
  local username
  username="${1:?ensure_user_exists: missing username}"
  shift
  user_exists "${username}" && return 0
  useradd "${@}" -- "${username}"
}
