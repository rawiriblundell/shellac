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
# Original author: Marshall McMullen <marshall.mcmullen@gmail.com>

[ -n "${_SHELLAC_LOADED_text_collapse+x}" ] && return 0
_SHELLAC_LOADED_text_collapse=1

# @description Collapse all runs of whitespace in a string down to single spaces.
#   Leading and trailing whitespace is also collapsed (becomes a single space at each end
#   unless the input is already trimmed).
#
# @arg $@ string Text to collapse (may also be piped via stdin)
#
# @example
#   str_collapse "foo   bar     baz"   # => "foo bar baz"
#   printf 'a  b\tc\n' | str_collapse  # => "a b c"
#
# @stdout String with consecutive whitespace reduced to single spaces
# @exitcode 0 Always
str_collapse() {
  if (( ${#} > 0 )); then
    printf -- '%s\n' "$*" | tr -s '[:space:]' ' '
  else
    tr -s '[:space:]' ' '
  fi
}
