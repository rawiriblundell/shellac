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
# Adapted from elibs/ebash (Apache-2.0) https://github.com/elibs/ebash

[ -n "${_SHELLAC_LOADED_core_save_function+x}" ] && return 0
_SHELLAC_LOADED_core_save_function=1

# @description Rename (copy) an existing function to a new name.
#   Useful for wrapping or overriding a function while preserving the original.
#   The original function body is copied to the new name via `declare -f` + eval.
#   Requires eval — there is no eval-free way to dynamically define a function
#   whose name is not known at parse time.
#
# @arg $1 string Existing function name (source)
# @arg $2 string New function name (destination)
#
# @example
#   # Wrap ls to always use --color
#   save_function ls _orig_ls
#   ls() { _orig_ls --color=auto "${@}"; }
#
# @exitcode 0 Success; 1 Source function does not exist; 2 Missing argument
save_function() {
  local _src _dst _body
  _src="${1:?save_function: missing source function name}"
  _dst="${2:?save_function: missing destination function name}"

  # Verify source exists
  if ! declare -f "${_src}" >/dev/null 2>&1; then
    printf -- '%s\n' "save_function: function not found: ${_src}" >&2
    return 1
  fi

  # Extract the function body and rewrite with new name via eval.
  # This is intentional metaprogramming — no alternative exists in bash
  # for runtime function renaming without eval.
  _body="$(declare -f "${_src}")"
  # Replace only the first occurrence of the function name (the definition line)
  # shellcheck disable=SC2086
  eval "${_dst}${_body#${_src}}"
}
