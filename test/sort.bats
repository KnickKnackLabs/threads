#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  load helpers
  setup_test_dir
}

@test "sort: reorders warning before note before success" {
  write_threads "$THREAD_SUCCESS" "$THREAD_NOTE" "$THREAD_WARNING"

  run threads sort --file "$THREADS_PATH"
  [ "$status" -eq 0 ]

  # Read back and check order
  content=$(cat "$THREADS_PATH")
  warning_pos=$(echo "$content" | grep -n "warning" | head -1 | cut -d: -f1)
  note_pos=$(echo "$content" | grep -n "\[!note\]" | head -1 | cut -d: -f1)
  success_pos=$(echo "$content" | grep -n "success" | head -1 | cut -d: -f1)
  [ "$warning_pos" -lt "$note_pos" ]
  [ "$note_pos" -lt "$success_pos" ]
}

@test "sort: reports thread counts" {
  write_threads "$THREAD_WARNING" "$THREAD_NOTE" "$THREAD_SUCCESS"

  run threads sort --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Sorted 3 threads"* ]]
}

@test "sort: handles no threads" {
  write_threads_file ""

  run threads sort --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No threads found"* ]]
}

@test "sort: handles no header marker" {
  echo "Just some text" > "$THREADS_PATH"

  run threads sort --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No header marker"* ]]
}

@test "sort: preserves thread content" {
  write_threads "$THREAD_MULTI_PARAGRAPH"

  threads sort --file "$THREADS_PATH"

  grep -q "First paragraph" "$THREADS_PATH"
  grep -q "Second paragraph" "$THREADS_PATH"
  grep -q "multi-paragraph reply" "$THREADS_PATH"
}
