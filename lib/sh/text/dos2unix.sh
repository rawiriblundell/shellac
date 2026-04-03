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

[ -n "${_SHELLAC_LOADED_text_dos2unix+x}" ] && return 0
_SHELLAC_LOADED_text_dos2unix=1

if ! command -v dos2unix >/dev/null 2>&1; then
  # @description Strip DOS/Windows carriage return characters from files or stdin.
  #   Step-in replacement for systems without the dos2unix command; uses 'tr -d \r'.
  #   In-place conversion is performed by writing to a temp file and copying back.
  #   No options are supported; option flags will produce an error.
  #
  # @arg $1 string Optional: one or more file paths to convert in place
  #
  # @stdout Converted content (when reading from stdin with no args)
  # @exitcode 0 Success
  # @exitcode 1 Unsupported option flag, or one or more files could not be written
  dos2unix() {
    local _dos2unix_arg
    # Ensure that no options are supplied in any arg
    for _dos2unix_arg in "${@}"; do
      case "${_dos2unix_arg}" in
        (-*)
          printf -- '%s\n' "This is a simple step-in function, '${_dos2unix_arg}' isn't supported" >&2
          return 1
        ;;
      esac
    done

    # Determine if we are dealing with a file or files
    if (( "${#}" > 0 )); then
      _dos2unix_rc=0
      for _dos2unix_file in "${@}"; do
        if [ ! -w "${_dos2unix_file}" ]; then
          printf -- '%s\n' "Unable to write to '${_dos2unix_file}'" >&2
          (( _dos2unix_rc++ ))
          continue
        fi
        # Make a temporary file
        _dos2unix_tmp=$(mktemp) || {
          printf -- '%s\n' "Unable to create temp file for '${_dos2unix_file}'" >&2
          (( _dos2unix_rc++ ))
          continue
        }

        # Convert the input file to the temp file
        tr -d '\r' < "${_dos2unix_file}" > "${_dos2unix_tmp}" || {
          printf -- '%s\n' "Unable to convert '${_dos2unix_file}'" >&2
          (( _dos2unix_rc++ ))
          continue
        }

        # Write it back
        cp "${_dos2unix_tmp}" "${_dos2unix_file}" || {
          printf -- '%s\n' "Unable to write '${_dos2unix_file}'" >&2
          (( _dos2unix_rc++ ))
          continue
        }
        # Remove the temporary file
        rm "${_dos2unix_tmp}" 2>/dev/null
      done
      (( _dos2unix_rc > 0 )) && return 1
      return 0
    # Otherwise we're parsing stdin
    else
      tr -d '\r'
    fi
  }
fi
