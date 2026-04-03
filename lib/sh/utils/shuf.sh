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
# Provenance: https://raw.githubusercontent.com/rawiriblundell/dotfiles/master/.bashrc
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_utils_shuf+x}" ] && return 0
_SHELLAC_LOADED_utils_shuf=1

command -v shuf >/dev/null 2>&1 && return 0

# @description Step-in replacement for 'shuf' on systems that lack it.
#   Uses reservoir sampling for arbitrary-size input. Requires the random_int function
#   and a working $RANDOM. Note: this is a work in progress; -o (output file) is
#   not supported.
#
# @arg $1 string Optional flags: -e (echo mode), -i LO-HI (range), -n N (count),
#   -r (repeat), -h (help), -v (version)
# @arg $2 string File path or arguments (depending on mode)
#
# @stdout Shuffled lines or values
# @exitcode 0 Success
# @exitcode 1 RANDOM not available, conflicting options, or invalid argument
shuf() {
  local OPTIND input_range input_strings n_min n_max n_count shuf_array shuf_repeat
  local _idx
  local _rand_pos
  local reservoir_size

  # Test that $RANDOM is present and functioning as a pseudo-random source.
  # Two reads of $RANDOM should produce different values; a static variable
  # (e.g. RANDOM=5 in a shell without special $RANDOM support) would not.
  # Note: there is a 1/32768 chance of a false negative if both reads
  # happen to produce the same value, which is acceptable for this check.
  if ! (( RANDOM != RANDOM )); then
    printf -- '%s\n' "shuf: RANDOM global variable required but doesn't appear to be available" >&2
    return 1
  fi

  while getopts ":e:i:hn:rv:" opt_flags; do
    case "${opt_flags}" in
      (e) input_strings=true
          shuf_array=( "${OPTARG}" )
          until [[ $(eval "printf '%s' \"\${$OPTIND:0:1}\"") = "-" ]] || [[ -z $(eval "printf '%s' \"\${$OPTIND}\"") ]]; do
            # shellcheck disable=SC2207
            shuf_array+=($(eval "printf '%s' \"\${$OPTIND}\""))
            OPTIND=$((OPTIND + 1))
          done;;
      (h)  printf -- '%s\n' "" "shuf - generate random permutations" \
              "" "Options:" \
              "  -e, echo.                Treat each ARG as an input line" \
              "  -h, help.                Print a summary of the options" \
              "  -i, input-range LO-HI.   Treat each number LO through HI as an input line" \
              "  -n, count.               Output at most n lines" \
              "  -o, output FILE          This option is unsupported in this version, use '> FILE'" \
              "  -r, repeat               Output lines can be repeated" \
              "  -v, version.             Print the version information" ""
            return 0;;
      (i) input_range=true
          n_min="${OPTARG%-*}"
          n_max="${OPTARG##*-}"
          ;;
      (n) n_count="${OPTARG}";;
      (r) shuf_repeat=true;;
      (v)  printf -- '%s\n' "shuf.  This is a bashrc function knockoff that steps in if the real 'shuf' is not found."
           return 0;;
      (\?)  printf -- '%s\n' "shuf: invalid option -- '-$OPTARG'." \
              "Try -h for usage or -v for version info." >&2
            return 1;;
      (:)  printf -- '%s\n' "shuf: option '-$OPTARG' requires an argument, e.g. '-$OPTARG 5'." >&2
           return 1;;
    esac
  done
  shift "$(( OPTIND - 1 ))"

  # Handle -e and -i options.  They shouldn't be together because we can't
  # understand their love.  -e is handled later on in the script
  if [[ "${input_range}" = "true" ]] && [[ "${input_strings}" == "true" ]]; then
    printf -- '%s\n' "shuf: cannot combine -e and -i options" >&2
    return 1
  fi

  # Default the reservoir size
  # This number was unscientifically chosen using "feels right" technology
  reservoir_size=4096

  # If we're dealing with a file, feed that into file descriptor 6
  if [[ -r "${1}" ]]; then
    # Size it up first and adjust n_count if necessary
    if [[ -n "${n_count}" ]] && (( $(wc -l < "${1}") < n_count )); then
      n_count=$(wc -l < "${1}")
    fi
    exec 6< "${1}"
  # Cater for the -i option
  elif [[ "${input_range}" = "true" ]]; then
    # If an input range is provided and repeats are ok, then simply call random_int:
    if [[ "${shuf_repeat}" = "true" ]] && (( n_max <= 32767 )); then
      random_int "${n_count:-$n_max}" "${n_min}" "${n_max}"
      return "$?"
    # Otherwise, print a complete range to fd6 for later processing
    else
      exec 6< <(eval "printf -- '%d\\n' {$n_min..$n_max}")
    fi
  # If we're dealing with -e, we already have shuf_array
  elif [[ "${input_strings}" = "true" ]]; then
    # First, adjust n_count as appropriate
    if [[ -z "${n_count}" ]] || (( n_count > "${#shuf_array[@]}" )); then
      n_count="${#shuf_array[@]}"
    fi
    # If repeats are ok, just get it over and done with
    if [[ "${shuf_repeat}" = "true" ]] && (( n_count <= 32767 )); then
      for _idx in $(random_int "${n_count}" 1 "${#shuf_array[@]}"); do
        (( _idx-- ))
        printf -- '%s\n' "${shuf_array[_idx]}"
      done
      return "$?"
    # Otherwise, dump shuf_array into fd6
    else
      exec 6< <(printf -- '%s\n' "${shuf_array[@]}")
    fi
  # If none of the above things are in use, then we assume stdin
  else
    exec 6<&0
  fi

  # If we reach this point, then we need to setup our output filtering
  # We use this over a conventional loop, because loops are very slow
  # So, if n_count is defined, we pipe all output to 'head -n'
  # Otherwise, we simply stream via `cat` as an overglorified no-op
  if [[ -n "${n_count}" ]]; then
    head_out() { head -n "${n_count}"; }
  else
    head_out() { cat -; }
  fi

  # Start capturing everything for head_out()
  {
    # Turn off globbing for safety
    set -f

    # Suck up as much input as required or possible into the reservoir
    mapfile -u 6 -n "${n_count:-$reservoir_size}" -t shuf_array

    # If there's more input, we start selecting random points in
    # the reservoir to evict and replace with incoming data
    _idx="${#shuf_array[@]}"
    while IFS=$'\n' read -r -u 6; do
      _rand_pos=$(random_int 1 1 "$_idx")
      (( _rand_pos-- ))
      if (( _rand_pos < ${#shuf_array[@]} )); then
        printf -- '%s\n' "${shuf_array[_rand_pos]}"
        shuf_array[_rand_pos]="${REPLY}"
      else
        printf -- '%s\n' "${REPLY}"
      fi
      (( _idx++ ))
    done

    # At this point we very likely have something left in the reservoir
    # so we shuffle it out.  This is effectively Satollo's algorithm
    while (( ${#shuf_array[@]} > 0 )); do
      _rand_pos=$(random_int 1 1 "${#shuf_array[@]}")
      (( _rand_pos-- ))
      if (( _rand_pos < ${#shuf_array[@]} )) && [[ -n "${shuf_array[_rand_pos]}" ]]; then
        printf -- '%s\n' "${shuf_array[_rand_pos]}"
        unset -- 'shuf_array[_rand_pos]'
        # shellcheck disable=SC2206
        shuf_array=( "${shuf_array[@]}" )
      fi
    done
    set +f
  } | head_out
  exec 0<&6 6<&-
}
