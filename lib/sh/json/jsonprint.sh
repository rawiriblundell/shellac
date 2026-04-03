# shellcheck shell=ksh

[ -n "${_SHELLAC_LOADED_json_jsonprint+x}" ] && return 0
_SHELLAC_LOADED_json_jsonprint=1
# The MIT License (MIT)

# Copyright (c) 2020 -, Rawiri Blundell

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

################################################################################
# Author's note: This is an exercise for my own amusement/education.
# If it works well for you, fantastic!  If you have ideas, please submit them :)

# @description Print an error message to stderr and exit 1. Variant of die() for jsonprint.
#   Note that in the parent script, extra logic may be necessary to die in subshells.
#   See: https://gist.github.com/rawiriblundell/2dab6903848f73641652a8e95e872dcb
#
# @arg $1 string Error message
#
# @stderr Error message prefixed with '====> jsonprint exception:'
# @exitcode 1 Always
json_die() {
  printf -- '====> jsonprint exception: %s\n' "${@}" >&2
  exit 1
}

# @description Alias for json_die().
json_exception() {
  json_die "${@}"
}

# @description Emit an opening curly brace to denote the start of a JSON block.
#
# @stdout '{'
# @exitcode 0 Always
json_open() {
  printf -- '%s' "{"
}

# @description Emit a closing curly brace followed by a newline (for ndjson).
#
# @stdout '}\n'
# @exitcode 0 Always
json_close() {
  printf -- '%s\n' "}"
}

# @description Emit a single comma.
#
# @stdout ','
# @exitcode 0 Always
json_comma() {
  printf -- '%s' ","
}

# @description Remove a trailing comma from stdin. Pipe input into this function.
#   Use when you cannot avoid emitting a trailing comma on the last element.
#
# @example
#   some_code | json_decomma
#
# @stdout Input with trailing comma removed
# @exitcode 0 Always
json_decomma() {
  sed 's/\(.*\),/\1/'
}

