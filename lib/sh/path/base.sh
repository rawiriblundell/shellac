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
# Adapted from adoyle-h/lobash (Apache-2.0) https://github.com/adoyle-h/lobash
# Adapted from labbots/bash-utility (MIT) https://github.com/labbots/bash-utility
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_path_base+x}" ] && return 0
_SHELLAC_LOADED_path_base=1

# @description Test whether a path exists (any type).
#
# @arg $1 string Path to test
#
# @exitcode 0 Path exists
# @exitcode 1 Path does not exist
path_exists() {
    [ -e "${1:-$RANDOM}" ] >/dev/null 2>&1
}

# @description Test whether a path is a regular file.
#
# @arg $1 string Path to test
#
# @exitcode 0 Path is a regular file
# @exitcode 1 Path is not a regular file
path_is_file() {
    [ -f "${1:-$RANDOM}" ] >/dev/null 2>&1
}

# @description Test whether a path is a directory.
#
# @arg $1 string Path to test
#
# @exitcode 0 Path is a directory
# @exitcode 1 Path is not a directory
path_is_directory() {
    [ -d "${1:-$RANDOM}" ] >/dev/null 2>&1
}

# TODO: path_is_hardlink()
# @description Test whether a path is a symbolic link.
#
# @arg $1 string Path to test
#
# @exitcode 0 Path is a symlink
# @exitcode 1 Path is not a symlink
path_is_symlink() {
    [ -L "${1:-$RANDOM}" ] >/dev/null 2>&1
}

# @description Test whether a path is readable by the current process.
#
# @arg $1 string Path to test
#
# @exitcode 0 Path is readable
# @exitcode 1 Path is not readable
path_is_readable() {
    [ -r "${1:-$RANDOM}" ] >/dev/null 2>&1
}

# @description Test whether a path is writeable by the current process.
#
# @arg $1 string Path to test
#
# @exitcode 0 Path is writeable
# @exitcode 1 Path is not writeable
path_is_writeable() {
    [ -w "${1:-$RANDOM}" ] >/dev/null 2>&1
}

# @description Test whether a path is executable by the current process.
#
# @arg $1 string Path to test
#
# @exitcode 0 Path is executable
# @exitcode 1 Path is not executable
path_is_executable() {
    [ -x "${1:-$RANDOM}" ] >/dev/null 2>&1
}

# @description Test whether a path is absolute (starts with /).
#
# @arg $1 string Path to test
#
# @exitcode 0 Path is absolute
# @exitcode 1 Path is not absolute
path_is_absolute() {
    case "${1:-}" in
        (/*) return 0 ;;
        (*)  return 1 ;;
    esac
}

# @description Test whether a path is relative (does not start with /).
#
# @arg $1 string Path to test
#
# @exitcode 0 Path is relative
# @exitcode 1 Path is not relative
path_is_relative() {
    case "${1:-}" in
        (/*) return 1 ;;
        (*)  return 0 ;;
    esac
}

# @description Test whether a path is a directory that contains no files.
#
# @arg $1 string Path to test
#
# @exitcode 0 Path is an empty directory
# @exitcode 1 Path is not an empty directory or does not exist
path_is_empty_dir() {
    [ -d "${1:-$RANDOM}" ] || return 1
    [ -z "$(find "${1}" -maxdepth 0 -empty 2>/dev/null)" ] && return 1
    return 0
}

# @description Test whether a path is inside a git repository.
#   Defaults to the current directory if no path is given.
#
# @arg $1 string Path to test (default: current directory)
#
# @exitcode 0 Path is inside a git repository
# @exitcode 1 Path is not inside a git repository
path_is_gitdir() {
    local _path
    _path="${1:-.}"
    [ -e "${_path}/.git" ] && return 0
    git -C "${_path}" rev-parse --git-dir >/dev/null 2>&1
}

# @description Convert a relative path to an absolute path without using readlink -f.
#   Works for both files and directories that exist on disk. Returns 1 if the path
#   does not exist. Temporarily clears CDPATH to avoid interference.
#
# @arg $1 string Relative or absolute file/directory path
#
# @stdout Absolute path
# @exitcode 0 Success
# @exitcode 1 Path does not exist
path_absolute() {
  local _filename
  _filename="${1:?No filename specified}"
  CDPATH=''
  [ -e "${_filename}" ] || return 1
  if [ -d "${_filename}" ]; then
    (cd "${_filename}" && pwd)
  elif [ -f "${_filename}" ]; then
    if [[ "${_filename}" = /* ]]; then
      printf -- '%s\n' "${_filename}"
    elif [[ "${_filename}" == */* ]]; then
      (
        cd "${_filename%/*}" >/dev/null 2>&1 || return 1
        printf -- '%s\n' "${PWD:-$(pwd)}/${_filename##*/}"
      )
    else
      printf -- '%s\n' "${PWD:-$(pwd)}/${_filename}"
    fi
  fi
}

