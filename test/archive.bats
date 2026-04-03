#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  load helpers
  setup_test_dir
}

@test "archive: moves resolved threads to archive file" {
  write_threads "$THREAD_NOTE" "$THREAD_SUCCESS"

  run threads archive --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Archived 1 resolved thread"* ]]

  # Success thread should be in archive
  [ -f "$ARCHIVE_PATH" ]
  grep -q "Done thing" "$ARCHIVE_PATH"

  # Success thread should be gone from original
  ! grep -q '\[!success\]' "$THREADS_PATH"

  # Note thread should remain
  grep -q "Test thread" "$THREADS_PATH"
}

@test "archive: creates archive file with header" {
  write_threads "$THREAD_SUCCESS"

  threads archive --file "$THREADS_PATH"

  grep -q "# Archive" "$ARCHIVE_PATH"
  grep -q "Archived" "$ARCHIVE_PATH"
}

@test "archive: appends to existing archive" {
  write_threads "$THREAD_SUCCESS"
  threads archive --file "$THREADS_PATH"

  # Add another resolved thread and archive again
  write_threads "$THREAD_NOTE" '> [!success]- Second resolved
> Done again.'

  threads archive --file "$THREADS_PATH"

  # Both should be in archive
  grep -q "Done thing" "$ARCHIVE_PATH"
  grep -q "Second resolved" "$ARCHIVE_PATH"
}

@test "archive: no resolved threads to archive" {
  write_threads "$THREAD_NOTE" "$THREAD_WARNING"

  run threads archive --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No resolved threads"* ]]
  [ ! -f "$ARCHIVE_PATH" ]
}

@test "archive: handles no header marker" {
  echo "Just some text" > "$THREADS_PATH"

  run threads archive --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No header marker"* ]]
}

@test "archive: preserves multiple unresolved threads" {
  write_threads "$THREAD_NOTE" "$THREAD_WARNING" "$THREAD_SUCCESS"

  threads archive --file "$THREADS_PATH"

  grep -q "Test thread" "$THREADS_PATH"
  grep -q "Urgent thing" "$THREADS_PATH"
  ! grep -q "Done thing" "$THREADS_PATH"
}
