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
# Provenance: https://github.com/rawiriblundell/sh_libpath
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_numbers_stats+x}" ] && return 0
_SHELLAC_LOADED_numbers_stats=1

# @description Sum a list of numbers from positional arguments or stdin.
#   Handles integers and floats. Non-numeric lines are silently skipped.
#   See also: sum() in numbers/sum.sh (integers only, legacy name).
#
# @arg $@ number Numbers to sum, or pipe one value per line via stdin
#
# @example
#   numbers_sum 1 2 3          # => 6
#   seq 1 100 | numbers_sum    # => 5050
#
# @stdout Sum of values (%g format — no trailing zeros)
# @exitcode 0 Always
numbers_sum() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    awk '/^-?[0-9]/{s += $1} END {printf "%g\n", s+0}'
  else
    printf -- '%s\n' "${@}" | awk '/^-?[0-9]/{s += $1} END {printf "%g\n", s+0}'
  fi
}

# @description Return the smallest value from a list of numbers.
#   Handles integers and floats. Accepts any number of values.
#   See also: num_min() in numbers/math.sh (pairwise, exactly two arguments).
#
# @arg $@ number Numbers to compare, or pipe one value per line via stdin
#
# @example
#   numbers_min 3 1 4 1 5 9    # => 1
#   seq 1 10 | numbers_min     # => 1
#
# @stdout Minimum value
# @exitcode 0 Always
# @exitcode 1 No input
numbers_min() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    awk 'NR==1{m=$1} /^-?[0-9]/{if($1<m) m=$1} END {if(NR>0) printf "%g\n",m; else exit 1}'
  else
    printf -- '%s\n' "${@}" | awk 'NR==1{m=$1} /^-?[0-9]/{if($1<m) m=$1} END {if(NR>0) printf "%g\n",m; else exit 1}'
  fi
}

# @description Return the largest value from a list of numbers.
#   Handles integers and floats. Accepts any number of values.
#   See also: num_max() in numbers/math.sh (pairwise, exactly two arguments).
#
# @arg $@ number Numbers to compare, or pipe one value per line via stdin
#
# @example
#   numbers_max 3 1 4 1 5 9    # => 9
#   seq 1 10 | numbers_max     # => 10
#
# @stdout Maximum value
# @exitcode 0 Always
# @exitcode 1 No input
numbers_max() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    awk 'NR==1{m=$1} /^-?[0-9]/{if($1>m) m=$1} END {if(NR>0) printf "%g\n",m; else exit 1}'
  else
    printf -- '%s\n' "${@}" | awk 'NR==1{m=$1} /^-?[0-9]/{if($1>m) m=$1} END {if(NR>0) printf "%g\n",m; else exit 1}'
  fi
}

# @description Compute the arithmetic mean of a list of numbers.
#   Handles integers and floats.
#   See also: average() in numbers/sum.sh (legacy name).
#
# @arg $@ number Numbers to average, or pipe one value per line via stdin
#
# @example
#   numbers_mean 1 2 3         # => 2
#   numbers_mean 1 2           # => 1.5
#   seq 1 10 | numbers_mean    # => 5.5
#
# @stdout Arithmetic mean (%g format — no trailing zeros)
# @exitcode 0 Always
# @exitcode 1 No input
numbers_mean() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    awk '/^-?[0-9]/{s += $1; n++} END {if(n>0) printf "%g\n",s/n; else exit 1}'
  else
    printf -- '%s\n' "${@}" | awk '/^-?[0-9]/{s += $1; n++} END {if(n>0) printf "%g\n",s/n; else exit 1}'
  fi
}

