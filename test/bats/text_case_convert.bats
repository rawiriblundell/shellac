#!/usr/bin/env bats
# Tests for str_snake_case, str_camel_case, str_kebab_case, str_slug,
# str_altcaps, str_ucfirst, str_lcfirst, str_ucwords, str_title_case
# in lib/sh/text/case_convert.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# str_snake_case
# ---------------------------------------------------------------------------

@test "str_snake_case: space-separated words" {
  run shellac_run 'include "text/case_convert"; str_snake_case "Hello World"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello_world" ]
}

@test "str_snake_case: camelCase input" {
  run shellac_run 'include "text/case_convert"; str_snake_case "fooBar"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foo_bar" ]
}

@test "str_snake_case: kebab-case input" {
  run shellac_run 'include "text/case_convert"; str_snake_case "kebab-case"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "kebab_case" ]
}

# ---------------------------------------------------------------------------
# str_camel_case
# ---------------------------------------------------------------------------

@test "str_camel_case: space-separated words" {
  run shellac_run 'include "text/case_convert"; str_camel_case "hello world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "helloWorld" ]
}

@test "str_camel_case: underscore-separated words" {
  run shellac_run 'include "text/case_convert"; str_camel_case "foo_bar_baz"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "fooBarBaz" ]
}

@test "str_camel_case: kebab-case input" {
  run shellac_run 'include "text/case_convert"; str_camel_case "kebab-case"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "kebabCase" ]
}

# ---------------------------------------------------------------------------
# str_kebab_case
# ---------------------------------------------------------------------------

@test "str_kebab_case: space-separated words" {
  run shellac_run 'include "text/case_convert"; str_kebab_case "Hello World"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello-world" ]
}

@test "str_kebab_case: camelCase input" {
  run shellac_run 'include "text/case_convert"; str_kebab_case "fooBar"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "foo-bar" ]
}

@test "str_kebab_case: snake_case input" {
  run shellac_run 'include "text/case_convert"; str_kebab_case "snake_case"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "snake-case" ]
}

# ---------------------------------------------------------------------------
# str_slug
# ---------------------------------------------------------------------------

@test "str_slug: basic phrase" {
  run shellac_run 'include "text/case_convert"; str_slug "Hello, World!"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello-world" ]
}

@test "str_slug: multiple words" {
  run shellac_run 'include "text/case_convert"; str_slug "My Blog Post Title"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "my-blog-post-title" ]
}

@test "str_slug: leading and trailing spaces trimmed" {
  run shellac_run 'include "text/case_convert"; str_slug "  extra  spaces  "'
  [ "${status}" -eq 0 ]
  [ "${output}" = "extra-spaces" ]
}

# ---------------------------------------------------------------------------
# str_ucfirst
# ---------------------------------------------------------------------------

@test "str_ucfirst: uppercases first character" {
  run shellac_run 'include "text/case_convert"; str_ucfirst "hello world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello world" ]
}

@test "str_ucfirst: already-uppercase string is unchanged" {
  run shellac_run 'include "text/case_convert"; str_ucfirst "Hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello" ]
}

# ---------------------------------------------------------------------------
# str_lcfirst
# ---------------------------------------------------------------------------

@test "str_lcfirst: lowercases first character" {
  run shellac_run 'include "text/case_convert"; str_lcfirst "Hello World"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello World" ]
}

@test "str_lcfirst: already-lowercase string is unchanged" {
  run shellac_run 'include "text/case_convert"; str_lcfirst "hello"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello" ]
}

# ---------------------------------------------------------------------------
# str_ucwords
# ---------------------------------------------------------------------------

@test "str_ucwords: capitalises each word" {
  run shellac_run 'include "text/case_convert"; str_ucwords "hello world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello World" ]
}

@test "str_ucwords: single word" {
  run shellac_run 'include "text/case_convert"; str_ucwords "foo"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Foo" ]
}

# ---------------------------------------------------------------------------
# str_title_case
# ---------------------------------------------------------------------------

@test "str_title_case: snake_case to Title Case" {
  run shellac_run 'include "text/case_convert"; str_title_case "slice_drive_size"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Slice Drive Size" ]
}

@test "str_title_case: two-word snake_case" {
  run shellac_run 'include "text/case_convert"; str_title_case "foo_bar"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Foo Bar" ]
}

@test "str_title_case: empty input returns nothing" {
  run shellac_run 'include "text/case_convert"; str_title_case ""'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}
