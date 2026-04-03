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

[ -n "${_SHELLAC_LOADED_crypto_genpasswd+x}" ] && return 0
_SHELLAC_LOADED_crypto_genpasswd=1

include "crypto/random"

# @description Generate random passwords when 'pwgen' or 'apg' are not available.
#   Supports standard alphanumeric, special character, and Koremutake phonetic syllable
#   modes. Options to require at least one digit, uppercase, or special character.
#
# @arg $1 string Optional flags: -c N (char count), -D (digit), -h (help), -K (Koremutake),
#   -n N (count), -s (strong), -S (stronger), -U (uppercase), -Y (special char)
#
# @stdout One or more generated passwords, one per line
# @exitcode 0 Success
# @exitcode 1 Invalid option or password length less than 4
secrets_genpasswd() {
  export LC_ALL=C LC_CTYPE=C
  # localise variables for safety
  local OPTIND _pwd_chars _pwd_digit _pwd_num _pwd_set _pwd_koremutake _pwd_upper \
    _pwd_special _pwd_special_chars _pwd_syllables _n _t _u _v _tmp_array

  # Default the vars
  _pwd_chars=10
  _pwd_digit="false"
  _pwd_num=1
  _pwd_set="[:alnum:]"
  _pwd_koremutake="false"
  _pwd_upper="false"
  _pwd_special="false"
  # shellcheck disable=SC1001
  _pwd_special_chars=(\! \@ \# \$ \% \^ \( \) \_ \+ \? \> \< \~)

  # Filtered koremutake syllables
  # http:#shorl.com/koremutake.php
  _pwd_syllables=( ba be bi bo bu by da de di 'do' du dy fe 'fi' fo fu fy ga ge \
    gi go gu gy ha he hi ho hu hy ja je ji jo ju jy ka ke ko ku ky la le li \
    lo lu ly ma me mi mo mu my na ne ni no nu ny pa pe pi po pu py ra re ri \
    ro ru ry sa se si so su sy ta te ti to tu ty va ve vi vo vu vy bra bre \
    bri bro bru bry dra dre dri dro dru dry fra fre fri fro fru fry gra gre \
    gri gro gru gry pra pre pri pro pru pry sta ste sti sto stu sty tra tre \
    er ed 'in' ex al en an ad or at ca ap el ci an et it ob of af au cy im op \
    co up ing con ter com per ble der cal man est 'for' mer col ful get low \
    son tle day pen pre ten tor ver ber can ple fer gen den mag sub sur men \
    min out tal but cit cle cov dif ern eve hap ket nal sup ted tem tin tro
  )

  while getopts ":c:DhKn:SsUY" Flags; do
    case "${Flags}" in
      (c)  _pwd_chars="${OPTARG}";;
      (D)  _pwd_digit="true";;
      (h)  printf -- '%s\n' "" "genpasswd - a poor sysadmin's pwgen" \
             "" "Usage: genpasswd [options]" "" \
             "Optional arguments:" \
             "-c [Number of characters. Minimum is 4. (Default:${_pwd_chars})]" \
             "-D [Require at least one digit (Default:off)]" \
             "-h [Help]" \
             "-K [Koremutake mode.  Uses syllables rather than characters, meaning more phonetical pwds." \
             "    Note: In this mode, character counts = syllable count and different defaults are used]" \
             "-n [Number of passwords (Default:${_pwd_num})]" \
             "-s [Strong mode, seeds a limited amount of special characters into the mix (Default:off)]" \
             "-S [Stronger mode, complete mix of characters (Default:off)]" \
             "-U [Require at least one uppercase character (Default:off)]" \
             "-Y [Require at least one special character (Default:off)]" \
             "" "Note1: Broken Pipe errors, (older bash versions) can be ignored" \
             "Note2: If you get umlauts, cyrillic etc, export LC_ALL= to something like en_US.UTF-8"
           return 0;;
      (K)  _pwd_koremutake="true";;
      (n)  _pwd_num="${OPTARG}";;
      # Attempted to randomise special chars using 7 random chars from [:punct:] but reliably
      # got "reverse collating sequence order" errors.  Seeded 9 special chars manually instead.
      (s)  _pwd_set="[:alnum:]#$&+/<}^%@";;
      (S)  _pwd_set="[:graph:]";;
      (U)  _pwd_upper="true";;
      (Y)  _pwd_special="true";;
      (\?)  printf -- '%s\n' "[ERROR] genpasswd: Invalid option: $OPTARG.  Try 'genpasswd -h' for usage." >&2
            return 1;;
      (:)  printf -- '%s\n' "[ERROR] genpasswd: Option '-${OPTARG}' requires an argument, e.g. '-${OPTARG} 5'." >&2
           return 1;;
    esac
  done

  # We need to check that the character length is more than 4 to protect against
  # infinite loops caused by the character checks.  i.e. 4 character checks on a 3 character password
  if (( _pwd_chars < 4 )); then
    printf -- '%s\n' "[ERROR] genpasswd: Password length must be greater than four characters." >&2
    return 1
  fi

  if [[ "${_pwd_koremutake}" = "true" ]]; then
    for (( i=0; i<_pwd_num; i++ )); do
      _n=0
      for int in $(random_int "${_pwd_chars:-7}" 1 $(( ${#_pwd_syllables[@]} - 1 )) ); do
        _tmp_array[_n]=$(printf -- '%s\n' "${_pwd_syllables[int]}")
        (( _n++ ))
      done
      read -r _t _u _v < <(random_int 3 0 $(( ${#_tmp_array[@]} - 1 )) | paste -s -)
      #pwdLower is effectively guaranteed, so we skip it and focus on the others
      if [[ "${_pwd_upper}" = "true" ]]; then
        _tmp_array[_t]=$(capitalise "${_tmp_array[_t]}")
      fi
      if [[ "${_pwd_digit}" = "true" ]]; then
        while (( _u == _t )); do
          _u="$(random_int 1 0 $(( ${#_tmp_array[@]} - 1 )) )"
        done
        _tmp_array[_u]="$(random_int 1 0 9)"
      fi
      if [[ "${_pwd_special}" = "true" ]]; then
        while (( _v == _t )); do
          _v="$(random_int 1 0 $(( ${#_tmp_array[@]} - 1 )) )"
        done
        rand_special=$(random_int 1 0 $(( ${#_pwd_special_chars[@]} - 1 )) )
        _tmp_array[_v]="${_pwd_special_chars[rand_special]}"
      fi
      printf -- '%s\n' "${_tmp_array[@]}" | paste -sd '\0' -
    done
  else
    for (( i=0; i<_pwd_num; i++ )); do
      _n=0
      while read -r; do
        _tmp_array[_n]="${REPLY}"
        (( _n++ ))
      done < <(tr -dc "${_pwd_set}" < /dev/urandom | tr -d ' ' | fold -w 1 | head -n "${_pwd_chars}")
      read -r _t _u _v < <(random_int 3 0 $(( ${#_tmp_array[@]} - 1 )) | paste -s -)
      #pwdLower is effectively guaranteed, so we skip it and focus on the others
      if [[ "${_pwd_upper}" = "true" ]]; then
        if ! printf -- '%s\n' "_tmp_array[@]}" | grep "[A-Z]" >/dev/null 2>&1; then
          _tmp_array[_t]=$(capitalise "${_tmp_array[_t]}")
        fi
      fi
      if [[ "${_pwd_digit}" = "true" ]]; then
        while (( _u == _t )); do
          _u="$(random_int 1 0 $(( ${#_tmp_array[@]} - 1 )) )"
        done
        if ! printf -- '%s\n' "_tmp_array[@]}" | grep "[0-9]" >/dev/null 2>&1; then
          _tmp_array[_u]="$(random_int 1 0 9)"
        fi
      fi
      # Because special characters aren't sucked up from /dev/urandom,
      # we have no reason to test for them, just swap one in
      if [[ "${_pwd_special}" = "true" ]]; then
        while (( _v == _t )); do
          _v="$(random_int 1 0 $(( ${#_tmp_array[@]} - 1 )) )"
        done
        rand_special=$(random_int 1 0 $(( ${#_pwd_special_chars[@]} - 1 )) ) 
        _tmp_array[_v]="${_pwd_special_chars[rand_special]}"
      fi
      printf -- '%s\n' "${_tmp_array[@]}" | paste -sd '\0' -
    done
  fi
} 
genpasswd() { secrets_genpasswd "${@}"; }
