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
# Adapted from adoyle-h/lobash (Apache-2.0) https://github.com/adoyle-h/lobash

[ -n "${_SHELLAC_LOADED_text_style+x}" ] && return 0
_SHELLAC_LOADED_text_style=1

include core/is

# TODO:
# * Check for $COLORTERM and fail out if/when possible
# * Something with this:
# ** https://cubicspot.blogspot.com/2019/05/designing-better-terminal-text-color.html
# References: 
# * https://gist.github.com/XVilka/8346728
# * https://stackoverflow.com/a/33206814


# @description Apply slow blink ANSI formatting to text.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 string Optional: file path or string to format
#
# @stdout Blink-formatted text
# @exitcode 0 Always
text_blink() {
  local LC_CTYPE
  LC_CTYPE=C
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- '\033[5m%s\033[0m\n' "${REPLY}"
    done < "${1:-/dev/stdin}"
  else
    printf -- '\033[5m%s\033[0m\n' "${*}"
  fi
}

# @description Apply bold ANSI formatting to text.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 string Optional: file path or string to format
#
# @stdout Bold-formatted text
# @exitcode 0 Always
text_bold() {
  local LC_CTYPE
  LC_CTYPE=C
  # If an arg is given and it's readable, then it's a file
  # Treat it line by line.  This caters for stdin as well
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- '\033[1m%s\033[0m\n' "${REPLY}"
    done < "${1:-/dev/stdin}"
  # Otherwise, we process anything given as an arg
  else
    printf -- '\033[1m%s\033[0m\n' "${*}"
  fi
}

# @description Convert a comma-separated list to newline-separated format.
#   See also str_n2c() and str_n2s() for the inverse.
#
# @arg $1 string Optional: file path (default: stdin)
#
# @stdout One item per line
# @exitcode 0 Always
str_c2n() {
  while read -r; do
    printf -- '%s\n' "${REPLY}" | tr "," "\\n"
  done < "${1:-/dev/stdin}"
}
text_c2n() { str_c2n "${@}"; }

