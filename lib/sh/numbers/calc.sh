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

[ -n "${_SHELLAC_LOADED_numbers_calc+x}" ] && return 0
_SHELLAC_LOADED_numbers_calc=1

# @description Evaluate an arbitrary arithmetic expression using bc.
#   Input must be quoted or stored in a variable to avoid shell interpretation.
#
# @arg $@ string A quoted arithmetic expression
#
# @example
#   calc "4.2 + 2.6"         # => 6.8
#   calc "(4.2 + 2.6) - 3.5" # => 3.3
#
# @stdout Result of the expression
# @exitcode 0 Always
calc() { bc -l <<< "${*:?No input supplied}"; }
