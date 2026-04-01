#!/usr/bin/env bats
# Tests for seq (step-in) in lib/sh/numbers/seq.sh
# Note: the module only defines seq when the system seq is absent.
# We test by patching PATH to hide the real seq.

load 'helpers/setup'

# Run the include forcing the step-in to be defined even if system seq exists,
# by temporarily unsetting/hiding it.
_seq_run() {
  shellac_run "
    # Hide system seq so the step-in function is loaded
    seq() { :; }; unset -f seq
    # Force reload by temporarily pretending seq is absent
    PATH_SAVE=\"\${PATH}\"
    export PATH=\"/nonexistent\"
    include \"numbers/seq\"
    export PATH=\"\${PATH_SAVE}\"
    ${1}
  "
}

@test "seq step-in: single arg generates 1 to n" {
  run shellac_run 'include "numbers/seq"; seq 5'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%d\n' 1 2 3 4 5)" ]
}

@test "seq step-in: two args generates first to last" {
  run shellac_run 'include "numbers/seq"; seq 3 7'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%d\n' 3 4 5 6 7)" ]
}

@test "seq step-in: three args uses increment" {
  run shellac_run 'include "numbers/seq"; seq 0 2 10'
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '%d\n' 0 2 4 6 8 10)" ]
}

@test "seq step-in: no args prints usage" {
  run _seq_run 'seq'
  [ "${status}" -eq 0 ]
  [[ "${output}" = *"Usage"* ]]
}
