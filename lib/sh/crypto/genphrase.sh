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

[ -n "${_SHELLAC_LOADED_crypto_genphrase+x}" ] && return 0
_SHELLAC_LOADED_crypto_genphrase=1

# @description Generate random passphrases from a word dictionary file (~/.pwords.dict).
#   Produces XKCD "Correct Horse Battery Staple" style phrases; see -S for stronger
#   alternatives. Requires the 'capitalise' function and optionally 'shuf' or 'rand'.
#
# @arg $1 string Optional flags: -h (help), -n N (count), -s word (seed word),
#   -S (seed explanation), -w N (words per phrase)
#
# @stdout One or more passphrases, one per line
# @exitcode 0 Success
# @exitcode 1 Dictionary file unavailable, or required dependency missing
secrets_genphrase() {
  # Some examples of methods to do this (fastest to slowest):
  # shuf:         printf -- '%s\n' "$(shuf -n 3 ~/.pwords.dict | tr -d "\n")"
  # perl:         printf -- '%s\n' "perl -nle '$word = $_ if rand($.) < 1; END { print $word }' ~/.pwords.dict"
  # sed:          printf "$s\n" "sed -n $((RANDOM%$(wc -l < ~/.pwords.dict)+1))p ~/.pwords.dict"
  # python:       printf -- '%s\n' "$(python -c 'import random, sys; print("".join(random.sample(sys.stdin.readlines(), "${_phrase_words}")).rstrip("\n"))' < ~/.pwords.dict | tr -d "\n")"
  # oawk/nawk:    printf -- '%s\n' "$(for i in {1..3}; do sed -n "$(echo "$RANDOM" $(wc -l <~/.pwords.dict) | awk '{ printf("%.0f\n",(1.0 * $1/32768 * $2)+1) }')p" ~/.pwords.dict; done | tr -d "\n")"
  # gawk:         printf -- '%s\n' "$(awk 'BEGIN{ srand(systime() + PROCINFO["pid"]); } { printf( "%.5f %s\n", rand(), $0); }' ~/.pwords.dict | sort -k 1n,1 | sed 's/^[^ ]* //' | head -3 | tr -d "\n")"
  # sort -R:      printf -- '%s\n' "$(sort -R ~/.pwords.dict | head -3 | tr -d "\n")"
  # bash $RANDOM: printf -- '%s\n' "$(for i in $(<~/.pwords.dict); do echo "$RANDOM $i"; done | sort | cut -d' ' -f2 | head -3 | tr -d "\n")"

  # perl, sed, oawk/nawk and bash are the most portable options in order of speed.  The bash $RANDOM example is horribly slow, but reliable.  Avoid if possible.

  # First, double check that the dictionary file exists.
  if [[ ! -f ~/.pwords.dict ]] ; then
    # Test if we can download our wordlist, otherwise use the standard 'words' file to generate something usable
    if ! wget -T 2 https://raw.githubusercontent.com/rawiriblundell/dotfiles/master/.pwords.dict -O ~/.pwords.dict &>/dev/null; then
      # Alternatively, we could just use grep -v "[[:punct:]]", but we err on the side of portability
      LC_COLLATE=C grep -Eh '^[A-Za-z].{3,9}$' /usr/{,share/}dict/words 2>/dev/null | grep -v "'" > ~/.pwords.dict
    fi
  fi

  # Test we have the capitalise function available
  if ! type capitalise &>/dev/null; then
    printf -- '%s\n' "[ERROR] genphrase: 'capitalise' function is required but was not found." \
      "This function can be retrieved from https://github.com/rawiriblundell"
    return 1
  fi

  # localise our vars for safety
  local OPTIND  _phrase_words _phrase_num _phrase_seed _phrase_seed_doc _seed_word _total_words

  # Default the vars
  _phrase_words=3
  _phrase_num=1
  _phrase_seed="False"
  _phrase_seed_doc="False"
  _seed_word=

  while getopts ":hn:s:Sw:" Flags; do
    case "${Flags}" in
      (h)  printf -- '%s\n' "" "genphrase - a basic passphrase generator" \
             "" "Optional Arguments:" \
             "-h [help]" \
             "-n [number of passphrases to generate (Default:${_phrase_num})]" \
             "-s [seed your own word.  Use 'genphrase -S' to read about this option.]" \
             "-S [explanation for the word seeding option: -s]" \
             "-w [number of random words to use (Default:${_phrase_words})]" ""
           return 0;;
      (n)  _phrase_num="${OPTARG}";;
      (s)  _phrase_seed="True"
           _seed_word="[${OPTARG}]";;
      (S)  _phrase_seed_doc="True";;
      (w)  _phrase_words="${OPTARG}";;
      (\?)  printf -- '%s\n' "ERROR: Invalid option: '-${OPTARG}'.  Try 'genphrase -h' for usage." >&2
            return 1;;
      (:)  printf -- '%s\n' "Option '-${OPTARG}' requires an argument. e.g. '-${OPTARG} 10'" >&2
           return 1;;
    esac
  done
  
  # If -S is selected, print out the documentation for word seeding
  if [[ "${_phrase_seed_doc}" = "True" ]]; then
    printf -- '%s\n' \
    "======================================================================" \
    "genphrase and the -s option: Why you would want to seed your own word?" \
    "======================================================================" \
    "One method for effectively using passphrases is known as 'root and extension.'" \
    "This can be expressed in a few ways, but in this context, it's to choose" \
    "at least two random words (your 'root') and to seed those two words" \
    "with a task specific word (your 'extension')." "" \
    "So let's take two words:" \
    "---" "pings genre" "---" "" \
    "Now if we capitalise both words to get TitleCasing, we meet the usual"\
    "UPPER and lowercase password requirements, as well as very likely" \
    "meeting the password length requirement: 'PingsGenre'" ""\
    "So then we add a task specific word: Let's say this passphrase is for" \
    "your online banking, so we add the word 'bank' into the mix and get:" \
    "'PingsGenrebank'" "" \
    "For social networking, you might have 'PingsGenreFBook' and so on." \
    "The random words are the same, but the task-specific word is the key." \
    "" "Problem is, this arguably isn't good enough.  According to Bruce Schneier" \
    "CorrectHorseBatteryStaple is not that secure.  Others argue otherwise." \
    "See: https://goo.gl/ZGlkfm and http://goo.gl/kunYbu." "" \
    "So we need to randomise those words, introduce some special characters," \
    "and some numbers.  'PingsGenrebank' becomes 'Pings{B4nk}Genre'" \
    "and likewise 'PingsGenreFBook' becomes '(FB0ok)GenrePings'." \
    "" "So, this is a very easy to remember system which meets most usual" \
    "password requirements, and it makes most lame password checkers happy." \
    "You could also argue that this borders on multi-factor auth" \
    "i.e. something you are/have/know = username/root/extension." \
    "" "genphrase will always put the seeded word in square brackets and if" \
    "possible it will randomise its location in the phrase, it's over to" \
    "you to make sure that your seeded word has numerals etc." "" \
    "Note: You can always use genphrase to generate the base phrase and" \
    "      then manually embellish it to your taste."
    return 0
  fi
  
  # Next test if a word is being seeded in
  if [[ "${_phrase_seed}" = "True" ]]; then
    # If so, make space for the seed word
    ((_phrase_words = _phrase_words - 1))
  fi

  # Calculate the total number of words we might process
  _total_words=$(( _phrase_words * _phrase_num ))
  
  # Now generate the passphrase(s)
  # First we test to see if shuf is available.  This should now work with the
  # 'shuf' step-in function and 'rand' scripts available from https://github.com/rawiriblundell
  # Also requires the 'capitalise' function from said source.
  if command -v shuf >/dev/null 2>&1; then
    # If we're using bash4, then use mapfile for safety
    if (( BASH_VERSINFO >= 4 )); then
      # Basically we're using shuf and awk to generate lines of random words
      # and assigning each line to an array element
      mapfile -t wordArray < <(shuf -n "${_total_words}" ~/.pwords.dict | awk -v w="${_phrase_words}" 'ORS=NR%w?FS:RS')
    # This older method should be ok for this particular usage,
    # but otherwise is not a direct replacement for mapfile
    # See: http://mywiki.wooledge.org/BashFAQ/005#Loading_lines_from_a_file_or_stream
    else
      IFS=$'\n' read -d '' -r -a wordArray < <(shuf -n "${_total_words}" ~/.pwords.dict | awk -v w="${_phrase_words}" 'ORS=NR%w?FS:RS')
    fi

    # Iterate through each line of the array
    for line in "${wordArray[@]}"; do
      # Convert the line to an array of its own and add any seed word
      # shellcheck disable=SC2206
      lineArray=( "${_seed_word}" ${line} )
      if (( BASH_VERSINFO >= 4 )); then
        shuf -e "${lineArray[@]^}"
      else
        shuf -e "${lineArray[@]}" | capitalise
      fi | paste -sd '\0' -
    done
    return 0 # Prevent subsequent run of bash
  
  # Otherwise, we switch to bash.  This is the fastest way I've found to perform this
  else
    if ! command -v rand >/dev/null 2>&1; then
      printf -- '%s\n' "[ERROR] genphrase: This function requires the 'rand' external script, which was not found." \
        "You can get this script from https://github.com/rawiriblundell"
      return 1
    fi

    # We test for 'mapfile' which indicates bash4 or some step-in function
    if command -v mapfile >/dev/null 2>&1; then
      # Create two arrays, one with all the words, and one with a bunch of random numbers
      mapfile -t dictArray < ~/.pwords.dict
      mapfile -t numArray < <(rand -M "${#dictArray[@]}" -r -N "${_total_words}")
    # Otherwise we take the classic approach
    else
      read -d '' -r -a dictArray < ~/.pwords.dict
      read -d '' -r -a numArray < <(rand -M "${#dictArray[@]}" -r -N "${_total_words}")
    fi

    # Setup the following vars for iterating through and slicing up 'numArray'
    loWord=0
    hiWord=$(( _phrase_words - 1 ))

    # Now start working our way through both arrays
    while (( hiWord <= _total_words )); do
      # Group all the following output
      {
        # We print out a random number with each word, this allows us to sort
        # all of the output, which randomises the location of any seed word
        printf -- '%s\n' "${RANDOM} ${_seed_word}"
        for randInt in "${numArray[@]:loWord:_phrase_words}"; do
          if (( BASH_VERSINFO >= 4 )); then
            printf -- '%s\n' "${RANDOM} ${dictArray[randInt]^}"
          else
            printf -- '%s\n' "${RANDOM} ${dictArray[randInt]}" | capitalise
          fi
        done
      # Pass the grouped output for some cleanup
      } | sort | awk '{print $2}' | paste -sd '\0' -
      # Iterate our boundary vars up and loop again until completion
      # shellcheck disable=SC2034
      loWord=$(( hiWord + 1 ))
      hiWord=$(( hiWord + _phrase_words ))
    done
  fi
}
genphrase() { secrets_genphrase "${@}"; }
