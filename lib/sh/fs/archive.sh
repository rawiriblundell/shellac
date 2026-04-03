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

[ -n "${_SHELLAC_LOADED_fs_archive+x}" ] && return 0
_SHELLAC_LOADED_fs_archive=1

# @description Compress files into a common archive format determined by the
#   output filename extension. Supports .tar.bz2, .tar.gz, .tgz, .zip, and .rar.
#
# @arg $1 string Output archive filename (extension determines format)
# @arg $2 string One or more source files or directories to include
#
# @exitcode 0 Success
# @exitcode 1 Unrecognised file extension
fs_compress() {
  local _fsobj
  _fsobj=$1
  shift
  case "${_fsobj}" in
    (*.tar.bz2) tar cjf "${_fsobj}" "${@}"  ;;
    (*.tar.gz)  tar czf "${_fsobj}" "${@}"  ;;
    (*.tgz)     tar czf "${_fsobj}" "${@}"  ;;
    (*.zip)     zip "${_fsobj}" "${@}"      ;;
    (*.rar)     rar "${_fsobj}" "${@}"      ;;
    (*)         printf -- '%s\n' "Filetype not recognized" ;;
  esac
}

# @description Extract one or more archives, dispatching to the appropriate tool
#   based on file extension. Supports tar variants, 7z, rar, zip, cpio, bz2, gz,
#   xz, lzma, zpaq, arc, and others.
#
# @arg $1 string One or more archive file paths to extract
#
# @exitcode 0 All archives extracted successfully
# @exitcode 1 One or more files were unreadable or had unrecognised extensions
fs_extract() {
  local _xcmd _rc _fsobj

  (($#)) || return
  _rc=0
  for _fsobj; do
    _xcmd=''

    if [[ ! -r ${_fsobj} ]]; then
      printf -- '%s\n' "$0: file is unreadable: '${_fsobj}'" >&2
      continue
    fi

    [[ -e ./"${_fsobj#/}" ]] && _fsobj="./${_fsobj#/}"

    case ${_fsobj} in
      (*.cbt|*.t@(gz|lz|xz|b@(2|z?(2))|a@(z|r?(.@(Z|bz?(2)|gz|lzma|xz)))))
        _xcmd=(bsdtar xvf)
      ;;
      (*.7z*|*.arj|*.cab|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.rpm|*.udf|*.wim|*.xar)
        _xcmd=(7z x)
      ;;
      (*.ace|*.cba)         _xcmd=(unace x) ;;
      (*.cbr|*.rar)         _xcmd=(unrar x) ;;
      (*.cbz|*.epub|*.zip)  _xcmd=(unzip) ;;
      (*.cpio) cpio -id < "${_fsobj}"; _rc=$(( _rc + "${?}" )); continue ;;
      (*.cso)
        ciso 0 "${_fsobj}" "${_fsobj}".iso; archive_extract "${_fsobj}".iso
        rm -rf "${_fsobj:?}"; _rc=$(( _rc + "${?}" ))
        continue
      ;;
      (*.arc)   _xcmd=(arc e);;
      (*.bz2)   _xcmd=(bunzip2);;
      (*.exe)   _xcmd=(cabextract);;
      (*.gz)    _xcmd=(gunzip);;
      (*.lzma)  _xcmd=(unlzma);;
      (*.xz)    _xcmd=(unxz);;
      (*.Z|*.z) _xcmd=(uncompress);;
      (*.zpaq)  _xcmd=(zpaq x);;
      (*)
        printf -- '%s\n' "$0: unrecognized file extension: '${_fsobj}'" >&2
        continue
      ;;
    esac

    command "${_xcmd[@]}" "${_fsobj}"
    _rc=$(( _rc + "${?}" ))
  done
  (( _rc > 0 )) && return "${_rc}"
  return 0
}
