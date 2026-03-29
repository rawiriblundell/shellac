#!/usr/bin/env bats
# Tests for str_is_int, str_is_hex, str_is_base64, str_is_upper, str_is_lower
# in lib/sh/text/predicates.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# str_is_int
# ---------------------------------------------------------------------------

@test "str_is_int: plain positive integer passes" {
  run shellac_run 'include "text/predicates"; str_is_int "42"'
  [ "${status}" -eq 0 ]
}

@test "str_is_int: zero passes" {
  run shellac_run 'include "text/predicates"; str_is_int "0"'
  [ "${status}" -eq 0 ]
}

@test "str_is_int: negative integer passes" {
  run shellac_run 'include "text/predicates"; str_is_int "-7"'
  [ "${status}" -eq 0 ]
}

@test "str_is_int: negative zero passes" {
  run shellac_run 'include "text/predicates"; str_is_int "-0"'
  [ "${status}" -eq 0 ]
}

@test "str_is_int: empty string fails" {
  run shellac_run 'include "text/predicates"; str_is_int ""'
  [ "${status}" -eq 1 ]
}

@test "str_is_int: bare minus fails" {
  run shellac_run 'include "text/predicates"; str_is_int "-"'
  [ "${status}" -eq 1 ]
}

@test "str_is_int: unary plus fails" {
  run shellac_run 'include "text/predicates"; str_is_int "+7"'
  [ "${status}" -eq 1 ]
}

@test "str_is_int: float fails" {
  run shellac_run 'include "text/predicates"; str_is_int "3.14"'
  [ "${status}" -eq 1 ]
}

@test "str_is_int: alphanumeric fails" {
  run shellac_run 'include "text/predicates"; str_is_int "42abc"'
  [ "${status}" -eq 1 ]
}

@test "str_is_int: double minus fails" {
  run shellac_run 'include "text/predicates"; str_is_int "--5"'
  [ "${status}" -eq 1 ]
}