# @description Sanitise a string for use as a JSON key or value. Strips surrounding
#   quotes, trailing ':' or '=', and leading/trailing whitespace. Accepts input as an
#   argument or via stdin.
#
# @arg $1 string Optional: string to sanitise (reads from stdin if omitted)
#
# @stdout Sanitised string
# @exitcode 0 Always
json_sanitise() {
  local _input
  if [[ -n "${1}" ]]; then
    _input="${1}"
  else
    read -r _input
  fi

  # Strip any literal double quotes.
  # These will be re-added if required by an output function
  _input="${_input%\"}"
  _input="${_input#\"}"

  # Strip any literal single quotes.
  # These will be re-added if required by an output function
  _input="${_input%\'}"
  _input="${_input#\'}"

  # Strip any trailing instances of ":" or "="
  _input="${_input%%:*}"
  _input="${_input%%=*}"

  # Remove any leading whitespace from 'value'
  _input="${_input#"${_input%%[![:space:]]*}"}"

  # Remove any trailing whitespace from 'key'
  _input="${_input%"${_input##*[![:space:]]}"}"

  printf -- '%s' "${_input}"
}

# @description US-English spelling alias for json_sanitise().
json_sanitize() {
  json_sanitise "${@}"
}

# @description Verify that required commands or files exist. On failure, emits a JSON
#   object containing Warning keypairs for each missing item and exits 1.
#
# @arg $@ string One or more command names or file paths to check
#
# @example
#   json_require lsblk /proc/meminfo
#
# @stdout JSON Warning object if any required items are missing
# @exitcode 0 All required items found
# @exitcode 1 One or more items missing
json_require() {
  local _fsobj _iter_count
  local -a _failures
  # shellcheck disable=SC2048
  for _fsobj in ${*}; do
    # First try to determine if it's a command
    command -v "${_fsobj}" >/dev/null 2>&1 && continue

    # Check for an executable at an absolute or relative path (not PATH lookup)
    [[ -x "${_fsobj}" ]] && continue

    # Next, let's see if it's a readable file
    [[ -r "${_fsobj}" ]] && continue

    # If we get to this point, add it to our list of failures
    _failures+=( "${_fsobj}" )
  done

  # Tare a loop counter
  # This helps us to automatically determine when to stop outputting commas
  _iter_count=0

  # If we have no failures, then no news is good news - return quietly
  if (( "${#_failures[@]}" == 0 )); then
    return 0
  # Otherwise, we process each element of our failure array
  else
    json_open
      for _fsobj in "${_failures[@]}"; do
        # If we're on our first run through this loop, we need to use json_str()
        # Once we iterate _iter_count by 1, we don't need to touch it again
        if (( _iter_count == 0 )); then
          json_str Warning "${_fsobj} not found or not readable"
          (( _iter_count++ ))
        # With _iter_count > 0, we simply append each extra warning
        # The append functions are prefixed with a comma, making them stackable
        else
          json_append_str Warning "${_fsobj} not found or not readable"
        fi
      done
    json_close
  fi
  exit 1
}

# @description Determine the JSON type of a value: 'float', 'int', 'bool', or 'string'.
#   Used internally to select the appropriate output function (json_str, json_num, etc.).
#
# @arg $1 string Value to inspect
#
# @stdout One of: float, int, bool, string
# @exitcode 0 Always
json_gettype() {
  local _isbool
  # Floats
  if printf -- '%s\n' "${*}" | grep -E '^[-+]?[0-9]+\.[0-9]*$' >/dev/null 2>&1; then
    printf -- '%s\n' "float"
    return 0
  fi

  # Integers
  if printf -- '%s\n' "${*}" | grep -E '^[-+]?[0-9]+$' >/dev/null 2>&1; then
    printf -- '%s\n' "int"
    return 0
  fi

  # Booleans
  # In the case of a boolean, we should only ever deal with one arg
  case "${1}" in
    ([tT][rR][uU][eE])      _isbool=true ;;
    ([fF][aA][lL][sS][eE])  _isbool=true ;;
    ([yY][eE][sS])          _isbool=true ;;
    ([nN][oO])              _isbool=true ;;
    ([oO][nN])              _isbool=true ;;
    ([oO][fF][fF])          _isbool=true ;;
    (*)                     _isbool=false ;;
  esac
  if [[ "${_isbool}" = "true" ]]; then
    printf -- '%s\n' "bool"
    return 0
  fi

  # Everything else we deal with as a string
  printf -- '%s\n' "string"
  return 0
}

# @description Emit an opening array bracket. With a name argument, emits '"name": ['.
#   Without an argument, emits '['.
#
# @arg $1 string Optional: array name
#
# @stdout '"name": [' or '['
# @exitcode 0 Always
json_open_arr() {
  case "${1}" in
    ('')  printf -- '%s' "[" ;;
    (*)   printf -- '"%s": [' "${*}" ;;
  esac
}

# @description Emit a closing array bracket. With '-c' or '--comma', appends a trailing comma.
#
# @arg $1 string Optional: '-c' or '--comma' to append a trailing comma
#
# @stdout ']' or '],'
# @exitcode 0 Always
json_close_arr() {
  local _comma
  case "${1}" in
    (-c|--comma) _comma="," ;;
    (*)          _comma="" ;;
  esac
  printf -- '%s%s' "]" "${_comma}"
}

# @description Emit a closing-then-opening array bracket sequence to chain arrays.
#   With '-n' or '--no-bracket', the leading ']' is omitted. With a name argument,
#   emits '], "name": ['.
#
# @arg $1 string Optional: '-n'/'--no-bracket' to omit the leading bracket
# @arg $2 string Optional: array name
#
# @stdout Array transition bracket(s)
# @exitcode 0 Always
json_append_arr() {
  case "${1}" in
    (-n|--no-bracket)
      case "${2}" in
        ('')  printf -- '%s' ",[" ;;
        (*)   shift 1; printf -- ', "%s": [' "${*}" ;;
      esac
    ;;
    ('')  printf -- '%s' "],[" ;;
    (*)   printf -- '], "%s": [' "${*}" ;;
  esac
}

# @description Emit an opening object brace. With a name argument, emits '"name": {'.
#   Without an argument, emits '{'.
#
# @arg $1 string Optional: object name
#
# @stdout '"name": {' or '{'
# @exitcode 0 Always
json_open_obj() {
  case "${1}" in
    ('')  printf -- '%s' "{" ;;
    (*)   printf -- '"%s": {' "${*}" ;;
  esac
}

# @description Emit a closing object brace. With '-c' or '--comma', appends a trailing comma.
#
# @arg $1 string Optional: '-c' or '--comma' to append a trailing comma
#
# @stdout '}' or '},'
# @exitcode 0 Always
# shellcheck disable=SC2120
json_close_obj() {
  case "${1}" in
    (-c|--comma)  printf -- '%s,' "}" ;;
    (''|*)        printf -- '%s' "}" ;;
  esac
}

# @description Emit a closing-then-opening object brace sequence to chain objects.
#   With '-n' or '--no-bracket', the leading '}' is omitted. With a name argument,
#   emits '}, "name": {'.
#
# @arg $1 string Optional: '-n'/'--no-bracket' to omit the leading brace
# @arg $2 string Optional: object name
#
# @stdout Object transition brace(s)
# @exitcode 0 Always
json_append_obj() {
  case "${1}" in
    (-n|--no-bracket)
      case "${2}" in
        ('')  printf -- '%s' ",{" ;;
        (*)   shift 1; printf -- ', "%s": {' "${*}" ;;
      esac
    ;;
    ('')  printf -- '%s' "},{" ;;
    (*)   printf -- '}, "%s": {' "${*}" ;;
  esac
}

# @description Escape characters that must be escaped in JSON strings. Reads from stdin.
#   Converts input to octals and substitutes control characters and special characters
#   with their JSON escape sequences. Modified from https://stackoverflow.com/a/23166624
#
# @example
#   printf '%s' 'hello "world"' | json_escape_str
#
# @stdout JSON-escaped string
# @exitcode 0 Always
# shellcheck disable=SC2059
json_escape_str() {
  local _char
  od -A n -t o1 -v | tr ' \t' '\n' | grep . |
    while read -r _char; do
      case "${_char}" in
        ('00[0-7]')  printf -- '\u00%s' "${_char}" ;;
        ('02[0-7]')  printf -- '\u00%s' "$(( "10#${_char}" - 10 ))" ;;
        ('010')      printf -- '%s' "\b" ;;
        ('011')      printf -- '%s' "\t" ;;
        ('012')      printf -- '%s' "\n" ;;
        ('013')      printf -- '\u00%s' "0B" ;;
        ('014')      printf -- '%s' "\f" ;;
        ('015')      printf -- '%s' "\r" ;;
        ('016')      printf -- '\u00%s' "0E" ;;
        ('017')      printf -- '\u00%s' "0F" ;;
        ('030')      printf -- '\u00%s' "18" ;;
        ('031')      printf -- '\u00%s' "19" ;;
        ('042')      printf -- '%s' "\\\"" ;;
        #('047')      printf -- '%s' "\'" ;;
        #('057')      printf -- '%s' "\/" ;;
        ('134')      printf -- '%s' "\\" ;;
        (''|*)       printf -- "\\${_char}" ;;
      esac
    done
}

# @description Emit a JSON string keypair. With '-c' or '--comma', appends a trailing comma.
#   If the value is blank or literally 'null', emits null (unquoted).
#
# @arg $1 string Optional: '-c'/'--comma' for trailing comma, otherwise the key
# @arg $2 string Value (or key if $1 is a flag)
#
# @example
#   json_str name Alice          # => "name": "Alice"
#   json_str -c name Alice       # => "name": "Alice",
#
# @stdout '"key": "value"' or '"key": null'
# @exitcode 0 Always
json_str() {
  local _comma _key
  case "${1}" in
    (-c|--comma) shift 1; _comma="," ;;
    (*)          _comma="" ;;
  esac
  _key="$(json_sanitise "${1:-null}")"
  case "${2}" in
    (null|'') printf -- '"%s": %s%s' "${_key}" "null" "${_comma}" ;;
    (*)       shift 1; printf -- '"%s": "%s"%s' "${_key}" "${*}" "${_comma}" ;;
  esac
}

# @description Emit a comma-prefixed JSON string keypair for stacking inside an object.
#   If the value is blank or literally 'null', emits null (unquoted).
#
# @arg $1 string Key
# @arg $2 string Value
#
# @stdout ', "key": "value"' or ', "key": null'
# @exitcode 0 Always
json_append_str() {
  local _key
  _key="$(json_sanitise "${1:-null}")"
  case "${2}" in
    (null|'') printf -- ', "%s": %s' "${_key}" "null" ;;
    (*)       shift; printf -- ', "%s": "%s"' "${_key}" "${*}" ;;
  esac
}

# @description Emit a JSON number keypair. Numbers are unquoted. With '-c' or '--comma',
#   appends a trailing comma. Integers strip leading zeros; floats use 2 decimal places.
#   If the value is not a number, calls json_die().
#
# @arg $1 string Optional: '-c'/'--comma' for trailing comma, otherwise the key
# @arg $2 string Numeric value
#
# @example
#   json_num count 42            # => "count": 42
#   json_num ratio 3.14          # => "ratio": 3.14
#
# @stdout '"key": value' or '"key": null'
# @exitcode 0 Always
# @exitcode 1 If value is not a number
json_num() {
  local _comma _key _value
  case "${1}" in
    (-c|--comma) shift 1; _comma="," ;;
    (*)          _comma="" ;;
  esac
  _key="$(json_sanitise "${1}")"
  _value="$(json_sanitise "${2:-null}")"
  case "${_value}" in
    (''|null)
      printf -- '"%s": %s%s' "${_key}" "null" "${_comma}"
    ;;
    (*[!0-9.]*)
      json_die "Value '${_value}' not a number"
    ;;
    (*[0-9][.][0-9]*)
      printf -- '"%s": %.2f%s' "${_key}" "${_value}" "${_comma}"
    ;;
    (*)
      # We strip any leading zeros as json doesn't support them (i.e. octal)
      printf -- '"%s": %.0f%s' "${_key}" "${_value}" "${_comma}"
    ;;
  esac
}

# @description Emit a comma-prefixed JSON number keypair for stacking inside an object.
#   Numbers are unquoted. If the value is blank or null, emits null (unquoted).
#
# @arg $1 string Key
# @arg $2 string Numeric value
#
# @stdout ', "key": value' or ', "key": null'
# @exitcode 0 Always
# @exitcode 1 If value is not a number
json_append_num() {
  local _key _value
  _key="$(json_sanitise "${1}")"
  _value="$(json_sanitise "${2:-null}")"
  case "${_value}" in
    (''|null)
      printf -- ', "%s": %s' "${_key}" "null"
    ;;
    (*[!0-9.]*)
      json_die "Value '${_value}' not a number"
    ;;
    (*[0-9][.][0-9]*)
      printf -- ', "%s": %.2f' "${_key}" "${_value}"
    ;;
    (*)
      printf -- ', "%s": %.0f' "${_key}" "${_value}"
    ;;
  esac
}

# @description Emit a JSON boolean keypair. Booleans are unquoted. With '-c' or '--comma',
#   appends a trailing comma. Accepts true/false/yes/no/on/off (case-insensitive).
#   Calls json_die() if the value is not a recognised boolean.
#
# @arg $1 string Optional: '-c'/'--comma' for trailing comma, otherwise the key
# @arg $2 string Boolean value (true/false/yes/no/on/off)
#
# @stdout '"key": true' or '"key": false'
# @exitcode 0 Always
# @exitcode 1 If value is not a recognised boolean
json_bool() {
  local _comma _key _value _bool
  case "${1}" in
    (-c|--comma) shift 1; _comma="," ;;
    (*)          _comma="" ;;
  esac
  _key="$(json_sanitise "${1:-null}")"
  _value="$(json_sanitise "${2:-null}")"
  case "${_value}" in
    ([tT][rR][uU][eE])     _bool=true ;;
    ([fF][aA][lL][sS][eE]) _bool=false ;;
    ([yY][eE][sS])         _bool=true ;;
    ([nN][oO])             _bool=false ;;
    ([oO][nN])             _bool=true ;;
    ([oO][fF][fF])         _bool=false ;;
    (*)                    json_die "Value not a recognised boolean" ;;
  esac
  printf -- '"%s": %s%s' "${_key}" "${_bool}" "${_comma}"
}

# @description Emit a comma-prefixed JSON boolean keypair for stacking inside an object.
#   Accepts true/false/yes/no/on/off (case-insensitive). Calls json_die() for unrecognised values.
#
# @arg $1 string Key
# @arg $2 string Boolean value (true/false/yes/no/on/off)
#
# @stdout ', "key": true' or ', "key": false'
# @exitcode 0 Always
# @exitcode 1 If value is not a recognised boolean
json_append_bool() {
  local _key _value _bool
  _key="$(json_sanitise "${1:-null}")"
  _value="$(json_sanitise "${2:-null}")"
  case "${_value}" in
    ([tT][rR][uU][eE])     _bool=true ;;
    ([fF][aA][lL][sS][eE]) _bool=false ;;
    ([yY][eE][sS])         _bool=true ;;
    ([nN][oO])             _bool=false ;;
    ([oO][nN])             _bool=true ;;
    ([oO][fF][fF])         _bool=false ;;
    (*)                    json_die "Value not a recognised boolean" ;;
  esac
  printf -- ', "%s": %s' "${_key}" "${_bool}"
}

# @description Emit a JSON keypair, automatically selecting the correct type function
#   (json_num, json_bool, or json_str) based on the value. Experimental.
#
# @arg $1 string Key
# @arg $2 string Value
#
# @stdout JSON keypair in the appropriate format
# @exitcode 0 Always
json_auto() {
  local _key _value
  _key="$(json_sanitise "${1}")"
  _value="$(json_sanitise "${2:-null}")"
  case "$(json_gettype "${_value}")" in
    (int|float) json_num "${_key}" "${_value}" ;;
    (bool)      json_bool "${_key}" "${_value}" ;;
    (string)    json_str "${_key}" "${_value}" ;;
  esac
}

# @description Emit a comma-prefixed JSON keypair, automatically selecting the correct
#   type function. Experimental.
#
# @arg $1 string Key
# @arg $2 string Value
#
# @stdout Comma-prefixed JSON keypair in the appropriate format
# @exitcode 0 Always
json_append_auto() {
  local _key _value
  _key="$(json_sanitise "${1}")"
  _value="$(json_sanitise "${2:-null}")"
  case "$(json_gettype "${_value}")" in
    (int|float) json_append_num "${_key}" "${_value}" ;;
    (bool)      json_append_bool "${_key}" "${_value}" ;;
    (string)    json_append_str "${_key}" "${_value}" ;;
  esac
}

# @description Parse a delimited key-value pair (using ':' or '=') and emit its
#   key and value as separate quoted words suitable for passing to json_str() or json_num().
#
# @arg $1 string Delimited key-value pair (e.g. 'Bytes: 22' or 'Bytes=22')
#
# @example
#   json_num $(json_from_dkvp "Bytes: 22")   # => "Bytes": 22
#
# @stdout '"key" "value"'
# @exitcode 0 Always
# @exitcode 1 Line has no recognised delimiter (': ' or '=')
json_from_dkvp() {
  local _line _key _value
  _line="${*}"
  case "${_line}" in
    (*:*)
      _key="${_line%%:*}"
      _value="${_line##*:}"
    ;;
    (*=*)
      _key="${_line%%=*}"
      _value="${_line##*=}"
    ;;
    (*)
      printf -- 'json_from_dkvp: unrecognised format (no : or = delimiter): %s\n' "${_line}" >&2
      return 1
    ;;
  esac
  _key="$(json_sanitise "${_key}")"
  _value="$(json_sanitise "${_value}")"
  printf -- '"%s" "%s"' "${_key}" "${_value}"
}

# @description Emit a JSON array keypair whose values are auto-typed.
#   Integers, floats, and booleans are unquoted; everything else is quoted.
#   With '-c' or '--comma', appends a trailing comma.
#
# @arg $1 string Optional: '-c'/'--comma' for trailing comma, otherwise the key
# @arg $2 string Key (when $1 is a flag)
# @arg $@ string Values to include in the array
#
# @example
#   json_val_arr tags foo bar         # => "tags": ["foo","bar"]
#   json_val_arr counts 1 2 3         # => "counts": [1,2,3]
#   json_val_arr flags true false     # => "flags": [true,false]
#
# @stdout '"key": [values...]'
# @exitcode 0 Always
json_val_arr() {
  local _comma _key _value _iter_count _bool
  case "${1}" in
    (-c|--comma) shift 1; _comma="," ;;
    (*)          _comma="" ;;
  esac
  _key="$(json_sanitise "${1:?No key given}")"
  shift 1
  _iter_count=0
  printf -- '"%s": [' "${_key}"
  for _value in "${@}"; do
    (( _iter_count > 0 )) && printf -- '%s' ","
    case "$(json_gettype "${_value}")" in
      (int|float)
        printf -- '%s' "${_value}"
      ;;
      (bool)
        case "${_value}" in
          ([tT][rR][uU][eE]|[yY][eE][sS]|[oO][nN])    printf -- '%s' "true" ;;
          ([fF][aA][lL][sS][eE]|[nN][oO]|[oO][fF][fF]) printf -- '%s' "false" ;;
        esac
      ;;
      (string|''|*)
        printf -- '"%s"' "${_value}"
      ;;
    esac
    (( _iter_count++ ))
  done
  printf -- ']%s' "${_comma}"
}

# @description Comma-prefixed variant of json_val_arr for stacking inside an object.
#
# @arg $1 string Key
# @arg $@ string Values to include in the array
#
# @stdout ', "key": [values...]'
# @exitcode 0 Always
json_append_val_arr() {
  printf -- '%s' ", "
  json_val_arr "${@}"
}

# @description Emit a complete JSON object from a flat list of alternating key-value pairs.
#   Automatically selects the correct type function for each value. With '-n'/'--name',
#   wraps the object under a named key.
#   Delegates to json_readloop for the iteration logic.
#
# @arg $1 string Optional: '-n'/'--name' followed by an object name
# @arg $@ string Alternating key value pairs
#
# @example
#   json_foreach a b c d         # => {"a": "b", "c": "d"}
#   json_foreach -n root a b     # => {"root": {"a": "b"}}
#
# @stdout Complete JSON object
# @exitcode 0 Always
# shellcheck disable=SC2048,SC2086,SC2183
json_foreach() {
  local _name
  case "${1}" in
    (-n|--name)
      _name="${2}"
      shift 2
      printf -- '%s' "{"
      printf -- '%s %s\n' ${*} | json_readloop --name "${_name}"
      printf -- '%s' "}"
    ;;
    (*)
      printf -- '%s %s\n' ${*} | json_readloop
    ;;
  esac
}

# @description Read key-value pairs from a file or stdin and emit a JSON object.
#   Automatically selects the correct type function for each value.
#   Preliminary implementation — do not use in production.
#
# @arg $1 string Optional: '-n'/'--name' followed by an object name, or a file path
#
# @stdout JSON object built from input key-value pairs
# @exitcode 0 Always
json_readloop() {
  local _loop_iter _key _value
  _loop_iter=0
  case "${1}" in
    (-n|--name) json_open_obj "${2}"; shift 2 ;;
    (*)         json_open_obj ;;
  esac
  while read -r _key _value; do
    _key="$(json_sanitise "${_key}")"
    _value="$(json_sanitise "${_value}")"

    if (( _loop_iter == 0 )); then
      case "$(json_gettype "${_value}")" in
        (int|float) json_num "${_key}" "${_value}" ;;
        (bool)      json_bool "${_key}" "${_value}" ;;
        (string)    json_str "${_key}" "${_value}" ;;
      esac
      (( _loop_iter++ ))
    else
      case "$(json_gettype "${_value}")" in
        (int|float) json_append_num "${_key}" "${_value}" ;;
        (bool)      json_append_bool "${_key}" "${_value}" ;;
        (string)    json_append_str "${_key}" "${_value}" ;;
      esac
    fi
  done < "${1:-/dev/stdin}"
  json_close_obj
}

# @description Append a timestamp object to the current JSON output. Tries epoch first;
#   falls back to YYYYMMDDHHMMSS format if epoch is unavailable.
#
# @stdout JSON object: {"timestamp": {"utc_epoch": N}} or {"timestamp": {"utc_YYYYMMDDHHMMSS": N}}
# @exitcode 0 Always
json_timestamp() {
  json_append_obj --no-bracket timestamp
    case "$(date '+%s' 2>&1)" in
      (*[0-9]*) json_num utc_epoch "$(date -u '+%s')" ;;
      (*)       json_num utc_YYYYMMDDHHMMSS "$(date -u '+%Y%m%d%H%M%S')" ;;
    esac
  json_close_obj
}

# @description Pretty-print JSON from stdin using python3 or jq, whichever is available.
#   Falls back to cat if neither is found.
#
# @example
#   json_open; json_str foo bar; json_close | json_pretty
#
# @stdout Indented, human-readable JSON
# @exitcode 0 Always
json_pretty() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool
  elif command -v jq >/dev/null 2>&1; then
    jq .
  else
    cat
  fi
}

