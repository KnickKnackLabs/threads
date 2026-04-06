#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  load helpers
  setup_test_dir
}

# --- Codeblock conversion (from tidy) ---

@test "fmt: converts raw codeblock to callout" {
  write_threads "$RAW_CODEBLOCK"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"converted 1 codeblock"* ]]
  content=$(cat "$THREADS_PATH")
  [[ "$content" == *"[!note]"* ]] || [[ "$content" == *"[!warning]"* ]]
  [[ "$content" == *"**[Or]**"* ]]
}

@test "fmt: ignores codeblocks without author markers" {
  write_threads_file '```
just some code
no authors here
```'
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing to format"* ]]
}

# --- Promote/demote (from tidy) ---

@test "fmt: promotes to warning when waiting on human" {
  export THREADS_HUMAN=Or
  write_threads "$THREAD_OR_WAITING"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"promoted"* ]]
  run cat "$THREADS_PATH"
  [[ "$output" == *"[!warning]"* ]]
  [[ "$output" == *"👈"* ]]
}

@test "fmt: demotes to note when waiting on agent" {
  export THREADS_HUMAN=Or
  local thread='> [!warning]- Was urgent 👈
> **[Or]** Question?
>
> ---
>
> **[Or]** Actually, agents should handle this.'
  write_threads "$thread"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"demoted"* ]]
  run cat "$THREADS_PATH"
  [[ "$output" == *"[!note]- Was urgent"* ]]
  [[ "$output" != *"👈"* ]]
}

@test "fmt: no promotion/demotion without THREADS_HUMAN" {
  unset THREADS_HUMAN 2>/dev/null || true
  write_threads "$THREAD_OR_WAITING"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing to format"* ]]
  run cat "$THREADS_PATH"
  [[ "$output" == *"[!note]"* ]]
}

@test "fmt: does not touch success threads" {
  write_threads "$THREAD_SUCCESS"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  run cat "$THREADS_PATH"
  [[ "$output" == *"[!success]"* ]]
}

@test "fmt: arrow chain uses original sender for waiting-on" {
  write_threads "$THREAD_OR_REWRITTEN_LAST"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  # Or spoke last (via rewrite) — should wait on agent, so stays/becomes note
  run cat "$THREADS_PATH"
  [[ "$output" == *"[!note]"* ]]
}

# --- Sorting (from sort) ---

@test "fmt: sorts warning before note before success" {
  write_threads "$THREAD_SUCCESS" "$THREAD_NOTE" "$THREAD_WARNING"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"sorted"* ]]
  # Verify order: warning first, then note, then success
  run cat "$THREADS_PATH"
  local warning_pos note_pos success_pos
  warning_pos=$(echo "$output" | grep -n "\[!warning\]" | head -1 | cut -d: -f1)
  note_pos=$(echo "$output" | grep -n "\[!note\]" | head -1 | cut -d: -f1)
  success_pos=$(echo "$output" | grep -n "\[!success\]" | head -1 | cut -d: -f1)
  [ "$warning_pos" -lt "$note_pos" ]
  [ "$note_pos" -lt "$success_pos" ]
}

@test "fmt: preserves thread content after sort" {
  write_threads "$THREAD_NOTE" "$THREAD_WARNING"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  run cat "$THREADS_PATH"
  [[ "$output" == *"This is a test note"* ]]
  [[ "$output" == *"This needs attention"* ]]
}

@test "fmt: nothing to format when already correct" {
  # Fixtures where types and order already match what fmt would produce
  local stable_warning='> [!warning]- Or needs to respond 👈
> **[Or]** Started a thought.
>
> ---
>
> **[junior]** Here is my reply.'
  local stable_note='> [!note]- Agent should handle
> **[Or]** Please do this.'
  write_threads "$stable_warning" "$stable_note" "$THREAD_SUCCESS"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing to format"* ]]
}

# --- Check mode ---

@test "fmt --check: exits 0 when clean" {
  local stable_warning='> [!warning]- Or needs to respond 👈
> **[Or]** Started a thought.
>
> ---
>
> **[junior]** Here is my reply.'
  local stable_note='> [!note]- Agent should handle
> **[Or]** Please do this.'
  write_threads "$stable_warning" "$stable_note" "$THREAD_SUCCESS"
  run threads fmt --file "$THREADS_PATH" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"Clean"* ]]
}

@test "fmt --check: exits 1 when changes needed" {
  write_threads "$THREAD_SUCCESS" "$THREAD_NOTE" "$THREAD_WARNING"
  run threads fmt --file "$THREADS_PATH" --check
  [ "$status" -eq 1 ]
  [[ "$output" == *"Would change"* ]]
  [[ "$output" == *"sorted"* ]]
}

@test "fmt --check: does not modify the file" {
  write_threads "$THREAD_SUCCESS" "$THREAD_NOTE" "$THREAD_WARNING"
  local before
  before=$(cat "$THREADS_PATH")
  run threads fmt --file "$THREADS_PATH" --check
  [ "$status" -eq 1 ]
  local after
  after=$(cat "$THREADS_PATH")
  [ "$before" = "$after" ]
}

# --- Info callouts ---

@test "fmt: info callouts sort before warnings" {
  local info_thread='> [!info]- Instructions
> How to use this file.'
  local stable_warning='> [!warning]- Or needs to respond \U0001f448
> **[Or]** Started a thought.
>
> ---
>
> **[junior]** Here is my reply.'
  write_threads "$stable_warning" "$info_thread"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  content=$(cat "$THREADS_PATH")
  local info_pos warning_pos
  info_pos=$(echo "$content" | grep -n '!info' | head -1 | cut -d: -f1)
  warning_pos=$(echo "$content" | grep -n '!warning' | head -1 | cut -d: -f1)
  [ "$info_pos" -lt "$warning_pos" ]
}

@test "fmt: does not promote/demote info callouts" {
  local info_thread='> [!info]- Instructions
> **[Or]** This is info, not a conversation.'
  write_threads "$info_thread"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  content=$(cat "$THREADS_PATH")
  [[ "$content" == *"[!info]"* ]]
}

# --- Combined operations ---

@test "fmt: converts codeblock and sorts in one pass" {
  write_threads "$THREAD_SUCCESS" "$RAW_CODEBLOCK" "$THREAD_WARNING"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"converted"* ]]
  [[ "$output" == *"sorted"* ]]
}

@test "fmt: promotes and sorts in one pass" {
  export THREADS_HUMAN=Or
  write_threads "$THREAD_SUCCESS" "$THREAD_OR_WAITING"
  run threads fmt --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"promoted"* ]]
  [[ "$output" == *"sorted"* ]]
  # Warning (promoted) should be before success
  run cat "$THREADS_PATH"
  local warning_pos success_pos
  warning_pos=$(echo "$output" | grep -n "\[!warning\]" | head -1 | cut -d: -f1)
  success_pos=$(echo "$output" | grep -n "\[!success\]" | head -1 | cut -d: -f1)
  [ "$warning_pos" -lt "$success_pos" ]
}