@test "str_is_int: reads from stdin" {
  run shellac_run 'include "text/predicates"; printf "%s" "99" | str_is_int'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# str_is_hex
# ---------------------------------------------------------------------------

@test "str_is_hex: lowercase hex passes" {
  run shellac_run 'include "text/predicates"; str_is_hex "deadbeef"'
  [ "${status}" -eq 0 ]
}

@test "str_is_hex: uppercase hex passes" {
  run shellac_run 'include "text/predicates"; str_is_hex "DEADBEEF"'
  [ "${status}" -eq 0 ]
}

@test "str_is_hex: mixed case passes" {
  run shellac_run 'include "text/predicates"; str_is_hex "DeAdBeEf"'
  [ "${status}" -eq 0 ]
}

@test "str_is_hex: 0x prefix passes" {
  run shellac_run 'include "text/predicates"; str_is_hex "0xff"'
  [ "${status}" -eq 0 ]
}

@test "str_is_hex: 0X prefix passes" {
  run shellac_run 'include "text/predicates"; str_is_hex "0XFF"'
  [ "${status}" -eq 0 ]
}

@test "str_is_hex: bare 0x fails (no digits after prefix)" {
  run shellac_run 'include "text/predicates"; str_is_hex "0x"'
  [ "${status}" -eq 1 ]
}

@test "str_is_hex: empty string fails" {
  run shellac_run 'include "text/predicates"; str_is_hex ""'
  [ "${status}" -eq 1 ]
}

@test "str_is_hex: non-hex chars fail" {
  run shellac_run 'include "text/predicates"; str_is_hex "0xGG"'
  [ "${status}" -eq 1 ]
}

@test "str_is_hex: decimal-only string passes (digits are valid hex)" {
  run shellac_run 'include "text/predicates"; str_is_hex "1234"'
  [ "${status}" -eq 0 ]
}

@test "str_is_hex: reads from stdin" {
  run shellac_run 'include "text/predicates"; printf "%s" "ff" | str_is_hex'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# str_is_base64
# ---------------------------------------------------------------------------

@test "str_is_base64: valid standard base64 no padding" {
  run shellac_run 'include "text/predicates"; str_is_base64 "YWJj"'
  [ "${status}" -eq 0 ]
}

@test "str_is_base64: valid base64 with one padding char" {
  run shellac_run 'include "text/predicates"; str_is_base64 "YWJjZA=="'
  [ "${status}" -eq 0 ]
}

@test "str_is_base64: valid base64 with two padding chars" {
  run shellac_run 'include "text/predicates"; str_is_base64 "YQ=="'
  [ "${status}" -eq 0 ]
}

@test "str_is_base64: standard alphabet with + and /" {
  run shellac_run 'include "text/predicates"; str_is_base64 "ab+/YQ=="'
  [ "${status}" -eq 0 ]
}

@test "str_is_base64: URL-safe alphabet with _ and -" {
  run shellac_run 'include "text/predicates"; str_is_base64 "YWJj_-=="'
  [ "${status}" -eq 0 ]
}

@test "str_is_base64: length not multiple of 4 fails" {
  run shellac_run 'include "text/predicates"; str_is_base64 "YQ"'
  [ "${status}" -eq 1 ]
}

@test "str_is_base64: three padding chars fails (over-padded)" {
  run shellac_run 'include "text/predicates"; str_is_base64 "a==="'
  [ "${status}" -eq 1 ]
}

@test "str_is_base64: embedded = fails" {
  run shellac_run 'include "text/predicates"; str_is_base64 "ab=c"'
  [ "${status}" -eq 1 ]
}

@test "str_is_base64: invalid chars fail" {
  run shellac_run 'include "text/predicates"; str_is_base64 "ab!@"'
  [ "${status}" -eq 1 ]
}

@test "str_is_base64: empty string fails" {
  run shellac_run 'include "text/predicates"; str_is_base64 ""'
  [ "${status}" -eq 1 ]
}

@test "str_is_base64: reads from stdin" {
  run shellac_run 'include "text/predicates"; printf "%s" "YWJj" | str_is_base64'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# str_is_upper
# ---------------------------------------------------------------------------

@test "str_is_upper: all uppercase passes" {
  run shellac_run 'include "text/predicates"; str_is_upper "HELLO"'
  [ "${status}" -eq 0 ]
}

@test "str_is_upper: uppercase with digits passes" {
  run shellac_run 'include "text/predicates"; str_is_upper "HELLO123"'
  [ "${status}" -eq 0 ]
}

@test "str_is_upper: digits only passes (no letters to be wrong)" {
  run shellac_run 'include "text/predicates"; str_is_upper "123"'
  [ "${status}" -eq 0 ]
}

@test "str_is_upper: empty string passes" {
  run shellac_run 'include "text/predicates"; str_is_upper ""'
  [ "${status}" -eq 0 ]
}

@test "str_is_upper: mixed case fails" {
  run shellac_run 'include "text/predicates"; str_is_upper "Hello"'
  [ "${status}" -eq 1 ]
}

@test "str_is_upper: all lowercase fails" {
  run shellac_run 'include "text/predicates"; str_is_upper "hello"'
  [ "${status}" -eq 1 ]
}

@test "str_is_upper: uppercase with lowercase word fails" {
  run shellac_run 'include "text/predicates"; str_is_upper "HELLO world"'
  [ "${status}" -eq 1 ]
}

@test "str_is_upper: reads from stdin" {
  run shellac_run 'include "text/predicates"; printf "%s" "ABC" | str_is_upper'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# str_is_lower
# ---------------------------------------------------------------------------

@test "str_is_lower: all lowercase passes" {
  run shellac_run 'include "text/predicates"; str_is_lower "hello"'
  [ "${status}" -eq 0 ]
}

@test "str_is_lower: lowercase with digits passes" {
  run shellac_run 'include "text/predicates"; str_is_lower "hello123"'
  [ "${status}" -eq 0 ]
}

@test "str_is_lower: digits only passes (no letters to be wrong)" {
  run shellac_run 'include "text/predicates"; str_is_lower "123"'
  [ "${status}" -eq 0 ]
}

@test "str_is_lower: empty string passes" {
  run shellac_run 'include "text/predicates"; str_is_lower ""'
  [ "${status}" -eq 0 ]
}

@test "str_is_lower: mixed case fails" {
  run shellac_run 'include "text/predicates"; str_is_lower "Hello"'
  [ "${status}" -eq 1 ]
}

@test "str_is_lower: all uppercase fails" {
  run shellac_run 'include "text/predicates"; str_is_lower "HELLO"'
  [ "${status}" -eq 1 ]
}

@test "str_is_lower: lowercase with uppercase word fails" {
  run shellac_run 'include "text/predicates"; str_is_lower "hello WORLD"'
  [ "${status}" -eq 1 ]
}

@test "str_is_lower: reads from stdin" {
  run shellac_run 'include "text/predicates"; printf "%s" "abc" | str_is_lower'
  [ "${status}" -eq 0 ]
}
