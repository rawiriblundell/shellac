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
# Adapted from dylanaraps/pure-bash-bible (MIT) https://github.com/dylanaraps/pure-bash-bible

[ -n "${_SHELLAC_LOADED_numbers_bitwise+x}" ] && return 0
_SHELLAC_LOADED_numbers_bitwise=1

# @description Bitwise AND of two integers.
#
# @arg $1 int First operand
# @arg $2 int Second operand
#
# @stdout Result as a decimal integer
# @exitcode 0 Always
#
# @example
#   bitwise_and 6 3   # => 2
bitwise_and() {
    printf -- '%d\n' "$(( ${1} & ${2} ))"
}

# @description Bitwise OR of two integers.
#
# @arg $1 int First operand
# @arg $2 int Second operand
#
# @stdout Result as a decimal integer
# @exitcode 0 Always
#
# @example
#   bitwise_or 6 3   # => 7
bitwise_or() {
    printf -- '%d\n' "$(( ${1} | ${2} ))"
}

# @description Bitwise XOR of two integers.
#
# @arg $1 int First operand
# @arg $2 int Second operand
#
# @stdout Result as a decimal integer
# @exitcode 0 Always
#
# @example
#   bitwise_xor 6 3   # => 5
bitwise_xor() {
    printf -- '%d\n' "$(( ${1} ^ ${2} ))"
}

# @description Bitwise NOT (one's complement) of an integer.
#
# @arg $1 int Operand
#
# @stdout Result as a decimal integer
# @exitcode 0 Always
#
# @example
#   bitwise_not 6   # => -7
bitwise_not() {
    printf -- '%d\n' "$(( ~${1} ))"
}

# @description Left-shift an integer by N bits.
#
# @arg $1 int Value to shift
# @arg $2 int Number of bit positions to shift left
#
# @stdout Result as a decimal integer
# @exitcode 0 Always
#
# @example
#   bitwise_lshift 1 4   # => 16
bitwise_lshift() {
    printf -- '%d\n' "$(( ${1} << ${2} ))"
}

# @description Right-shift an integer by N bits.
#
# @arg $1 int Value to shift
# @arg $2 int Number of bit positions to shift right
#
# @stdout Result as a decimal integer
# @exitcode 0 Always
#
# @example
#   bitwise_rshift 16 4   # => 1
bitwise_rshift() {
    printf -- '%d\n' "$(( ${1} >> ${2} ))"
}
