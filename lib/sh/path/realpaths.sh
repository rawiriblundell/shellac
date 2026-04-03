#!/usr/bin/env bash
# CC0 1.0 Universal
# Provenance: https://raw.githubusercontent.com/bashup/realpaths/master/realpaths

[ -n "${_SHELLAC_LOADED_path_realpaths+x}" ] && return 0
_SHELLAC_LOADED_path_realpaths=1

# @description Resolve symlinks and return the parent directory of the target.
#   Result is written to the global REPLY variable, not stdout.
# @arg $1 string Path to resolve
realpath_location(){ realpath_follow "$1"; realpath_absolute "$REPLY" ".."; }
# @description Resolve symlinks and return the resulting absolute path.
#   Result is written to the global REPLY variable, not stdout.
# @arg $1 string Path to resolve
realpath_resolved(){ realpath_follow "$1"; realpath_absolute "$REPLY"; }
# @description Return the directory component of a path. Result is written to REPLY.
# @arg $1 string Path to process
realpath_dirname() { REPLY=.; ! [[ $1 =~ /+[^/]+/*$|^//$ ]] || REPLY="${1%${BASH_REMATCH[0]}}"; REPLY=${REPLY:-/}; }
# @description Return the filename component of a path. Result is written to REPLY.
# @arg $1 string Path to process
realpath_basename(){ REPLY=/; ! [[ $1 =~ /*([^/]+)/*$ ]] || REPLY="${BASH_REMATCH[1]}"; }

# @description Resolve all symlinks in a path without resolving path components.
#   Detects symlink loops and stops. Result is written to REPLY.
# @arg $1 string Path to follow
realpath_follow() {
	local _target
	while [[ -L "$1" ]] && _target=$(readlink -- "$1"); do
		realpath_dirname "$1"
		# Resolve relative to symlink's directory
		[[ $REPLY != . && $_target != /* ]] && REPLY=$REPLY/$_target || REPLY=$_target
		# Break out if we found a symlink loop
		for _target; do [[ $REPLY == "$_target" ]] && break 2; done
		# Add to the loop-detect list and tail-recurse
		set -- "$REPLY" "$@"
	done
	REPLY="$1"
}

# @description Compute an absolute path by resolving path components against PWD.
#   Handles ., .., double-slash, and root. Result is written to REPLY.
# @arg $1 string Path component(s) to resolve
realpath_absolute() {
	REPLY=$PWD; local eg=extglob; ! shopt -q $eg || eg=; ${eg:+shopt -s $eg}
	while (($#)); do case $1 in
		//|//[^/]*) REPLY=//; set -- "${1:2}" "${@:2}" ;;
		/*) REPLY=/; set -- "${1##+(/)}" "${@:2}" ;;
		*/*) set -- "${1%%/*}" "${1##${1%%/*}+(/)}" "${@:2}" ;;
		''|.) shift ;;
		..) realpath_dirname "$REPLY"; shift ;;
		*) REPLY="${REPLY%/}/$1"; shift ;;
	esac; done; ${eg:+shopt -u $eg}
}

# @description Recursively canonicalise a path: resolve symlinks and normalise
#   all path components. Result is written to REPLY.
# @arg $1 string Path to canonicalise
realpath_canonical() {
	realpath_follow "$1"; set -- "$REPLY"   # $1 is now resolved
	realpath_basename "$1"; set -- "$1" "$REPLY"   # $2 = basename $1
	realpath_dirname "$1"
	[[ $REPLY != "$1" ]] && realpath_canonical "$REPLY"; # recurse unless root
	realpath_absolute "$REPLY" "$2";   # combine canon parent w/basename
}

# @description Compute the relative path from a base directory to a target path.
#   Defaults to PWD as the base if not given. Result is written to REPLY.
# @arg $1 string Target path
# @arg $2 string Optional: base directory (default: PWD)
realpath_relative() {
	local _target=""
	realpath_absolute "$1"; set -- "$REPLY" "${@:2}"; realpath_absolute "${2-$PWD}" X
	while realpath_dirname "$REPLY"; [[ "$1" != "$REPLY" && "$1" == "${1#${REPLY%/}/}" ]]; do
		_target=../$_target
	done
	[[ $1 == "$REPLY" ]] && REPLY=${_target%/} || REPLY="$_target${1#${REPLY%/}/}"
	REPLY=${REPLY:-.}
}

# @description Resolve a symlink chain to its ultimate target using only POSIX
#   tools (ls -dl, not readlink). Handles up to 40 levels of indirection.
#   Unlike other realpath_* functions, writes the resolved path to stdout, not REPLY.
#   Attribution: based on readlinkf_posix by ko1nksm. See NOTICE.md.
#
# @arg $1 string Path to resolve
# @stdout Resolved absolute path
# @exitcode 0 Path resolved successfully
# @exitcode 1 Path not found, too many symlinks, or cd failed
realpath_portable_follow() {
  local CDPATH
  local _max_symlinks
  local _target
  local _link

  [ -n "${1:-}" ] || return 1
  CDPATH=''  # shadow env CDPATH to prevent cd from changing to unexpected dirs
  _max_symlinks=40

  _target="${1}"
  [ -e "${_target%/}" ] || _target="${1%"${1##*[!/]}"}"  # strip trailing slashes
  [ -d "${_target:-/}" ] && _target="${_target}/"

  cd -P -- "$(dirname -- "${_target}")" 2>/dev/null || return 1
  _target="$(basename -- "${_target}")"

  while [ "${_max_symlinks}" -ge 0 ] && _max_symlinks=$(( _max_symlinks - 1 )); do
    if [ "${_target}" != "${_target%/*}" ]; then
      # shellcheck disable=SC2164
      cd -P -- "${_target%/*}" 2>/dev/null || break
      _target="${_target##*/}"
    fi

    if [ ! -L "${_target}" ]; then
      printf -- '%s\n' "${PWD%/}/${_target}"
      return 0
    fi

    # ls -dl output format: "lrwxrwxrwx ... filename -> link_target"
    _link="$(ls -dl -- "${_target}" 2>/dev/null)" || break
    _target="${_link#*" ${_target} -> "}"
  done
  return 1
}
