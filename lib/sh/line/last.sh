# shellcheck shell=ksh
# @redirect text/last.sh
# This file exists so that 'shellac include line/last' works as expected.
# The canonical implementation lives in text/last.sh.
# It is intentionally excluded from 'shellac libraries' output.

[ -n "${_SHELLAC_LOADED_text_last+x}" ] && return 0
# shellcheck disable=SC1090
. "$(dirname -- "${BASH_SOURCE[0]}")/../text/first.sh"
