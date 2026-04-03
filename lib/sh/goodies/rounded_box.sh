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

[ -n "${_SHELLAC_LOADED_goodies_rounded_box+x}" ] && return 0
_SHELLAC_LOADED_goodies_rounded_box=1

# @description Print text wrapped in a Unicode rounded box.
#   Supports an optional title in the top border and custom width.
#   Long lines are wrapped with fold. Literal \n in content is treated as a newline.
#
# @arg $1 string Optional: -t TITLE to set a title in the top border
# @arg $2 string Optional: -w WIDTH to set the box width in columns (default: 80)
# @arg $@ string Content to display inside the box
#
# @stdout Text enclosed in a rounded Unicode border box
# @exitcode 0 Always
rounded_box() {
    local _u_left _u_right _b_left _b_right _h_bar _v_bar _h_width _title _content
    local _title_visual_width _title_padding _i _processed_content _line _folded_line
    local _line_visual_width _padding_width
    local OPTIND
    _u_left="\xe2\x95\xad"   # upper left corner
    _u_right="\xe2\x95\xae"  # upper right corner
    _b_left="\xe2\x95\xb0"   # bottom left corner
    _b_right="\xe2\x95\xaf"  # bottom right corner
    _h_bar="\xe2\x94\x80"    # horizontal bar
    _v_bar="\xe2\x94\x82"    # vertical bar
    _h_width="78"            # default horizontal width

    # Reset OPTIND
    OPTIND=1

    while getopts ":ht:w:" flags; do
        case "${flags}" in
            (h)
                printf -- '%s\n' "rounded_box (-t [_title] -w [width in columns]) [_content]" >&2
                return 0
            ;;
            (t) _title="${OPTARG}" ;;
            (w) _h_width="$(( OPTARG - 2 ))" ;;
            (*) : ;;
        esac
    done
    shift "$(( OPTIND - 1 ))"

    # What remains after getopts is our content
    # We store it this way to support multi-line input
    _content=$(printf -- '%s ' "${@}")

    # Print our top bar
    printf -- '%b' "${_u_left}"
    # If the title is defined, then make space for it within the top bar
    if [[ -n "${_title}" ]]; then
        # Calculate visual width of title (accounting for UTF-8)
        _title_visual_width=$(printf -- '%s' "${_title}" | wc -m)
        _title_padding=$(( _h_width - _title_visual_width - 2 ))

        printf -- '%b %s ' "${_h_bar}" "${_title}"
        for (( _i=0; _i<_title_padding; _i++)); do
            printf -- '%b' "${_h_bar}"
        done
    # Otherwise, just print the full bar
    else
        for (( _i=0; _i<_h_width; _i++)); do
            printf -- '%b' "${_h_bar}"
        done
    fi
    printf -- '%b\n' "${_h_bar}${_u_right}"

    # Print our content
    if [[ -n "${_content}" ]]; then
        # Replace literal "\n" with actual newlines
        _processed_content=$(printf -- '%s' "${_content}" | sed 's/\\n/\n/g')

        # Process each line, including empty lines
        while IFS= read -r _line || [[ -n "${_line}" ]]; do
            # Wrap long lines with fold
            while IFS= read -r _folded_line; do
                _line_visual_width=$(printf -- '%s' "${_folded_line}" | wc -m)
                _padding_width=$(( _h_width - _line_visual_width ))
                printf -- '%b %s' "${_v_bar}" "${_folded_line}"
                printf -- '%*s' "${_padding_width}"
                printf -- ' %b\n' "${_v_bar}"
            done < <(printf -- '%s\n' "${_line}" | fold -s -w "${_h_width}")
        done < <(printf -- '%s\n' "${_processed_content}")
    else
        # Empty content - print one blank line
        printf -- '%b %*s %b\n' "${_v_bar}" "${_h_width}" "" "${_v_bar}"
    fi

    # Print our bottom bar
    printf -- '%b' "${_b_left}${_h_bar}"
    for (( _i=0; _i<_h_width; _i++)); do
        printf -- '%b' "${_h_bar}"
    done
    printf -- '%b\n' "${_h_bar}${_b_right}"
}