# @description Center each line of input within the terminal width.
#   Lines longer than the terminal width are folded and each segment centered.
#   Accepts input via stdin or a file path.
#
# @arg $1 string Optional: file path (default: stdin)
#
# @stdout Each line centered within the terminal width
# @exitcode 0 Always
text_center() {
  local width
  width="${COLUMNS:-$(tput cols)}"
  while IFS= read -r; do
    # If, by luck, REPLY is the same as width, then just dump it
    (( ${#REPLY} == width )) && printf -- '%s\n' "${REPLY}" && continue

    # Handle lines of any length longer than width
    # this ensures that wrapped overflow is centered
    if (( ${#REPLY} > width )); then
      while read -r subreply; do
        (( ${#subreply} == width )) && printf -- '%s\n' "${subreply}" && continue
        printf -- '%*s\n' $(( (${#subreply} + width) / 2 )) "${subreply}"
      done < <(fold -w "${width}" <<< "${REPLY}")
      continue
    fi

    # Otherwise, print centered
    printf -- '%*s\n' $(( (${#REPLY} + width) / 2 )) "${REPLY}"
  done < "${1:-/dev/stdin}"
  [[ -n "${REPLY}" ]] && printf -- '%s\n' "${REPLY}"
}

# @description Apply faint/dim ANSI formatting to text.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 string Optional: file path or string to format
#
# @stdout Faint-formatted text
# @exitcode 0 Always
text_faint() {
  local LC_CTYPE
  LC_CTYPE=C
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- '\033[2m%s\033[0m\n' "${REPLY}"
    done < "${1:-/dev/stdin}"
  else
    printf -- '\033[2m%s\033[0m\n' "${*}"
  fi
}



# @description Swap foreground and background colors using ANSI invert formatting.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 string Optional: file path or string to format
#
# @stdout Inverted-color text
# @exitcode 0 Always
text_invert() {
  local LC_CTYPE
  LC_CTYPE=C
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- '\033[7m%s\033[0m\n' "${REPLY}"
    done < "${1:-/dev/stdin}"
  else
    printf -- '\033[7m%s\033[0m\n' "${*}"
  fi
}

# @description Apply italic ANSI formatting to text.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 string Optional: file path or string to format
#
# @stdout Italic-formatted text
# @exitcode 0 Always
text_italic() {
  local LC_CTYPE
  LC_CTYPE=C
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- '\033[3m%s\033[0m\n' "${REPLY}"
    done < "${1:-/dev/stdin}"
  else
    printf -- '\033[3m%s\033[0m\n' "${*}"
  fi
}

# @description Convert newline-separated input to a single comma-separated line.
#   See also str_c2n() for the inverse.
#
# @arg $1 string Optional: file path (default: stdin)
#
# @stdout Comma-separated values on a single line
# @exitcode 0 Always
str_n2c() { paste -sd ',' "${1:--}"; }
text_n2c() { str_n2c "${@}"; }

# @description Convert newline-separated input to a single space-separated line.
#
# @arg $1 string Optional: file path (default: stdin)
#
# @stdout Space-separated values on a single line
# @exitcode 0 Always
str_n2s() { paste -sd ' ' "${1:--}"; }
text_n2s() { str_n2s "${@}"; }

# @description Print a specific line number from a file or stdin.
#
# @arg $1 int Line number to print (required)
# @arg $2 string Optional: file path (default: stdin)
#
# @stdout The specified line
# @exitcode 0 Success
# @exitcode 1 Invalid line number or unreadable file
text_printline() {
  local _line_no
  local _file

  # If $1 is empty, print a usage message
  if [[ -z "${1}" ]]; then
    printf -- '%s\n' "Usage:  text_printline n [file]" ""
    printf -- '\t%s\n' "Print the Nth line of FILE." "" \
      "With no FILE or when FILE is -, read standard input instead."
    return 0
  fi

  # Check that $1 is a number, if it isn't print an error message
  # If it is, blindly convert it to base10 to remove any leading zeroes
  case "${1}" in
    (''|*[!0-9]*)
      printf -- '%s\n' "text_printline: '${1}' does not appear to be a number." >&2
      printf -- '%s\n' "Run 'text_printline' with no arguments for usage." >&2
      return 1
    ;;
    (*)
      _line_no="$(( 10#${1} ))"
    ;;
  esac

  # Next, if $2 is set, check that we can actually read it
  if [[ -n "${2}" ]]; then
    if [[ ! -r "${2}" ]]; then
      printf -- '%s\n' "text_printline: '${2}' does not appear to exist or is not readable." >&2
      printf -- '%s\n' "Run 'text_printline' with no arguments for usage." >&2
      return 1
    else
      _file="${2}"
    fi
  fi

  # Finally after all that testing is done, we throw in a cursory test for 'sed'
  if is_command sed; then
    sed -ne "${_line_no}{p;q;}" -e "\$s/.*/text_printline: end of stream reached./" -e '$ w /dev/stderr' "${_file:-/dev/stdin}"
  # Otherwise we print a message that 'sed' isn't available
  else
    printf -- '%s\n' "text_printline: this function depends on 'sed' which was not found." >&2
    return 1
  fi
}

# @description Apply strikethrough ANSI formatting to text.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 string Optional: file path or string to format
#
# @stdout Strikethrough-formatted text
# @exitcode 0 Always
text_strike() {
  local LC_CTYPE
  LC_CTYPE=C
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- '\033[9m%s\033[0m\n' "${REPLY}"
    done < "${1:-/dev/stdin}"
  else
    printf -- '\033[9m%s\033[0m\n' "${*}"
  fi
}


# @description Apply underline ANSI formatting to text.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 string Optional: file path or string to format
#
# @stdout Underlined text
# @exitcode 0 Always
text_underline() {
  local LC_CTYPE
  LC_CTYPE=C
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- '\033[4m%s\033[0m\n' "${REPLY}"
    done < "${1:-/dev/stdin}"
  else
    printf -- '\033[4m%s\033[0m\n' "${*}"
  fi
}

# @description Wrap input to n words per line using xargs.
#   Reads from stdin or a file.
#
# @arg $1 int Optional: number of words per line (default: 1)
# @arg $2 string Optional: file path (default: stdin)
#
# @stdout Input rewrapped to the specified word count per line
# @exitcode 0 Always
text_wordwrap() {
  xargs -n "${1:-1}" < "${2:-/dev/stdin}"
}

################################################################################
# Colors / colours

# @description Apply a foreground (text) color to input using ANSI 256-color codes.
#   Named colors, numeric codes, and random ('rand') are supported.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 string Color name or code: b, r, g, y, bl, m, c, w, o, rand, or a number 0-255
# @arg $@ string Optional: text to color (default: stdin)
#
# @stdout Color-formatted text
# @exitcode 0 Always
text_fg() {
  local LC_CTYPE
  local fg_colour
  LC_CTYPE=C
  case "${1}" in
    (b|B|black|Black)        fg_colour='\033[38;5;0m';;
    (r|R|red|Red)            fg_colour='\033[1;31m';;
    (g|G|green|Green)        fg_colour='\033[0;32m';;
    (y|Y|yellow|Yellow)      fg_colour='\033[1;33m';;
    (bl|Bl|blue|Blue)        fg_colour='\033[38;5;32m';;
    (m|M|magenta|Magenta)    fg_colour='\033[1;35m';;
    (c|C|cyan|Cyan)          fg_colour='\033[1;36m';;
    (w|W|white|White|safe)   fg_colour='\033[1;37m';;
    (o|O|orange|Orange)      fg_colour='\033[38;5;208m';;
    ('_'|'-'|'null'|''|rand) fg_colour="\033[38;5;$((RANDOM%255))m";;
    (*[0-9]*)
      fg_colour="${1//[^0-9]/}"
      while (( fg_colour > 255 )); do
        fg_colour=$(( fg_colour / 2 ))
      done
      fg_colour="\033[38;5;${fg_colour}m"
    ;;
  esac
  shift
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- "${fg_colour}%s\033[0m\n" "${REPLY}"
    done < "${1:-/dev/stdin}"
  else
    printf -- "${fg_colour}%s\033[0m\n" "${*}"
  fi
}

# @description Apply a background color to input using ANSI 256-color codes.
#   Named colors, numeric codes, and random ('rand') are supported.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 string Color name or code: b, r, g, y, bl, m, c, w, o, rand, or a number 0-255
# @arg $@ string Optional: text to color (default: stdin)
#
# @stdout Background-color-formatted text
# @exitcode 0 Always
text_bg() {
  local LC_CTYPE
  local bg_colour
  LC_CTYPE=C
  case "${1}" in
    (b|B|black|Black)        bg_colour='\033[48;5;0m';;
    (r|R|red|Red)            bg_colour='\033[0;41m';;
    (g|G|green|Green)        bg_colour='\033[0;42m';;
    (y|Y|yellow|Yellow)      bg_colour='\033[0;43m';;
    (bl|Bl|blue|Blue)        bg_colour='\033[48;5;32m';;
    (m|M|magenta|Magenta)    bg_colour='\033[0;45m';;
    (c|C|cyan|Cyan)          bg_colour='\033[0;46m';;
    (w|W|white|White|safe)   bg_colour='\033[0;47m';;
    (o|O|orange|Orange)      bg_colour='\033[48;5;208m';;
    ('_'|'-'|'null'|''|rand) bg_colour="\033[48;5;$((RANDOM%255))m";;
    (*[0-9]*)
      bg_colour="${1//[^0-9]/}"
      while (( bg_colour > 255 )); do
        bg_colour=$(( bg_colour / 2 ))
      done
      bg_colour="\033[48;5;${bg_colour}m"
    ;;
  esac
  shift
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- "${bg_colour}%s\033[0m\n" "${REPLY}"
    done < "${1:-/dev/stdin}"
  else
    printf -- "${bg_colour}%s\033[0m\n" "${*}"
  fi
}

# @description Apply a truecolor foreground color using RGB values (0-255 each).
#   Random values are used for any omitted or non-numeric component.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 int Red component (0-255, or omit for random)
# @arg $2 int Green component (0-255, or omit for random)
# @arg $3 int Blue component (0-255, or omit for random)
# @arg $@ string Optional: text to color (default: stdin)
#
# @stdout Truecolor foreground-formatted text
# @exitcode 0 Always
text_rgb.fg() {
  local fg_red fg_green fg_blue fg_colour
  case "${1}" in
    (*[0-9]*)
      fg_red="${1//[^0-9]/}"
      while (( fg_red > 255 )); do
        fg_red=$(( fg_red / 2 ))
      done
    ;;
    ('_'|'-'|'null'|''|*) fg_red=$((RANDOM%255))
  esac
  case "${2}" in
    (*[0-9]*)
      fg_green="${2//[^0-9]/}"
      while (( fg_green > 255 )); do
        fg_green=$(( fg_green / 2 ))
      done
    ;;
    ('_'|'-'|'null'|''|*) fg_green=$((RANDOM%255))
  esac
  case "${3}" in
    (*[0-9]*)
      fg_blue="${3//[^0-9]/}"
      while (( fg_blue > 255 )); do
        fg_blue=$(( fg_blue / 2 ))
      done
    ;;
    ('_'|'-'|'null'|''|*) fg_blue=$((RANDOM%255))
  esac
  shift 3
  fg_colour="\033[38;2;${fg_red};${fg_green};${fg_blue}m"
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- "${fg_colour}%s\033[0m\n" "${REPLY}"
    done < "${1:-/dev/stdin}"
  else
    printf -- "${fg_colour}%s\033[0m\n" "${*}"
  fi
}

# @description Apply a truecolor background color using RGB values (0-255 each).
#   Random values are used for any omitted or non-numeric component.
#   Accepts input as an argument or via stdin/file.
#
# @arg $1 int Red component (0-255, or omit for random)
# @arg $2 int Green component (0-255, or omit for random)
# @arg $3 int Blue component (0-255, or omit for random)
# @arg $@ string Optional: text to color (default: stdin)
#
# @stdout Truecolor background-formatted text
# @exitcode 0 Always
text_rgb.bg() {
  local bg_red bg_green bg_blue bg_colour
  case "${1}" in
    (*[0-9]*)
      bg_red="${1//[^0-9]/}"
      while (( bg_red > 255 )); do
        bg_red=$(( bg_red / 2 ))
      done
    ;;
    ('_'|'-'|'null'|''|*) bg_red=$((RANDOM%255))
  esac
  case "${2}" in
    (*[0-9]*)
      bg_green="${2//[^0-9]/}"
      while (( bg_green > 255 )); do
        bg_green=$(( bg_green / 2 ))
      done
    ;;
    ('_'|'-'|'null'|''|*) bg_green=$((RANDOM%255))
  esac
  case "${3}" in
    (*[0-9]*)
      bg_blue="${3//[^0-9]/}"
      while (( bg_blue > 255 )); do
        bg_blue=$(( bg_blue / 2 ))
      done
    ;;
    ('_'|'-'|'null'|''|*) bg_blue=$((RANDOM%255))
  esac
  shift 3
  bg_colour="\033[48;2;${bg_red};${bg_green};${bg_blue}m"
  if [[ -r "${1}" ]]||[[ -z "${1}" ]]; then
    while read -r; do
      printf -- "${bg_colour}%s\033[0m\n" "${REPLY}"
    done < "${1:-/dev/stdin}"
  else
    printf -- "${bg_colour}%s\033[0m\n" "${*}"
  fi
}

################################################################################
# Case transformations

if (( BASH_VERSINFO >= 4 )); then
  # @internal
  str_capitalise-string() {
    printf -- '%s\n' "${1^}"
  }
else
  # @internal
  str_capitalise-string() {
    # Split off the first character, uppercase it and trim
    # Next, print the string from the second character onwards
    printf -- '%s\n' "$(str_toupper "${1:0:1}")${1:1}"
  }
fi
# @internal
text_capitalise-string() { str_capitalise-string "${@}"; }

# @description Capitalise the first letter of each word in the input.
#   Accepts input as an argument or via stdin/file.
#   Known limitation: leading whitespace is chomped.
#
# @arg $@ string Optional: one or more words (default: stdin)
#
# @stdout Capitalised text
# @exitcode 0 Success
# @exitcode 1 Both stdin and argument provided simultaneously
str_capitalise() {
  # Ignore any instances of '*' that may be in a file
  local GLOBIGNORE
  local _eof
  local _in_string
  GLOBIGNORE="*"

  # Check that stdin or $1 isn't empty
  if [[ -t 0 ]] && [[ -z "${1}" ]]; then
    printf -- '%s\n' "Usage:  capitalise string" ""
    printf -- '\t%s\n' "Capitalises the first character of STRING and/or its elements."
    return 0
  # Disallow both piping in strings and declaring strings
  elif [[ ! -t 0 ]] && [[ -n "${1}" ]]; then
    printf -- '%s\n' "str_capitalise: please select either piping in or declaring a string to capitalise, not both." >&2
    return 1
  fi

  # If parameter is a file, or stdin is used, action that first
  # shellcheck disable=SC2119
  if [[ -r "${1}" ]]||[[ ! -t 0 ]]; then
    # We require an exit condition for 'read', this covers the edge case
    # where a line is read that does not have a newline
    _eof=
    while [[ -z "${_eof}" ]]; do
      # Read each line of input
      read -r || _eof=true
      # If the line is blank, then print a blank line and continue
      if [[ -z "${REPLY}" ]]; then
        printf -- '%s\n' ""
        continue
      fi
      # Split each line element for processing
      for _in_string in ${REPLY}; do
        # If _in_string is an integer, skip to the next element
        test "${_in_string}" -eq "${_in_string}" 2>/dev/null && continue
        str_capitalise-string "${_in_string}"
      # We use paste to trim and rejoin any trailing whitespace
      done | paste -sd ' ' -
    done < "${1:-/dev/stdin}"

  # Otherwise, if a parameter exists, then capitalise all given elements
  # Processing follows the same path as before.
  elif [[ -n "$*" ]]; then
    for _in_string in "$@"; do
      str_capitalise-string "${_in_string}"
    done | paste -sd ' ' -
  fi

  GLOBIGNORE=
}
text_capitalise() { str_capitalise "${@}"; }

# @description Convert text to lowercase. Accepts a string argument, file path, or stdin.
#   Tries Bash 4 parameter expansion, then awk, then tr as fallbacks.
#
# @arg $1 string Optional: string to lowercase (default: stdin/file)
#
# @stdout Lowercased text
# @exitcode 0 Success
# @exitcode 1 No available conversion method found
str_tolower() {
  if [[ -n "${1}" ]] && [[ ! -r "${1}" ]]; then
    if (( BASH_VERSINFO >= 4 )); then
      printf -- '%s ' "${*,,}" | paste -sd '\0' -
    elif is_command awk; then
      printf -- '%s ' "$*" | awk '{print tolower($0)}'
    elif is_command tr; then
      printf -- '%s ' "$*" | tr '[:upper:]' '[:lower:]'
    else
      printf -- '%s\n' "str_tolower - no available method found" >&2
      return 1
    fi
  else
    if (( BASH_VERSINFO >= 4 )); then
      while read -r; do
        printf -- '%s\n' "${REPLY,,}"
      done
      [[ -n "${REPLY}" ]] && printf -- '%s\n' "${REPLY,,}"
    elif is_command awk; then
      awk '{print tolower($0)}'
    elif is_command tr; then
      tr '[:upper:]' '[:lower:]'
    else
      printf -- '%s\n' "str_tolower - no available method found" >&2
      return 1
    fi < "${1:-/dev/stdin}"
  fi
}
text_tolower() { str_tolower "${@}"; }

# @description Convert text to uppercase. Accepts a string argument, file path, or stdin.
#   Tries Bash 4 parameter expansion, then awk, then tr as fallbacks.
#
# @arg $1 string Optional: string to uppercase (default: stdin/file)
#
# @stdout Uppercased text
# @exitcode 0 Success
# @exitcode 1 No available conversion method found
str_toupper() {
  if [[ -n "${1}" ]] && [[ ! -r "${1}" ]]; then
    if (( BASH_VERSINFO >= 4 )); then
      printf -- '%s ' "${*^^}" | paste -sd '\0' -
    elif is_command awk; then
      printf -- '%s ' "$*" | awk '{print toupper($0)}'
    elif is_command tr; then
      printf -- '%s ' "$*" | tr '[:lower:]' '[:upper:]'
    else
      printf -- '%s\n' "str_toupper - no available method found" >&2
      return 1
    fi
  else
    if (( BASH_VERSINFO >= 4 )); then
      while read -r; do
        printf -- '%s\n' "${REPLY^^}"
      done
      [[ -n "${REPLY}" ]] && printf -- '%s\n' "${REPLY^^}"
    elif is_command awk; then
      awk '{print toupper($0)}'
    elif is_command tr; then
      tr '[:lower:]' '[:upper:]'
    else
      printf -- '%s\n' "str_toupper - no available method found" >&2
      return 1
    fi < "${1:-/dev/stdin}"
  fi
}
text_toupper() { str_toupper "${@}"; }

# @description Remove ANSI/VT100 color and formatting escape codes from a string.
#   Useful for measuring true display length or logging colored output to plain text.
#
# @arg $1 string String to strip (reads from stdin if omitted)
#
# @example
#   str_strip_ansi $'\033[32mhello\033[0m'   # => "hello"
#   printf '%s' "${colored_var}" | str_strip_ansi
#
# @stdout String with all ANSI escape sequences removed
# @exitcode 0 Always
str_strip_ansi() {
  if (( ${#} > 0 )); then
    printf -- '%s\n' "${1}" | sed 's/\x1b\[[0-9;]*m//g'
  else
    sed 's/\x1b\[[0-9;]*m//g'
  fi
}
