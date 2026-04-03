# shellcheck shell=ksh

# BSD 3-Clause License

# Copyright (c) 2014-2015, Miëtek Bak
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.

# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.

# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Provenance: https://raw.githubusercontent.com/mietek/bashmenot/master/src/line.sh

[ -n "${_SHELLAC_LOADED_line_filter+x}" ] && return 0
_SHELLAC_LOADED_line_filter=1

# @description Return the first line of stdin.
#
# @stdout First line of input
# @exitcode 0 Always
filter_first () {
	head -n 1 || return 0
}


# @description Return all lines of stdin except the first.
#
# @stdout All input lines after the first
# @exitcode 0 Always
filter_not_first () {
	sed '1d' || return 0
}


# @description Return the last line of stdin.
#
# @stdout Last line of input
# @exitcode 0 Always
filter_last () {
	tail -n 1 || return 0
}


# @description Return all lines of stdin except the last.
#
# @stdout All input lines except the last
# @exitcode 0 Always
filter_not_last () {
	sed '$d' || return 0
}


# @description Return only lines from stdin matching a given pattern.
#
# @arg $1 string The pattern to match against
#
# @stdout Lines matching the pattern
# @exitcode 0 Always
filter_matching () {
	local _pattern
	expect_args _pattern -- "$@"

	awk '/'"${_pattern//\//\\/}"'/ { print }' || return 0
}


# @description Return only lines from stdin that do not match a given pattern.
#
# @arg $1 string The pattern to exclude
#
# @stdout Lines not matching the pattern
# @exitcode 0 Always
filter_not_matching () {
	local _pattern
	expect_args _pattern -- "$@"

	awk '!/'"${_pattern//\//\\/}"'/ { print }' || return 0
}


# @description Pass stdin through only if it contains at most one line; fail if more.
#
# @stdout The single input line, or nothing if more than one line was present
# @exitcode 0 Zero or one line present
# @exitcode 1 More than one line present
match_at_most_one () {
	awk '	NR == 1 { line = $0 "\n" }
		NR == 2 { line = ""; exit 1 }
		END { printf line }' || return 1
}


# @description Pass stdin through only if it contains at least one non-empty line.
#
# @stdout Input passed through unchanged
# @exitcode 0 At least one line present
# @exitcode 1 No lines present
match_at_least_one () {
	grep '.' || return 1
}


# @description Pass stdin through only if it contains exactly one non-empty line.
#
# @stdout The single input line
# @exitcode 0 Exactly one line present
# @exitcode 1 Zero or more than one line present
match_exactly_one () {
	match_at_most_one | match_at_least_one || return 1
}


# @description Strip the trailing newline from stdin output.
#
# @stdout Input with no trailing newline
# @exitcode 0 Always
strip_trailing_newline () {
	awk 'NR > 1 { printf "\n" } { printf "%s", $0 }' || return 0
}
