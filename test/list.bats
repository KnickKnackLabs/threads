#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  load helpers
  setup_test_dir
}

@test "list: shows threads with status" {
  write_threads "$THREAD_WARNING" "$THREAD_NOTE" "$THREAD_SUCCESS"

  run threads list --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Urgent thing"* ]]
  [[ "$output" == *"Test thread"* ]]
  [[ "$output" == *"Done thing"* ]]
}

@test "list: shows no threads message" {
  write_threads_file ""

  run threads list --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No threads found"* ]]
}

@test "list: shows participants" {
  write_threads "$THREAD_NOTE"

  run threads list --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Or"* ]]
  [[ "$output" == *"junior"* ]]
}

@test "list: missing file gives helpful error" {
  run threads list --file "$TEST_DIR/nonexistent.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"No threads file found"* ]]
}
