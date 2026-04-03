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

[ -n "${_SHELLAC_LOADED_line_reverse_words+x}" ] && return 0
_SHELLAC_LOADED_line_reverse_words=1

# @description Reverse the order of words on a line.
#
# @arg $@ string One or more words to reverse
#
# @stdout Words in reversed order, space-separated
# @exitcode 0 Always
line_reverse_words() {
    local _reverse_words_word _reverse_words_output
    # shellcheck disable=SC2068 # We want word splitting here
    for _reverse_words_word in ${@}; do
        _reverse_words_output="${_reverse_words_word} ${_reverse_words_output}"
    done
    printf -- '%s\n' "${_reverse_words_output% }"
}
