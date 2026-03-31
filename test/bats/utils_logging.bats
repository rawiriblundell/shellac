#!/usr/bin/env bats
# Tests for utils/logging.sh — log_debug, log_info, log_warn, log_error,
# _log_level_num, and LOG_LEVEL filtering.

load 'helpers/setup'

# ---------------------------------------------------------------------------
# _log_level_num
# ---------------------------------------------------------------------------

@test "_log_level_num: DEBUG maps to 0" {
  run shellac_run 'include "utils/logging"; _log_level_num DEBUG'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "_log_level_num: INFO maps to 1" {
  run shellac_run 'include "utils/logging"; _log_level_num INFO'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "_log_level_num: WARN maps to 2" {
  run shellac_run 'include "utils/logging"; _log_level_num WARN'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "_log_level_num: ERROR maps to 3" {
  run shellac_run 'include "utils/logging"; _log_level_num ERROR'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "_log_level_num: unknown level maps to 1 (INFO)" {
  run shellac_run 'include "utils/logging"; _log_level_num BOGUS'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

# ---------------------------------------------------------------------------
# LOG_LEVEL default
# ---------------------------------------------------------------------------

@test "LOG_LEVEL defaults to INFO" {
  run shellac_run 'include "utils/logging"; printf "%s\n" "${LOG_LEVEL}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "INFO" ]
}

@test "LOG_LEVEL can be overridden before include" {
  run shellac_run 'LOG_LEVEL=DEBUG; include "utils/logging"; printf "%s\n" "${LOG_LEVEL}"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "DEBUG" ]
}

# ---------------------------------------------------------------------------
# log_debug filtering
# ---------------------------------------------------------------------------

@test "log_debug: suppressed at LOG_LEVEL=INFO" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=INFO
    log_debug "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

@test "log_debug: suppressed at LOG_LEVEL=WARN" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=WARN
    log_debug "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

@test "log_debug: suppressed at LOG_LEVEL=ERROR" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=ERROR
    log_debug "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

@test "log_debug: exits 0 when suppressed" {
  run shellac_run 'include "utils/logging"; LOG_LEVEL=INFO; log_debug "x"'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# log_info filtering
# ---------------------------------------------------------------------------

@test "log_info: suppressed at LOG_LEVEL=WARN" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=WARN
    log_info "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

@test "log_info: suppressed at LOG_LEVEL=ERROR" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=ERROR
    log_info "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

@test "log_info: exits 0 when suppressed" {
  run shellac_run 'include "utils/logging"; LOG_LEVEL=WARN; log_info "x"'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# log_warn filtering
# ---------------------------------------------------------------------------

@test "log_warn: suppressed at LOG_LEVEL=ERROR" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=ERROR
    log_warn "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

@test "log_warn: exits 0 when suppressed" {
  run shellac_run 'include "utils/logging"; LOG_LEVEL=ERROR; log_warn "x"'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# log_error is never suppressed
# ---------------------------------------------------------------------------

@test "log_error: exits 0 at LOG_LEVEL=ERROR" {
  run shellac_run 'include "utils/logging"; LOG_LEVEL=ERROR; log_error "x"'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# logmsg: argument validation
# ---------------------------------------------------------------------------

@test "logmsg: exits 1 for unknown option" {
  run shellac_run 'include "utils/logging"; logmsg -z "msg"'
  [ "${status}" -eq 1 ]
}
