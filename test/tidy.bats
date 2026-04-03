#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  load helpers
  setup_test_dir
}

# --- Codeblock conversion ---

@test "tidy: converts raw codeblock to callout" {
  # Use a heredoc to avoid backtick escaping issues
  cat > "$THREADS_PATH" << 'TESTEOF'
# HUMAN

Test scratchpad.

--- HEADER END ---

```
[Or] Hey, what do you think?

[junior] Looks good.
```
TESTEOF

  run threads tidy --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"converted 1 codeblock"* ]]

  # Should now be a callout
  grep -q '\[!note\]\|\[!warning\]' "$THREADS_PATH"
  grep -q '\*\*\[Or\]\*\*' "$THREADS_PATH"
  grep -q '\*\*\[junior\]\*\*' "$THREADS_PATH"
}

@test "tidy: ignores codeblocks without author markers" {
  cat > "$THREADS_PATH" << 'TESTEOF'
# HUMAN

Test scratchpad.

--- HEADER END ---

```
just some code
echo hello
```
TESTEOF

  run threads tidy --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing to tidy"* ]]
}

# --- Promote/demote ---

@test "tidy: promotes to warning when waiting on Or" {
  write_threads "$THREAD_OR_WAITING"

  run threads tidy --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"promoted"* ]]

  grep -q '\[!warning\]' "$THREADS_PATH"
  grep -q '👈' "$THREADS_PATH"
}

@test "tidy: demotes to note when waiting on agent" {
  # A warning thread where Or spoke last (waiting on agent → should demote)
  write_threads_file '
> [!warning]- Should demote 👈
> **[junior]** I said something.
>
> ---
>
> **[Or]** Or replied.'

  run threads tidy --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"demoted"* ]]

  grep -q '\[!note\]' "$THREADS_PATH"
  ! grep -q '👈' "$THREADS_PATH"
}

@test "tidy: does not touch success threads" {
  write_threads "$THREAD_SUCCESS"

  run threads tidy --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing to tidy"* ]]

  grep -q '\[!success\]' "$THREADS_PATH"
}

@test "tidy: arrow chain uses original sender for waiting-on" {
  # Or → Zeke means Or sent it, Zeke edited. Original sender is Or → waiting on agent.
  write_threads "$THREAD_OR_REWRITTEN_BY_AGENT"

  run threads tidy --file "$THREADS_PATH"
  [ "$status" -eq 0 ]

  # Zeke's response is last, original sender is Zeke → waiting on Or → should be warning
  grep -q '\[!warning\]' "$THREADS_PATH"
}

@test "tidy: nothing to tidy when already correct" {
  write_threads "$THREAD_AGENT_WAITING"

  run threads tidy --file "$THREADS_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing to tidy"* ]]
}
