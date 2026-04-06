#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  load helpers
  setup_test_dir
}

@test "ls: shows threads with status" {
  write_threads "$THREAD_WARNING" "$THREAD_NOTE" "$THREAD_SUCCESS"

  run threads ls --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Urgent thing"* ]]
  [[ "$output" == *"Test thread"* ]]
  [[ "$output" == *"Done thing"* ]]
}

@test "ls: shows no threads message" {
  write_threads_file ""

  run threads ls --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No threads found"* ]]
}

@test "ls: shows participants" {
  write_threads "$THREAD_NOTE"

  run threads ls --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Or"* ]]
  [[ "$output" == *"junior"* ]]
}

@test "ls: shows word-based status labels" {
  write_threads "$THREAD_INFO" "$THREAD_WARNING" "$THREAD_NOTE" "$THREAD_SUCCESS"

  run threads ls --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"info"* ]]
  [[ "$output" == *"attention"* ]]
  [[ "$output" == *"active"* ]]
  [[ "$output" == *"resolved"* ]]
}

@test "ls: missing file gives helpful error" {
  run threads ls --file "$TEST_DIR/nonexistent.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"No threads file found"* ]]
}
