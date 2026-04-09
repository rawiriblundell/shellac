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
# 8-ball retrieved from https://www.asciiart.eu/sports-and-outdoors/billiards
# This appears to be derived from ASCII sphere art attributed to Felix Lee <flee@cse.psu.edu>

[ -n "${_SHELLAC_LOADED_goodies_8ball+x}" ] && return 0
_SHELLAC_LOADED_goodies_8ball=1

# @description Print a random Magic 8-Ball response with ASCII art sphere.
#   Responses are drawn from three categories: affirmative, non-committal,
#   and negative.  A category is chosen at random, then a response from
#   within that category is selected.
#
# @stdout ASCII 8-ball sphere followed by one random response
# @exitcode 0 Always
8ball() {
  local _affirmative _non_committal _negative
  local _idx _response

  _affirmative=(
    "It is certain"
    "It is decidedly so"
    "Without a doubt"
    "Yes definitely"
    "You may rely on it"
    "As I see it, yes"
    "Most likely"
    "Outlook good"
    "Yes"
    "Signs point to yes"
    "Yes queen!"
    "Yes king!"
  )

  _non_committal=(
    "Reply hazy, try again"
    "Ask again later"
    "Better not tell you now"
    "Cannot predict now"
    "Concentrate and ask again"
    "Yo no se"
    "Not sure"
  )

  _negative=(
    "Don't count on it"
    "My reply is no"
    "My sources say no"
    "Outlook not so good"
    "Very doubtful"
    "You did not cook"
    "You got roasted alive"
  )

  case "$(( RANDOM % 3 ))" in
    (0)
      _idx="$(( RANDOM % ${#_affirmative[@]} ))"
      _response="${_affirmative[${_idx}]}"
    ;;
    (1)
      _idx="$(( RANDOM % ${#_non_committal[@]} ))"
      _response="${_non_committal[${_idx}]}"
    ;;
    (*)
      _idx="$(( RANDOM % ${#_negative[@]} ))"
      _response="${_negative[${_idx}]}"
    ;;
  esac

  cat <<EOF
        ____
    ,dP9CGG88@b,
  ,IP  _   Y888@@b,
 dIi  (_)   G8888@b
dCII  (_)   G8888@@b
GCCIi     ,GG8888@@@
GGCCCCCCCGGG88888@@@
GGGGCCCGGGG88888@@@@...
Y8GGGGGG8888888@@@@P.....
 Y88888888888@@@@@P......
 \`Y8888888@@@@@@@P'......
    \`@@@@@@@@@P'.......
        """"........

  ${_response}
EOF
}
