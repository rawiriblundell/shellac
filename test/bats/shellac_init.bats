#!/usr/bin/env bats
# Tests for bin/shellac: init, path discovery, and SHELLAC_LOADED sentinel.

load 'helpers/setup'

setup() {
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

# ---------------------------------------------------------------------------
# SH_LIBPATH pre-set
# ---------------------------------------------------------------------------

@test "SH_LIBPATH pre-set: sourcing succeeds" {
  run shellac_run 'printf ok'
  [ "${status}" -eq 0 ]
}

@test "SH_LIBPATH pre-set: env value is present in resulting SH_LIBPATH" {
  run shellac_run 'printf "%s\n" "${SH_LIBPATH}"'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"${SHELLAC_LIB}"* ]]
}

@test "SH_LIBPATH pre-set: SH_LIBPATH_ARRAY contains the pre-set path" {
  run bash -c "
    export SH_LIBPATH='${SHELLAC_LIB}'
    source '${SHELLAC_BIN}'
    found=0
    for p in \"\${SH_LIBPATH_ARRAY[@]}\"; do
      [ \"\${p}\" = '${SHELLAC_LIB}' ] && found=1
    done
    printf '%d\n' \"\${found}\"
  "
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "SH_LIBPATH pre-set: SH_LIBPATH_ARRAY contains only existing directories" {
  run shellac_run '
    for p in "${SH_LIBPATH_ARRAY[@]}"; do
      [ -d "${p}" ] || { printf "missing: %s\n" "${p}"; exit 1; }
    done
    printf ok
  '
  [ "${status}" -eq 0 ]
  [ "${output}" = "ok" ]
}

@test "SH_LIBPATH pre-set: multiple pre-set paths are each present in result" {
  run bash -c "
    export SH_LIBPATH='${SHELLAC_LIB}:${SHELLAC_LIB}'
    source '${SHELLAC_BIN}'
    # Deduplication must collapse the duplicate; SHELLAC_LIB should appear once
    count=\$(printf '%s\n' \"\${SH_LIBPATH_ARRAY[@]}\" | grep -cxF '${SHELLAC_LIB}')
    printf '%d\n' \"\${count}\"
  "
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

@test "discovery: valid path is added to SH_LIBPATH_ARRAY" {
  run bash -c "
    unset SH_LIBPATH
    export XDG_DATA_HOME='${TEST_TMPDIR}'
    mkdir -p '${TEST_TMPDIR}/shellac/lib/sh/core'
    cp '${SHELLAC_LIB}/core/include.sh' '${TEST_TMPDIR}/shellac/lib/sh/core/'
    cp '${SHELLAC_LIB}/core/requires.sh' '${TEST_TMPDIR}/shellac/lib/sh/core/'
    cp '${SHELLAC_LIB}/core/wants.sh' '${TEST_TMPDIR}/shellac/lib/sh/core/'
    source '${SHELLAC_BIN}'
    printf '%s\n' \"\${SH_LIBPATH_ARRAY[@]}\"
  "
  [ "${status}" -eq 0 ]
  # _self_libpath is now prepended during discovery, so the XDG path may not
  # be at index 0. Assert membership rather than position.
  [[ "${output}" == *"${TEST_TMPDIR}/shellac/lib/sh"* ]]
}

@test "discovery: missing path is silently skipped" {
  run bash -c "
    unset SH_LIBPATH
    export SH_LIBPATH='${SHELLAC_LIB}'
    source '${SHELLAC_BIN}'
    # SH_LIBPATH_ARRAY should only contain paths that actually exist
    for p in \"\${SH_LIBPATH_ARRAY[@]}\"; do
      [ -d \"\${p}\" ] || { printf 'missing: %s\n' \"\${p}\"; exit 1; }
    done
  "
  [ "${status}" -eq 0 ]
}

@test "discovery: XDG_DATA_HOME path is included" {
  local xdg_home_lib="${TEST_TMPDIR}/data_home/shellac/lib/sh"
  mkdir -p "${xdg_home_lib}/core"
  cp "${SHELLAC_LIB}/core/include.sh" "${xdg_home_lib}/core/"
  cp "${SHELLAC_LIB}/core/requires.sh" "${xdg_home_lib}/core/"
  cp "${SHELLAC_LIB}/core/wants.sh" "${xdg_home_lib}/core/"
  run bash -c "
    unset SH_LIBPATH
    export XDG_DATA_HOME='${TEST_TMPDIR}/data_home'
    source '${SHELLAC_BIN}'
    printf '%s\n' \"\${SH_LIBPATH}\"
  "
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"${xdg_home_lib}"* ]]
}

@test "discovery: XDG_DATA_DIRS paths are included" {
  local xdg_lib="${TEST_TMPDIR}/xdg/shellac/lib/sh"
  mkdir -p "${xdg_lib}/core"
  cp "${SHELLAC_LIB}/core/include.sh" "${xdg_lib}/core/"
  cp "${SHELLAC_LIB}/core/requires.sh" "${xdg_lib}/core/"
  cp "${SHELLAC_LIB}/core/wants.sh" "${xdg_lib}/core/"
  run bash -c "
    unset SH_LIBPATH
    export XDG_DATA_DIRS='${TEST_TMPDIR}/xdg'
    source '${SHELLAC_BIN}'
    printf '%s\n' \"\${SH_LIBPATH}\"
  "
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"${xdg_lib}"* ]]
}

@test "discovery: paths.conf entries are included in SH_LIBPATH" {
  # XDG_CONFIG_HOME: shellac appends /shellac internally, so point here not at shellac subdir
  local xdg_config="${TEST_TMPDIR}/.config"
  local extra_lib="${TEST_TMPDIR}/extra/lib/sh"
  mkdir -p "${xdg_config}/shellac" "${extra_lib}/core"
  cp "${SHELLAC_LIB}/core/include.sh" "${extra_lib}/core/"
  cp "${SHELLAC_LIB}/core/requires.sh" "${extra_lib}/core/"
  cp "${SHELLAC_LIB}/core/wants.sh" "${extra_lib}/core/"
  printf '%s\n' "${extra_lib}" > "${xdg_config}/shellac/paths.conf"
  run bash -c "
    unset SH_LIBPATH
    export HOME='${TEST_TMPDIR}'
    export XDG_CONFIG_HOME='${xdg_config}'
    source '${SHELLAC_BIN}'
    printf '%s\n' \"\${SH_LIBPATH}\"
  "
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"${extra_lib}"* ]]
}

