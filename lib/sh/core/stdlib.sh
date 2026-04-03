#!/bin/false
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

[ -n "${_SHELLAC_LOADED_core_stdlib+x}" ] && return 0
_SHELLAC_LOADED_core_stdlib=1

# @description Load a curated baseline set of shellac libraries.
#   Equivalent to a language stdlib — the functions you almost always
#   end up sourcing in any non-trivial script.
#
#   Requires: include() must already be available (i.e. source this via
#   'include core/stdlib', not by direct dot-sourcing).
#
#   The sentinel pattern on each library makes repeated inclusion free,
#   so loading stdlib alongside explicit includes is safe.
#
# @example
#   include core/stdlib
#
# @exitcode 0 All libraries loaded successfully
# @exitcode 1 One or more libraries failed to load

# --- Control flow & error handling ---
include core/die
include core/trap
include core/status

# --- Dependency checking ---
include core/requires
include core/wants

# --- Type and state predicates ---
include core/is
include core/types
include core/assert

# --- Shell & OS awareness ---
include sys/os
include sys/shell

# --- String basics ---
include text/trim
include text/predicates
include text/padding

# --- Numeric basics ---
include numbers/numeric

# --- Array basics ---
include array/contains
include array/join

# --- Structured output & logging ---
include utils/logging

# --- Resilience ---
include utils/retry_backoff
