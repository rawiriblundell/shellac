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

[ -n "${_SHELLAC_LOADED_markdown_markdown+x}" ] && return 0
_SHELLAC_LOADED_markdown_markdown=1

# Block elements — each prints a complete line (trailing newline included).
# Inline elements (md_bold, md_italic, md_code) emit only the formatted
# fragment with no trailing newline, for use inside printf/command substitution.

# @description Print a level-1 heading.
# @arg $@ string Heading text
# @stdout "# text\n"
md_h1() { printf -- '# %s\n' "${*}"; }

# @description Print a level-2 heading.
# @arg $@ string Heading text
# @stdout "## text\n"
md_h2() { printf -- '## %s\n' "${*}"; }

# @description Print a level-3 heading.
# @arg $@ string Heading text
# @stdout "### text\n"
md_h3() { printf -- '### %s\n' "${*}"; }

# @description Print a level-4 heading.
# @arg $@ string Heading text
# @stdout "#### text\n"
md_h4() { printf -- '#### %s\n' "${*}"; }

# @description Print a horizontal rule.
# @stdout "---\n"
md_hr() { printf -- '%s\n' '---'; }

# @description Print a blank line.
# @stdout "\n"
md_blank() { printf -- '\n'; }

# @description Open a fenced code block, with an optional language tag.
# @arg $1 string Optional language identifier (e.g. bash, json)
# @stdout "```[lang]\n"
md_fence_open() { printf -- '\x60\x60\x60%s\n' "${1:-}"; }

# @description Close a fenced code block.
# @stdout "```\n"
md_fence_close() { printf -- '\x60\x60\x60\n'; }

# @description Print a bullet list item.
# @arg $@ string Item text
# @stdout "- text\n"
md_bullet() { printf -- '- %s\n' "${*}"; }

# @description Print a numbered list item.
# @arg $1 integer Item number
# @arg $@ string  Item text
# @stdout "N. text\n"
md_numbered() {
  local _item_num
  _item_num="${1:?No item number provided}"
  shift
  printf -- '%s. %s\n' "${_item_num}" "${*}"
}

# @description Print a blockquote line.
# @arg $@ string Quote text
# @stdout "> text\n"
md_blockquote() { printf -- '> %s\n' "${*}"; }

# Inline elements — no trailing newline; intended for use inside printf or $().

# @description Emit bold-formatted text (no trailing newline).
# @arg $@ string Text to bold
# @stdout "**text**"
md_bold() { printf -- '**%s**' "${*}"; }

# @description Emit italic-formatted text (no trailing newline).
# @arg $@ string Text to italicise
# @stdout "_text_"
md_italic() { printf -- '_%s_' "${*}"; }

# @description Emit inline code-formatted text (no trailing newline).
# @arg $@ string Text to format as inline code
# @stdout "`text`"
md_code() { printf -- '\x60%s\x60' "${*}"; }