@test "discovery: paths.conf entries are honoured even when SH_LIBPATH is pre-set" {
  local xdg_config="${TEST_TMPDIR}/.config"
  local extra_lib="${TEST_TMPDIR}/extra/lib/sh"
  mkdir -p "${xdg_config}/shellac" "${extra_lib}/core"
  cp "${SHELLAC_LIB}/core/include.sh" "${extra_lib}/core/"
  cp "${SHELLAC_LIB}/core/requires.sh" "${extra_lib}/core/"
  cp "${SHELLAC_LIB}/core/wants.sh" "${extra_lib}/core/"
  printf '%s\n' "${extra_lib}" > "${xdg_config}/shellac/paths.conf"
  run bash -c "
    export SH_LIBPATH='${SHELLAC_LIB}'
    export XDG_CONFIG_HOME='${xdg_config}'
    source '${SHELLAC_BIN}'
    printf '%s\n' \"\${SH_LIBPATH}\"
  "
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"${extra_lib}"* ]]
}

@test "discovery: paths.conf comments and blank lines are ignored" {
  local conf_dir="${TEST_TMPDIR}/.config/shellac"
  mkdir -p "${conf_dir}"
  printf '# this is a comment\n\n/nonexistent/path\n' > "${conf_dir}/paths.conf"
  run bash -c "
    unset SH_LIBPATH
    export SH_LIBPATH='${SHELLAC_LIB}'
    export XDG_CONFIG_HOME='${conf_dir}'
    source '${SHELLAC_BIN}'
    # /nonexistent/path should not appear in SH_LIBPATH_ARRAY
    for p in \"\${SH_LIBPATH_ARRAY[@]}\"; do
      [ \"\${p}\" = '/nonexistent/path' ] && exit 1
    done
    printf ok
  "
  [ "${status}" -eq 0 ]
  [ "${output}" = "ok" ]
}

# ---------------------------------------------------------------------------
# SHELLAC_LOADED sentinel
# ---------------------------------------------------------------------------

@test "SHELLAC_LOADED sentinel: prevents double-sourcing" {
  run bash -c "
    export SH_LIBPATH='${SHELLAC_LIB}'
    source '${SHELLAC_BIN}'
    first_stack_size=\${#SH_STACK[@]}
    source '${SHELLAC_BIN}'
    second_stack_size=\${#SH_STACK[@]}
    # Stack must not have grown on the second source
    [ \"\${first_stack_size}\" -eq \"\${second_stack_size}\" ] && printf ok
  "
  [ "${status}" -eq 0 ]
  [ "${output}" = "ok" ]
}

@test "SHELLAC_LOADED is set after sourcing" {
  run shellac_run 'printf "%s\n" "${SHELLAC_LOADED}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

# ---------------------------------------------------------------------------
# Execution guard
# ---------------------------------------------------------------------------

@test "executing shellac directly fails with an error message" {
  run bash "${SHELLAC_BIN}"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"must be sourced"* ]]
}