# @description Validate JSON from stdin using python3 or jq, whichever is available.
#   Prints nothing on success; prints an error message to stderr on failure.
#
# @example
#   json_open; json_str foo bar; json_close | json_validate
#
# @exitcode 0 Valid JSON
# @exitcode 1 Invalid JSON or no validator available
json_validate() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool >/dev/null
  elif command -v jq >/dev/null 2>&1; then
    jq . >/dev/null
  else
    printf -- '%s\n' "json_validate: no validator found (python3 or jq required)" >&2
    return 1
  fi
}

# @description Emit a JSON object from environment variables. With no arguments,
#   emits all environment variables. With arguments, emits only those named variables.
#
# @arg $@ string Optional: names of specific environment variables to include
#
# @example
#   json_from_env HOME SHELL       # => {"HOME": "/root", "SHELL": "/bin/bash"}
#   json_from_env                  # => all environment variables as a JSON object
#
# @stdout JSON object of environment variable keypairs
# @exitcode 0 Always
json_from_env() {
  local _iter_count _name _value
  _iter_count=0
  json_open_obj
  if (( "${#}" > 0 )); then
    for _name in "${@}"; do
      _value="${!_name}"
      if (( _iter_count == 0 )); then
        json_str "${_name}" "${_value}"
        (( _iter_count++ ))
      else
        json_append_str "${_name}" "${_value}"
      fi
    done
  else
    while IFS='=' read -r _name _value; do
      [[ -z "${_name}" ]] && continue
      if (( _iter_count == 0 )); then
        json_str "${_name}" "${_value}"
        (( _iter_count++ ))
      else
        json_append_str "${_name}" "${_value}"
      fi
    done < <(env)
  fi
  json_close_obj
}
