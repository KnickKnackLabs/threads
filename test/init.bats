#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  load helpers
  setup_test_dir
}

@test "init: creates file from template" {
  run threads init --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [ -f "$THREADS_PATH" ]
  [[ "$output" == *"Initialized"* ]]
}

@test "init: created file contains info callout" {
  threads init --file "$THREADS_PATH"
  grep -q "\[!info\]" "$THREADS_PATH"
}

@test "init: created file contains threads task references" {
  threads init --file "$THREADS_PATH"
  grep -q "threads fmt" "$THREADS_PATH"
  grep -q "threads archive" "$THREADS_PATH"
}

@test "init: refuses to overwrite without --force" {
  threads init --file "$THREADS_PATH"
  run threads init --file "$THREADS_PATH"
  [ "$status" -ne 0 ]
  [[ "$output" == *"already exists"* ]]
}

@test "init --force: updates header, preserves threads" {
  threads init --file "$THREADS_PATH"

  # Add a thread after the header
  echo '' >> "$THREADS_PATH"
  echo '> [!note]- My thread' >> "$THREADS_PATH"
  echo '> **[Or]** Important stuff.' >> "$THREADS_PATH"

  run threads init --force --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Updated"* ]]

  # Thread should be preserved
  grep -q "My thread" "$THREADS_PATH"
  grep -q "Important stuff" "$THREADS_PATH"
}

@test "init: creates parent directories" {
  NESTED="$TEST_DIR/deep/nested/HUMAN.md"
  run threads init --file "$NESTED"
  [ "$status" -eq 0 ]
  [ -f "$NESTED" ]
}
