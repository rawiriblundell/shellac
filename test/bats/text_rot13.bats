#!/usr/bin/env bats
# Tests for rot13 in lib/sh/text/rot13.sh

load 'helpers/setup'

@test "rot13: encodes a simple string argument" {
  run shellac_run 'include "text/rot13"; rot13 "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "uryyb" ]
}

@test "rot13: encoding is its own inverse (double rot13 roundtrip)" {
  run shellac_run 'include "text/rot13"; rot13 "$(rot13 "Hello World")"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello World" ]
}

@test "rot13: encodes via stdin" {
  run shellac_run 'include "text/rot13"; printf "hello\n" | rot13'
  [ "${status}" -eq 0 ]
  [ "${output}" = "uryyb" ]
}

@test "rot13: preserves non-alpha characters" {
  run shellac_run 'include "text/rot13"; rot13 "hello, world! 123"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "uryyb, jbeyq! 123" ]
}

@test "rot13: no args with no stdin reads empty stdin and exits 0" {
  run shellac_run 'include "text/rot13"; rot13 </dev/null'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}
