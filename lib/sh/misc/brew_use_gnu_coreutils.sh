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

[ -n "${_SHELLAC_LOADED_misc_brew_use_gnu_coreutils+x}" ] && return 0
_SHELLAC_LOADED_misc_brew_use_gnu_coreutils=1

case "$(uname -s)" in
  (darwin)
    command -v brew >/dev/null 2>&1 || return 1
    PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
    MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
  ;;
  (*) return 1 ;;
esac

# Dirty way to do it:
# for coreutil in grep sed base64 shasum256; do
#     if command -v "g${coreutil}" &gt;/dev/null 2&gt;&amp;1; then
#       eval "${coreutil}() { command \"g${coreutil}\"  \"\${*}\"; }"
#     else
#       die "g${coreutil} not found"
#     fi
# done
