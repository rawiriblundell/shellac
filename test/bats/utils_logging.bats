#!/usr/bin/env bats
# Tests for utils/logging.sh — all eight RFC 5424 levels, aliases,
# _log_level_num, LOG_LEVEL filtering, and logmsg options.

# bats-shell: bash
# bats file_tags=BW01,BW02

load 'helpers/setup'

# ---------------------------------------------------------------------------
# _log_level_num
# ---------------------------------------------------------------------------

@test "_log_level_num: EMERG maps to 0" {
  run shellac_run 'include "utils/logging"; _log_level_num EMERG'
  [ "${status}" -eq 0 ]
  [ "${output}" = "0" ]
}

@test "_log_level_num: ALERT maps to 1" {
  run shellac_run 'include "utils/logging"; _log_level_num ALERT'
  [ "${status}" -eq 0 ]
  [ "${output}" = "1" ]
}

@test "_log_level_num: CRIT maps to 2" {
  run shellac_run 'include "utils/logging"; _log_level_num CRIT'
  [ "${status}" -eq 0 ]
  [ "${output}" = "2" ]
}

@test "_log_level_num: ERR maps to 3" {
  run shellac_run 'include "utils/logging"; _log_level_num ERR'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "_log_level_num: ERROR maps to 3 (alias)" {
  run shellac_run 'include "utils/logging"; _log_level_num ERROR'
  [ "${status}" -eq 0 ]
  [ "${output}" = "3" ]
}

@test "_log_level_num: WARNING maps to 4" {
  run shellac_run 'include "utils/logging"; _log_level_num WARNING'
  [ "${status}" -eq 0 ]
  [ "${output}" = "4" ]
}

@test "_log_level_num: WARN maps to 4 (alias)" {
  run shellac_run 'include "utils/logging"; _log_level_num WARN'
  [ "${status}" -eq 0 ]
  [ "${output}" = "4" ]
}

@test "_log_level_num: NOTICE maps to 5" {
  run shellac_run 'include "utils/logging"; _log_level_num NOTICE'
  [ "${status}" -eq 0 ]
  [ "${output}" = "5" ]
}

@test "_log_level_num: INFO maps to 6" {
  run shellac_run 'include "utils/logging"; _log_level_num INFO'
  [ "${status}" -eq 0 ]
  [ "${output}" = "6" ]
}

@test "_log_level_num: DEBUG maps to 7" {
  run shellac_run 'include "utils/logging"; _log_level_num DEBUG'
  [ "${status}" -eq 0 ]
  [ "${output}" = "7" ]
}

@test "_log_level_num: unknown level maps to 6 (INFO)" {
  run shellac_run 'include "utils/logging"; _log_level_num BOGUS'
  [ "${status}" -eq 0 ]
  [ "${output}" = "6" ]
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

@test "log_info: suppressed at LOG_LEVEL=NOTICE" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=NOTICE
    log_info "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

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
# log_notice filtering
# ---------------------------------------------------------------------------

@test "log_notice: suppressed at LOG_LEVEL=WARN" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=WARN
    log_notice "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

@test "log_notice: exits 0 when suppressed" {
  run shellac_run 'include "utils/logging"; LOG_LEVEL=WARN; log_notice "x"'
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

@test "log_warning: alias for log_warn — suppressed at LOG_LEVEL=ERROR" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=ERROR
    log_warning "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

# ---------------------------------------------------------------------------
# log_error / log_err
# ---------------------------------------------------------------------------

@test "log_error: exits 0 at LOG_LEVEL=ERROR" {
  run shellac_run 'include "utils/logging"; LOG_LEVEL=ERROR; log_error "x"'
  [ "${status}" -eq 0 ]
}

@test "log_error: suppressed at LOG_LEVEL=CRIT" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=CRIT
    log_error "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

@test "log_err: alias for log_error — exits 0 at LOG_LEVEL=ERROR" {
  run shellac_run 'include "utils/logging"; LOG_LEVEL=ERROR; log_err "x"'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# log_crit filtering
# ---------------------------------------------------------------------------

@test "log_crit: suppressed at LOG_LEVEL=ALERT" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=ALERT
    log_crit "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

@test "log_crit: exits 0 when suppressed" {
  run shellac_run 'include "utils/logging"; LOG_LEVEL=ALERT; log_crit "x"'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# log_alert filtering
# ---------------------------------------------------------------------------

@test "log_alert: suppressed at LOG_LEVEL=EMERG" {
  run shellac_run 'include "utils/logging"
    LOG_LEVEL=EMERG
    log_alert "should not appear"
    printf "%s\n" "after"'
  [ "${status}" -eq 0 ]
  [ "${output}" = "after" ]
}

@test "log_alert: exits 0 when suppressed" {
  run shellac_run 'include "utils/logging"; LOG_LEVEL=EMERG; log_alert "x"'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# log_emerg is never suppressed
# ---------------------------------------------------------------------------

@test "log_emerg: exits 0 at LOG_LEVEL=EMERG" {
  run shellac_run 'include "utils/logging"; LOG_LEVEL=EMERG; log_emerg "x"'
  [ "${status}" -eq 0 ]
}

# ---------------------------------------------------------------------------
# logmsg: argument validation
# ---------------------------------------------------------------------------

@test "logmsg: exits 1 for unknown option" {
  run shellac_run 'include "utils/logging"; logmsg -z "msg"'
  [ "${status}" -eq 1 ]
}

@test "logmsg: accepts -p priority without error" {
  run shellac_run 'include "utils/logging"; logmsg -p info "msg"'
  [ "${status}" -eq 0 ]
}
