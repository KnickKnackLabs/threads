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

@test "ls: marks starter and latest sender in newest-first threads" {
  write_threads "$THREAD_NOTE"

  run threads ls --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Or+"* ]]
  [[ "$output" == *"junior*"* ]]
  [[ "$output" == *"latest sender"* ]]
}

@test "ls: shows word-based status labels" {
  write_threads \
    "$THREAD_INFO" \
    "$THREAD_WARNING" \
    "$THREAD_TODO" \
    "$THREAD_QUESTION" \
    "$THREAD_NOTE" \
    "$THREAD_ABSTRACT" \
    "$THREAD_SUCCESS"

  run threads ls --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"info"* ]]
  [[ "$output" == *"attention"* ]]
  [[ "$output" == *"todo"* ]]
  [[ "$output" == *"shaping"* ]]
  [[ "$output" == *"active"* ]]
  [[ "$output" == *"parked"* ]]
  [[ "$output" == *"resolved"* ]]
}

@test "ls: missing file gives helpful error" {
  run threads ls --file "$TEST_DIR/nonexistent.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"No threads file found"* ]]
}

@test "ls: renders a title containing straight double quotes" {
  write_threads "$THREAD_QUOTED_TITLE"

  run threads ls --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *'This has "quoted text" in the title'* ]]
}

@test "ls: keeps a leading double quote in a title" {
  write_threads "$THREAD_LEADING_QUOTE_TITLE"

  run threads ls --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"Currently Implemented" tables are traps'* ]]
}
