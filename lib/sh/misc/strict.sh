# shellcheck shell=ksh

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

[ -n "${_SHELLAC_LOADED_misc_strict+x}" ] && return 0
_SHELLAC_LOADED_misc_strict=1

################################################################################
# Please read CONTRIBUTING and research the Unofficial Strict Mode's flaws

# @description Enable the Unofficial Strict Mode: errexit, errtrace, nounset, pipefail.
#   WARNING: This mode has well-known flaws. Read the project CONTRIBUTING guide
#   and research the risks before using it in production scripts.
#
# @exitcode 0 Always
strict_euopipefail() {
  set -o errexit
  set -o errtrace
  set -o nounset
  set -o pipefail
}

# @description Set IFS to tab and newline, disabling word splitting on spaces.
#
# @exitcode 0 Always
strict_nowhitesplitting() {
  IFS='\t\n'
}

# @description Enable a modernish-style 'safe' mode: empty IFS (no word splitting),
#   noglob (no pathname expansion), nounset (unset variable errors), and noclobber
#   (prevent accidental file overwriting with >). Inspired by modernish safe.mm.
#
# @exitcode 0 Always
strict_safe() {
  IFS=''
  set -o noglob
  set -o nounset
  set -o noclobber
}
