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
# Provenance: https://github.com/rawiriblundell/sh_libpath
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_crypto_random+x}" ] && return 0
_SHELLAC_LOADED_crypto_random=1

# @description Generate a numeric seed suitable for use with PRNG functions.
#   Prefers /dev/urandom+od, falls back to date +%s, then a portable shell calculation.
#
# @stdout A large positive integer suitable for use as a PRNG seed
# @exitcode 0 Always
random_seed() {
  # First we check if /dev/urandom is available.
  # We used to have a method_urandom.  /dev/urandom can generate numbers fast
  # But selecting numbers in ranges etc made for a fairly slow method
  if [ -c /dev/urandom ] && command -v od >/dev/null 2>&1; then
    # Get a string of bytes from /dev/urandom using od
    od -N 4 -A n -t uL /dev/urandom | tr -d '\n' | awk '{$1=$1+0};1'
  # Otherwise we try to get another seed
  elif date '+%s' >/dev/null 2>&1; then
    date '+%s'
  # Portable workaround based on http://www.etalabs.net/sh_tricks.html
  # We take extra steps to try to prevent accidental octal interpretation
  else
    local _secs_var _mins_var _hour_var _day_var _yr_offset _year_var
    _secs_var=$(TZ=GMT0 date +%S)
    _mins_var=$(TZ=GMT0 date +%M)
    _hour_var=$(TZ=GMT0 date +%H)
    _day_var=$(TZ=GMT0 date +%j | sed 's/^0*//')
    _yr_offset=$(( $(TZ=GMT0 date +%Y) - 1600 ))
    _year_var=$(( (_yr_offset * 365 + _yr_offset / 4 - _yr_offset / 100 + _yr_offset / 400 + _day_var - 135140) * 86400 ))
    printf -- '%s\n' "$(( _year_var + (${_hour_var#0} * 3600) + (${_mins_var#0} * 60) + ${_secs_var#0} ))"
  fi
}

# @description Generate random integers using a BSD-style Linear Congruential Generator.
#   Produces values in the range 0-32767, matching the range of $RANDOM.
#
# @arg $1 int Optional: count of numbers to generate (default: 1)
# @arg $2 int Optional: seed value (default: epoch seconds via random_seed)
#
# @stdout One random integer per line
# @exitcode 0 Always
random_lcg() {
  local _rn_count _rn_seed
  _rn_count="${1:-1}"
  _rn_seed="${2:-$(random_seed)}"

  # Here's an unnecessary nod to FreeBSD's rand.c
  if [ "${_rn_seed}" = 0 ]; then
    _rn_seed=123459876
  fi

  while (( _rn_count > 0 )); do
    # BSD style modulus'ed against 2^31
    _rn_seed=$(( (1103515245 * _rn_seed + 12345) % 2147483648 ))

    # Microsoft style
    #_rn_seed=$(( (214013 * _rn_seed + 2531011) % 2147483648 ))

    # print the generated number as an unsigned int (i.e. positive decimal)
    # Divided by 2^16
    printf -- '%u\n' "$(( _rn_seed / 65536 ))"

    _rn_count=$(( _rn_count - 1 ))
  done
}

# @description Generate random integers using xorshift128+ with debiased modulo.
#   Selects the word size automatically via getconf LONG_BIT.
#
# @arg $1 int Optional: count of numbers to generate (default: 1)
# @arg $2 int Optional: minimum value (default: 1)
# @arg $3 int Optional: maximum value (default: architecture max)
# @arg $4 int Optional: seed for seed1 (default: random_seed)
#
# @stdout One random integer per line within [min, max]
# @exitcode 0 Always
random_xorshift128plus() {
  local _n_count _n_min _n_max _max_rand _n_range
  local _seed0 _seed1 _int0 _int1 _skip_ints
  _n_count="${1:-1}"
  _n_min="${2:-1}"
  _seed0=4          # RFC 1149.5
  _seed1="${4:-$(random_seed)}"

  # Figure out our default max_rand, using 'getconf'
  case "$(getconf LONG_BIT 2>/dev/null)" in
    (64) _max_rand=9223372036854775807 ;;  # 2^63-1
    (32) _max_rand=2147483647 ;;           # 2^31-1
    (*)  _max_rand=32767 ;;               # 2^15-1
  esac

  _n_max="${3:-${_max_rand}}"
  _n_range=$(( _n_max - _n_min + 1 ))
  _int0="${_seed0}"
  _int1="${_seed1}"

  while (( _n_count > 0 )); do
    # This is required for modulo de-biasing
    # We figure out the number of problematic integers to skip
    # in order to bring modulo back into uniform alignment
    # This is significantly faster than naive rejection sampling
    #_skip_ints=$(( ((_max_rand % _n_max) + 1) % _n_max ))
    _skip_ints=$(( (_max_rand - _n_range) % _n_range ))

    # xorshift128+ with preselected triples
    _int1=$(( _int1 ^ _int1 << 23 ))
    _int1=$(( _int1 ^ _int1 >> 17 ))
    _int1=$(( _int1 ^ _int0 ))
    _int1=$(( _int1 ^ _int0 >> 26 ))
    _seed1="${_int1}"

    # If our generated int is larger than the number of problematic ints
    # then we can modulo it safely, otherwise drop it and generate again
    if (( (_seed0 + _seed1) > _skip_ints )); then
      #printf -- '%u\n' "$(( ((_seed0 + _seed1) % _n_max) + 1 ))"
      printf -- '%u\n' "$(( ((_seed0 + _seed1) % _n_range) + _n_min ))"
      (( _n_count-- ))
    fi
  done
}

# @description Generate random integers using $RANDOM with debiased modulo.
#
# @arg $1 int Optional: count of numbers to generate (default: 1)
# @arg $2 int Optional: minimum value inclusive (default: 1)
# @arg $3 int Optional: maximum value inclusive (default: 32767)
#
# @stdout One random integer per line within [min, max]
# @exitcode 0 Success
# @exitcode 3 min equals max (zero-range)
random_int() {
  local _n_count _n_min _n_max _n_mod _rand_thres _i _x_int
  _n_count="${1:-1}"
  _n_min="${2:-1}"
  _n_max="${3:-32767}"
  _n_mod=$(( _n_max - _n_min + 1 ))
  if (( _n_min >= _n_max )); then return 3; fi
  # De-bias the modulo as best as possible
  _rand_thres=$(( -(32768 - _n_mod) % _n_mod ))
  if (( _rand_thres < 0 )); then
    (( _rand_thres = _rand_thres * -1 ))
  fi
  _i=0
  while (( _i < _n_count )); do
    _x_int="${RANDOM}"
    if (( _x_int > ${_rand_thres:-0} )); then
      printf -- '%d\n' "$(( _x_int % _n_mod + _n_min ))"
      (( _i += 1 ))
    fi
  done
}
