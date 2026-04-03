#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  load helpers
  setup_test_dir
}

@test "status: counts threads by waiting-on" {
  write_threads "$THREAD_AGENT_WAITING" "$THREAD_OR_WAITING" "$THREAD_SUCCESS"

  run threads status --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"3 threads"* ]]
  [[ "$output" == *"waiting on agent"* ]]
  [[ "$output" == *"waiting on Or"* ]]
  [[ "$output" == *"resolved"* ]]
}

@test "status: handles all resolved" {
  write_threads "$THREAD_SUCCESS"

  run threads status --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 threads"* ]]
  [[ "$output" == *"resolved"* ]]
}

@test "status: handles no threads" {
  write_threads_file ""

  run threads status --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"0 threads"* ]]
}

@test "status: handles thread with no authors" {
  write_threads "$THREAD_NO_AUTHORS"

  run threads status --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 threads"* ]]
}
