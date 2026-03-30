#!/usr/bin/env bats
# Tests for url_encode, url_decode, url_parse_query, url_get_param,
# url_build_query in lib/sh/net/url.sh

load 'helpers/setup'

# ---------------------------------------------------------------------------
# url_encode
# ---------------------------------------------------------------------------

@test "url_encode: unreserved chars pass through unchanged" {
  run shellac_run 'include "net/url"; url_encode "hello-world_test.~"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello-world_test.~" ]
}

@test "url_encode: space becomes %20" {
  run shellac_run 'include "net/url"; url_encode "hello world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello%20world" ]
}

@test "url_encode: special characters are encoded" {
  run shellac_run 'include "net/url"; url_encode "a=1&b=2"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a%3D1%26b%3D2" ]
}

@test "url_encode: empty string returns empty" {
  run shellac_run 'include "net/url"; url_encode ""'
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

# ---------------------------------------------------------------------------
# url_decode
# ---------------------------------------------------------------------------

@test "url_decode: decodes %20 to space" {
  run shellac_run 'include "net/url"; url_decode "hello%20world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello world" ]
}

@test "url_decode: converts + to space" {
  run shellac_run 'include "net/url"; url_decode "hello+world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello world" ]
}

@test "url_decode: decodes encoded special chars" {
  run shellac_run 'include "net/url"; url_decode "a%3D1%26b%3D2"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "a=1&b=2" ]
}

@test "url_encode then url_decode roundtrips" {
  run shellac_run 'include "net/url"
    original="hello world & stuff=things"
    encoded=$(url_encode "${original}")
    decoded=$(url_decode "${encoded}")
    [ "${decoded}" = "${original}" ]'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# url_parse_query
# ---------------------------------------------------------------------------

@test "url_parse_query: parses key=value pairs to lines" {
  run shellac_run 'include "net/url"; url_parse_query "name=Alice&city=Auckland"'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"name=Alice"* ]]
  [[ "${output}" = *"city=Auckland"* ]]
}

@test "url_parse_query: strips leading ?" {
  run shellac_run 'include "net/url"; url_parse_query "?foo=bar"'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"foo=bar"* ]]
}

@test "url_parse_query: decodes percent-encoded values" {
  run shellac_run 'include "net/url"; url_parse_query "q=hello%20world"'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"q=hello world"* ]]
}

@test "url_parse_query -n: populates associative array" {
  run shellac_run 'include "net/url"
    declare -A p
    url_parse_query -n p "name=Alice&city=Auckland"
    printf "%s\n" "${p[name]}" "${p[city]}"'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"Alice"* ]]
  [[ "${output}" = *"Auckland"* ]]
}

@test "url_parse_query: missing argument exits non-zero" {
  run shellac_run 'include "net/url"; url_parse_query'
  [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# url_get_param
# ---------------------------------------------------------------------------

@test "url_get_param: returns value for existing key" {
  run shellac_run 'include "net/url"; url_get_param "name=Alice&city=Auckland" name'
  [ "${status}" -eq 0 ]
  [ "${output}" = "Alice" ]
}

@test "url_get_param: returns 1 for missing key" {
  run shellac_run 'include "net/url"; url_get_param "name=Alice" nosuchkey'
  [ "${status}" -eq 1 ]
}

@test "url_get_param: decodes percent-encoded value" {
  run shellac_run 'include "net/url"; url_get_param "q=hello%20world" q'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello world" ]
}

@test "url_get_param: strips leading ?" {
  run shellac_run 'include "net/url"; url_get_param "?foo=bar" foo'
  [ "${status}" -eq 0 ]
  [ "${output}" = "bar" ]
}

# ---------------------------------------------------------------------------
# url_build_query
# ---------------------------------------------------------------------------

@test "url_build_query: builds query string from key=value args" {
  run shellac_run 'include "net/url"; url_build_query name=Alice city=Auckland'
  [ "${status}" -eq 0 ]
  [ "${output}" = "name=Alice&city=Auckland" ]
}

@test "url_build_query: encodes spaces in values" {
  run shellac_run 'include "net/url"; url_build_query "q=hello world"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "q=hello%20world" ]
}

@test "url_build_query: single pair" {
  run shellac_run 'include "net/url"; url_build_query lang=en'
  [ "${status}" -eq 0 ]
  [ "${output}" = "lang=en" ]
}

@test "url_build_query: no arguments exits 1" {
  run shellac_run 'include "net/url"; url_build_query'
  [ "${status}" -eq 1 ]
}

@test "url_build_query then url_parse_query roundtrips" {
  run shellac_run 'include "net/url"
    qs=$(url_build_query "q=hello world" lang=en)
    url_get_param "${qs}" q'
  [ "${status}" -eq 0 ]
  [ "${output}" = "hello world" ]
}
