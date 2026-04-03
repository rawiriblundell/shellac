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

[ -n "${_SHELLAC_LOADED_line_line+x}" ] && return 0
_SHELLAC_LOADED_line_line=1

# @description Count the number of lines in a string or file.
#   Accepts a file path, string argument, or stdin.
#
# @arg $1 string Optional: file path or newline-delimited string
#
# @example
#   line_count "$(printf 'a\nb\nc')"   # => 3
#   line_count /etc/passwd             # => (number of lines in file)
#
# @stdout Integer line count
# @exitcode 0 Always
line_count() {
  if [[ -r "${1}" ]]; then
    wc -l < "${1}" | tr -d ' '
  elif [[ -n "${1}" ]]; then
    printf -- '%s\n' "${1}" | wc -l | tr -d ' '
  else
    wc -l | tr -d ' '
  fi
}

# @description Return the Nth line of a string or file (1-based).
#   Accepts a file path or stdin; the line number is always required.
#
# @arg $1 int    Line number (1-based)
# @arg $2 string Optional: file path
#
# @example
#   line_at 2 /etc/passwd   # => (second line of /etc/passwd)
#   printf 'a\nb\nc\n' | line_at 2   # => b
#
# @stdout The requested line
# @exitcode 0 Always
# @exitcode 1 No line number given
line_at() {
  local _n
  _n="${1:?No line number given}"
  shift
  if [[ -r "${1}" ]]; then
    sed -n "${_n}p" "${1}"
  else
    sed -n "${_n}p"
  fi
}

# @description Return the first line of a string or file.
#   Accepts a file path or stdin.
#
# @arg $1 string Optional: file path
#
# @example
#   line_first /etc/passwd   # => (first line)
#   printf 'a\nb\nc\n' | line_first   # => a
#
# @stdout First line
# @exitcode 0 Always
line_first() {
  if [[ -r "${1}" ]]; then
    head -n 1 "${1}"
  else
    head -n 1
  fi
}

# @description Return the last line of a string or file.
#   Accepts a file path or stdin.
#
# @arg $1 string Optional: file path
#
# @example
#   line_last /etc/passwd   # => (last line)
#   printf 'a\nb\nc\n' | line_last   # => c
#
# @stdout Last line
# @exitcode 0 Always
line_last() {
  if [[ -r "${1}" ]]; then
    tail -n 1 "${1}"
  else
    tail -n 1
  fi
}

# @description Filter lines matching a pattern (grep wrapper).
#   Accepts a file path or stdin.
#
# @arg $1 string The pattern to match
# @arg $2 string Optional: file path
#
# @example
#   line_grep "root" /etc/passwd   # => (lines containing 'root')
#   printf 'foo\nbar\nbaz\n' | line_grep "ba"   # => bar
#                                               #    baz
#
# @stdout Matching lines
# @exitcode 0 At least one match
# @exitcode 1 No matches
line_grep() {
  local _pattern
  _pattern="${1:?No pattern given}"
  shift
  if [[ -r "${1}" ]]; then
    grep -- "${_pattern}" "${1}"
  else
    grep -- "${_pattern}"
  fi
}

# @description Apply a transformation command to each line of input.
#   The command receives each line via stdin.
#
# @arg $1 string The command (and arguments) to apply to each line
# @arg $2 string Optional: file path (otherwise reads stdin)
#
# @example
#   line_map "tr '[:lower:]' '[:upper:]'" /etc/hostname   # => HOSTNAME
#   printf 'foo\nbar\n' | line_map "tr a-z A-Z"   # => FOO
#                                                  #    BAR
#
# @stdout Transformed lines
# @exitcode 0 Always
line_map() {
  local _cmd _line
  _cmd="${1:?No command given}"
  shift
  while IFS= read -r _line; do
    printf -- '%s\n' "${_line}" | eval "${_cmd}"
  done < "${1:-/dev/stdin}"
}

# @description Remove duplicate lines, preserving order of first occurrence.
#   Accepts a file path or stdin.
#
# @arg $1 string Optional: file path
#
# @example
#   printf 'a\nb\na\nc\nb\n' | line_unique   # => a
#                                             #    b
#                                             #    c
#
# @stdout Lines with duplicates removed, in original order
# @exitcode 0 Always
line_unique() {
  if [[ -r "${1}" ]]; then
    awk '!seen[$0]++' "${1}"
  else
    awk '!seen[$0]++'
  fi
}

# @description Sort lines. Accepts a file path or stdin. Additional sort
#   flags may be passed after the optional file path.
#
# @arg $1 string Optional: file path
#
# @example
#   printf 'b\na\nc\n' | line_sort   # => a
#                                     #    b
#                                     #    c
#
# @stdout Sorted lines
# @exitcode 0 Always
line_sort() {
  if [[ -r "${1}" ]]; then
    sort "${@}"
  else
    sort
  fi
}

# @description Reverse the order of lines. Accepts a file path or stdin.
#
# @arg $1 string Optional: file path
#
# @example
#   printf 'a\nb\nc\n' | line_reverse   # => c
#                                        #    b
#                                        #    a
#
# @stdout Lines in reverse order
# @exitcode 0 Always
line_reverse() {
  if [[ -r "${1}" ]]; then
    tac "${1}"
  else
    tac
  fi
}

# @description Remove leading and trailing whitespace from each line.
#   Accepts a file path or stdin.
#
# @arg $1 string Optional: file path
#
# @example
#   printf '  foo  \n  bar  \n' | line_trim_each   # => foo
#                                                   #    bar
#
# @stdout Lines with leading/trailing whitespace removed
# @exitcode 0 Always
line_trim_each() {
  if [[ -r "${1}" ]]; then
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "${1}"
  else
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
  fi
}

# @description Append a line to a file only if it is not already present
#   (idempotent append).
#
# @arg $1 string The line to append
# @arg $2 string The file path
#
# @example
#   line_append "nameserver 1.1.1.1" /etc/resolv.conf
#
# @exitcode 0 Line already present or successfully appended
# @exitcode 1 Could not append to file
line_append() {
  local _line _file
  _line="${1:?No line given}"
  _file="${2:?No file given}"
  if ! grep -qF "${_line}" "${_file}" 2>/dev/null; then
    printf -- '%s\n' "${_line}" >> "${_file}"
  fi
}

# @description Remove all lines matching a pattern from a file (in-place).
#   The original file is modified directly.
#
# @arg $1 string The pattern to match for removal
# @arg $2 string The file path
#
# @example
#   line_remove "^#" /etc/myconfig   # removes all comment lines
#
# @exitcode 0 Always
# @exitcode 1 File not writable
line_remove() {
  local _pattern _file
  _pattern="${1:?No pattern given}"
  _file="${2:?No file given}"
  if [[ ! -w "${_file}" ]]; then
    printf -- '%s\n' "line_remove: ${_file} is not writable" >&2
    return 1
  fi
  sed -i "/${_pattern}/d" "${_file}"
}
