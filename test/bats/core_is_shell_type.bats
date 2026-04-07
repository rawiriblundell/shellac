#!/usr/bin/env bats
# shellcheck disable=SC2317,BW01,BW02
# Tests for is_builtin, is_keyword, is_alias in lib/sh/core/is.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# is_builtin
# ---------------------------------------------------------------------------

@test "is_builtin: hash is a builtin" {
  run shellac_run 'include "core/is"; is_builtin hash'
  [ "${status}" -eq 0 ]
}

@test "is_builtin: printf is a builtin" {
  run shellac_run 'include "core/is"; is_builtin printf'
  [ "${status}" -eq 0 ]
}

@test "is_builtin: read is a builtin" {
  run shellac_run 'include "core/is"; is_builtin read'
  [ "${status}" -eq 0 ]
}

@test "is_builtin: cd is a builtin" {
  run shellac_run 'include "core/is"; is_builtin cd'
  [ "${status}" -eq 0 ]
}

@test "is_builtin: grep is not a builtin" {
  run shellac_run 'include "core/is"; is_builtin grep'
  [ "${status}" -eq 1 ]
}

@test "is_builtin: awk is not a builtin" {
  run shellac_run 'include "core/is"; is_builtin awk'
  [ "${status}" -eq 1 ]
}

@test "is_builtin: a nonsense name is not a builtin" {
  run shellac_run 'include "core/is"; is_builtin grobblegobble'
  [ "${status}" -eq 1 ]
}

@test "is_builtin: if is not a builtin (it is a keyword)" {
  run shellac_run 'include "core/is"; is_builtin if'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# is_keyword
# ---------------------------------------------------------------------------

@test "is_keyword: if is a keyword" {
  run shellac_run 'include "core/is"; is_keyword if'
  [ "${status}" -eq 0 ]
}

@test "is_keyword: while is a keyword" {
  run shellac_run 'include "core/is"; is_keyword while'
  [ "${status}" -eq 0 ]
}

@test "is_keyword: case is a keyword" {
  run shellac_run 'include "core/is"; is_keyword case'
  [ "${status}" -eq 0 ]
}

@test "is_keyword: then is a keyword" {
  run shellac_run 'include "core/is"; is_keyword then'
  [ "${status}" -eq 0 ]
}

@test "is_keyword: do is a keyword" {
  run shellac_run 'include "core/is"; is_keyword do'
  [ "${status}" -eq 0 ]
}

@test "is_keyword: grep is not a keyword" {
  run shellac_run 'include "core/is"; is_keyword grep'
  [ "${status}" -eq 1 ]
}

@test "is_keyword: printf is not a keyword (it is a builtin)" {
  run shellac_run 'include "core/is"; is_keyword printf'
  [ "${status}" -eq 1 ]
}

@test "is_keyword: a nonsense name is not a keyword" {
  run shellac_run 'include "core/is"; is_keyword grobblegobble'
  [ "${status}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# is_alias
# Note: aliases are not inherited by non-interactive subshells.
# is_alias will return false for any name in a clean subprocess unless
# the alias is explicitly defined in the same shell session.
# ---------------------------------------------------------------------------

@test "is_alias: undefined name is not an alias in non-interactive shell" {
  run shellac_run 'include "core/is"; is_alias ll'
  [ "${status}" -eq 1 ]
}

@test "is_alias: inline-defined alias is detected" {
  run shellac_run 'include "core/is"; shopt -s expand_aliases; alias testalias="true"; is_alias testalias'
  [ "${status}" -eq 0 ]
}

@test "is_alias: builtin name with no alias definition is not an alias" {
  run shellac_run 'include "core/is"; is_alias printf'
  [ "${status}" -eq 1 ]
}

@test "is_alias: external command with no alias definition is not an alias" {
  run shellac_run 'include "core/is"; is_alias grep'
  [ "${status}" -eq 1 ]
}
