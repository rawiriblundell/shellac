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
# Adapted from tomocafe/dotfiles (MIT) https://github.com/tomocafe/dotfiles
# Adapted from SpicyLemon/SpicyLemon (MIT) https://github.com/SpicyLemon/SpicyLemon
# Adapted from laoshaw/xsh-lib (MIT) https://github.com/laoshaw/xsh-lib

[ -n "${_SHELLAC_LOADED_numbers_math+x}" ] && return 0
_SHELLAC_LOADED_numbers_math=1

# @description Absolute value of an integer.
#
# @arg $1 int Integer (may be negative)
#
# @example
#   num_abs -5    # => 5
#   num_abs 3     # => 3
#
# @stdout Absolute value
# @exitcode 0 Always; 1 Missing or non-integer argument
num_abs() {
  local n
  n="${1:-}"
  [[ -z "${n}" ]] && { printf -- '%s\n' "num_abs: missing argument" >&2; return 1; }
  printf -- '%d' "${n}" >/dev/null 2>&1 || { printf -- '%s\n' "num_abs: not an integer: ${n}" >&2; return 1; }
  (( n < 0 )) && n=$(( -n ))
  printf -- '%d\n' "${n}"
}

# @description Return the lesser of two integers.
#
# @arg $1 int First integer
# @arg $2 int Second integer
#
# @example
#   num_min 3 7     # => 3
#   num_min -2 1    # => -2
#
# @stdout Smaller value
# @exitcode 0 Always; 1 Missing argument
num_min() {
  local a b
  a="${1:?num_min: missing first argument}"
  b="${2:?num_min: missing second argument}"
  if (( a <= b )); then
    printf -- '%d\n' "${a}"
  else
    printf -- '%d\n' "${b}"
  fi
}

# @description Return the greater of two integers.
#
# @arg $1 int First integer
# @arg $2 int Second integer
#
# @example
#   num_max 3 7     # => 7
#   num_max -2 1    # => 1
#
# @stdout Larger value
# @exitcode 0 Always; 1 Missing argument
num_max() {
  local a b
  a="${1:?num_max: missing first argument}"
  b="${2:?num_max: missing second argument}"
  if (( a >= b )); then
    printf -- '%d\n' "${a}"
  else
    printf -- '%d\n' "${b}"
  fi
}

# @description Integer modulo: a mod m.
#   Result has the same sign as the divisor (mathematical modulo).
#
# @arg $1 int Dividend
# @arg $2 int Divisor (must be non-zero)
#
# @example
#   num_modulo 10 3     # => 1
#   num_modulo -7 3     # => 2  (mathematical, not C-style)
#
# @stdout Modulo result
# @exitcode 0 Always; 1 Division by zero or missing argument
num_modulo() {
  local a m result
  a="${1:?num_modulo: missing dividend}"
  m="${2:?num_modulo: missing divisor}"
  (( m == 0 )) && { printf -- '%s\n' "num_modulo: division by zero" >&2; return 1; }
  result=$(( a % m ))
  # Adjust to mathematical modulo (result same sign as divisor)
  if (( result != 0 && (result < 0) != (m < 0) )); then
    result=$(( result + m ))
  fi
  printf -- '%d\n' "${result}"
}

# @description Clamp an integer to [min, max].
#
# @arg $1 int Value to clamp
# @arg $2 int Minimum bound (inclusive)
# @arg $3 int Maximum bound (inclusive)
#
# @example
#   num_clamp 15 0 10    # => 10
#   num_clamp -3 0 10    # => 0
#   num_clamp  5 0 10    # => 5
#
# @stdout Clamped value
# @exitcode 0 Always; 1 Missing argument
num_clamp() {
  local val lo hi
  val="${1:?num_clamp: missing value}"
  lo="${2:?num_clamp: missing minimum}"
  hi="${3:?num_clamp: missing maximum}"
  if (( val < lo )); then
    printf -- '%d\n' "${lo}"
  elif (( val > hi )); then
    printf -- '%d\n' "${hi}"
  else
    printf -- '%d\n' "${val}"
  fi
}