# @description Compute the median of a list of numbers.
#   For an odd count, returns the middle value. For an even count, returns
#   the mean of the two middle values.
#
# @arg $@ number Numbers, or pipe one value per line via stdin
#
# @example
#   numbers_median 3 1 4 1 5   # => 3
#   numbers_median 1 2 3 4     # => 2.5
#
# @stdout Median value (%g format)
# @exitcode 0 Always
# @exitcode 1 No input
numbers_median() {
  local _prog
  _prog='BEGIN{n=0}
    /^-?[0-9]/{a[n++]=$1}
    END {
      if (n==0) exit 1
      mid = int(n/2)
      if (n%2 == 1) printf "%g\n", a[mid]
      else printf "%g\n", (a[mid-1]+a[mid])/2
    }'
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    sort -n | awk "${_prog}"
  else
    printf -- '%s\n' "${@}" | sort -n | awk "${_prog}"
  fi
}

# @description Return the most frequently occurring value in a list.
#   On a tie, returns the smallest value among those with the highest frequency.
#   Handles integers and floats.
#
# @arg $@ number Numbers, or pipe one value per line via stdin
#
# @example
#   numbers_mode 1 2 2 3 3 3   # => 3
#   numbers_mode 1 1 2 2       # => 1  (tie: smallest wins)
#
# @stdout Most frequent value
# @exitcode 0 Always
# @exitcode 1 No input
numbers_mode() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    awk '/^-?[0-9]/{count[$1]++}
      END {
        if (length(count)==0) exit 1
        max=0
        for (v in count) if (count[v]>max) max=count[v]
        for (v in count) if (count[v]==max) print v
      }' | sort -n | head -n 1
  else
    printf -- '%s\n' "${@}" | awk '/^-?[0-9]/{count[$1]++}
      END {
        if (length(count)==0) exit 1
        max=0
        for (v in count) if (count[v]>max) max=count[v]
        for (v in count) if (count[v]==max) print v
      }' | sort -n | head -n 1
  fi
}

# @description Compute the population standard deviation of a list of numbers.
#   Uses the one-pass variance formula: var = E[x²] - (E[x])².
#   For sample standard deviation (divides by N-1) use numbers_stdev_sample.
#
# @arg $@ number Numbers, or pipe one value per line via stdin
#
# @example
#   numbers_stdev 2 4 4 4 5 5 7 9   # => 2
#   numbers_stdev 1 2 3              # => 0.816497
#
# @stdout Population standard deviation (%g format)
# @exitcode 0 Always
# @exitcode 1 Fewer than one value provided
numbers_stdev() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    awk '/^-?[0-9]/{s+=$1; sq+=$1*$1; n++}
      END {
        if (n<1) exit 1
        var = sq/n - (s/n)^2
        printf "%g\n", sqrt(var < 0 ? 0 : var)
      }'
  else
    printf -- '%s\n' "${@}" | awk '/^-?[0-9]/{s+=$1; sq+=$1*$1; n++}
      END {
        if (n<1) exit 1
        var = sq/n - (s/n)^2
        printf "%g\n", sqrt(var < 0 ? 0 : var)
      }'
  fi
}

# @description Compute the sample standard deviation (Bessel's correction, divides by N-1).
#
# @arg $@ number Numbers, or pipe one value per line via stdin
#
# @example
#   numbers_stdev_sample 2 4 4 4 5 5 7 9   # => 2.13809
#
# @stdout Sample standard deviation (%g format)
# @exitcode 0 Always
# @exitcode 1 Fewer than two values provided
numbers_stdev_sample() {
  if (( ${#} == 0 )) && [[ ! -t 0 ]]; then
    awk '/^-?[0-9]/{s+=$1; sq+=$1*$1; n++}
      END {
        if (n<2) exit 1
        var = (sq - s*s/n) / (n-1)
        printf "%g\n", sqrt(var < 0 ? 0 : var)
      }'
  else
    printf -- '%s\n' "${@}" | awk '/^-?[0-9]/{s+=$1; sq+=$1*$1; n++}
      END {
        if (n<2) exit 1
        var = (sq - s*s/n) / (n-1)
        printf "%g\n", sqrt(var < 0 ? 0 : var)
      }'
  fi
}
