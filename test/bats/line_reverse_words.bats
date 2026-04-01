#!/usr/bin/env bats
# Tests for line/reverse_words in lib/sh/line/reverse_words.sh

load 'helpers/setup'

@test "line_reverse_words: reverses order of words" {
  run shellac_run 'include "line/reverse_words"; line_reverse_words one two three'
  [ "${status}" -eq 0 ]
  [ "${output}" = "three two one" ]
}

@test "line_reverse_words: single word is returned unchanged" {
  run shellac_run 'include "line/reverse_words"; line_reverse_words only'
  [ "${status}" -eq 0 ]
  [ "${output}" = "only" ]
}

@test "line_reverse_words: two words are swapped" {
  run shellac_run 'include "line/reverse_words"; line_reverse_words alpha beta'
  [ "${status}" -eq 0 ]
  [ "${output}" = "beta alpha" ]
}

@test "line_reverse_words: no args produces empty-ish output" {
  run shellac_run 'include "line/reverse_words"; line_reverse_words'
  [ "${status}" -eq 0 ]
}