# @description Strip the leading directory path from a filename.
#   Pure parameter expansion equivalent of basename(1).
#   Does not support the suffix-stripping second argument.
#
# @arg $1 string File path
#
# @stdout Filename component only
# @exitcode 0 Always
path_basename() {
  printf -- '%s\n' "${1##*/}"
}

# @description Strip the filename component, leaving the directory path.
#   Pure parameter expansion equivalent of dirname(1).
#   Does not handle dotfiles, tilde, or other edge cases.
#
# @arg $1 string File path
#
# @stdout Directory component of the path
# @exitcode 0 Always
path_dirname() {
  printf -- '%s\n' "${1%/*}"
}

# @description Get the file extension from a path (without the leading dot).
#   Pure parameter expansion — no subshells.
#
# @arg $1 string File path
#
# @example
#   path_extension "/foo/bar.txt"        # => "txt"
#   path_extension "/foo/archive.tar.gz" # => "gz"
#   path_extension "/foo/noext"          # => exit 1
#
# @stdout Extension string, e.g. "sh", "txt"
# @exitcode 0 Success; 1 No extension found; 2 Missing argument
path_extension() {
  local file extension
  (( ${#} == 0 )) && { printf -- '%s\n' "path_extension: missing argument" >&2; return 2; }
  file="${1##*/}"
  extension="${file##*.}"
  [[ "${file}" = "${extension}" ]] && return 1
  printf -- '%s\n' "${extension}"
}

# @description Get the filename without its extension from a path (the stem).
#   Pure parameter expansion — no subshells.
#
# @arg $1 string File path
#
# @example
#   path_stem "/foo/bar.txt"   # => "bar"
#   path_stem "/foo/bar"       # => "bar"
#
# @stdout Filename without extension
# @exitcode 0 Success; 2 Missing argument
path_stem() {
  local file
  (( ${#} == 0 )) && { printf -- '%s\n' "path_stem: missing argument" >&2; return 2; }
  file="${1##*/}"
  printf -- '%s\n' "${file%.*}"
}

# @description Remove the file extension from a path (returns full path minus .ext).
#   Pure parameter expansion — no subshells.
#
# @arg $1 string File path
#
# @example
#   path_strip_extension "/foo/bar.txt"        # => "/foo/bar"
#   path_strip_extension "/foo/archive.tar.gz" # => "/foo/archive.tar"
#   path_strip_extension "/foo/noext"          # => "/foo/noext"
#
# @stdout Path without final extension
# @exitcode 0 Success; 2 Missing argument
path_strip_extension() {
  local path
  (( ${#} == 0 )) && { printf -- '%s\n' "path_strip_extension: missing argument" >&2; return 2; }
  path="${1}"
  printf -- '%s\n' "${path%.*}"
}

# @description Replace the file extension of a path.
#   The replacement extension should include the leading dot.
#
# @arg $1 string File path
# @arg $2 string New extension (with leading dot, e.g. ".sh")
#
# @example
#   path_replace_extension "/foo/bar.txt" ".md"    # => "/foo/bar.md"
#   path_replace_extension "/foo/bar"     ".sh"    # => "/foo/bar.sh"
#
# @stdout Path with replaced extension
# @exitcode 0 Success; 2 Missing argument
path_replace_extension() {
  local path ext
  (( ${#} < 2 )) && { printf -- '%s\n' "path_replace_extension: missing argument(s)" >&2; return 2; }
  path="${1}"
  ext="${2}"
  printf -- '%s\n' "${path%.*}${ext}"
}

# @description Normalize a path by resolving . and .. components purely as a
#   string operation — the path does not need to exist on disk.
#   Multiple consecutive slashes are collapsed to one.
#   A trailing slash is preserved only for the root "/".
#
# @arg $1 string Path to normalize
#
# @example
#   path_normalize "/foo/bar/../baz"      # => /foo/baz
#   path_normalize "/foo/./bar"           # => /foo/bar
#   path_normalize "foo//bar"             # => foo/bar
#   path_normalize "/a/b/c/../../d"       # => /a/d
#
# @stdout Normalized path
# @exitcode 0 Success; 2 Missing argument
path_normalize() {
  local path part result is_abs
  path="${1:?path_normalize: missing path argument}"

  # Preserve absolute/relative
  is_abs=0
  [[ "${path}" == /* ]] && is_abs=1

  # Split on /
  result=()
  # Temporarily use IFS to split
  local IFS='/'
  for part in ${path}; do
    [[ -z "${part}" || "${part}" == "." ]] && continue
    if [[ "${part}" == ".." ]]; then
      (( ${#result[@]} > 0 )) && unset 'result[${#result[@]}-1]'
    else
      result+=( "${part}" )
    fi
  done

  # Reconstruct
  local joined
  joined="${result[*]}"   # IFS='/' still active
  if (( is_abs )); then
    printf -- '/%s\n' "${joined}"
  elif [[ -z "${joined}" ]]; then
    printf -- '.\n'
  else
    printf -- '%s\n' "${joined}"
  fi
}

# @description Compute the relative path from a base directory to a target path.
#   Both arguments are normalized before comparison (no readlink, works on
#   non-existent paths).  Both must be absolute or both must be relative.
#
# @arg $1 string Base directory (from)
# @arg $2 string Target path (to)
#
# @example
#   path_relative /foo/bar /foo/bar/baz    # => baz
#   path_relative /foo/bar /foo/qux        # => ../qux
#   path_relative /a/b/c   /x/y           # => ../../../x/y
#
# @stdout Relative path
# @exitcode 0 Success; 2 Missing argument
path_relative() {
  local from to from_norm to_norm common up rel
  from="${1:?path_relative: missing base (from) argument}"
  to="${2:?path_relative: missing target (to) argument}"

  from_norm="$(path_normalize "${from}")"
  to_norm="$(path_normalize "${to}")"

  # Split into components
  local IFS='/'
  local -a from_parts to_parts
  read -r -a from_parts <<< "${from_norm}"
  read -r -a to_parts  <<< "${to_norm}"

  # Find common prefix length
  common=0
  while (( common < ${#from_parts[@]} )) && (( common < ${#to_parts[@]} )) &&
        [[ "${from_parts[${common}]}" == "${to_parts[${common}]}" ]]; do
    (( common += 1 ))
  done

  # Build ../.. for remaining from components
  up=$(( ${#from_parts[@]} - common ))
  rel=
  local i
  for (( i = 0; i < up; i++ )); do
    rel="${rel:+${rel}/}.."
  done

  # Append remaining to components
  for (( i = common; i < ${#to_parts[@]}; i++ )); do
    [[ -n "${to_parts[${i}]}" ]] || continue
    rel="${rel:+${rel}/}${to_parts[${i}]}"
  done

  printf -- '%s\n' "${rel:-.}"
}
