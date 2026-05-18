# Shared helpers for threads BATS tests
#
# Provides test isolation via temporary directories and a threads()
# wrapper that calls tasks through mise.

if [ -z "${REPO_DIR:-}" ]; then
  REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export REPO_DIR
  eval "$(cd "$REPO_DIR" && mise env)"
fi

# Call threads tasks through mise — the only layer between tests and mise.
threads() {
  local caller_pwd="${THREADS_CALLER_PWD:-$PWD}"
  (cd "$REPO_DIR" && THREADS_CALLER_PWD="$caller_pwd" mise run -q "$@")
}
export -f threads

# Create an isolated test environment
# Sets: TEST_DIR, THREADS_PATH, ARCHIVE_PATH
setup_test_dir() {
  TEST_DIR="$BATS_TEST_TMPDIR/threads-test-$$"
  mkdir -p "$TEST_DIR"
  THREADS_PATH="$TEST_DIR/HUMAN.md"
  ARCHIVE_PATH="$TEST_DIR/HUMAN.archive.md"
  export TEST_DIR THREADS_PATH ARCHIVE_PATH
}

# Write a minimal threads file with header and given body content
# Usage: write_threads_file "body content"
write_threads_file() {
  local body="${1:-}"
  cat > "$THREADS_PATH" <<EOF
# HUMAN
${body}
EOF
}

# Write a threads file with specific thread blocks
# Usage: write_threads [thread_blocks...]
# Each argument is a complete callout block (including "> " prefix)
write_threads() {
  local body=""
  for thread in "$@"; do
    body="${body}
${thread}
"
  done
  write_threads_file "$body"
}

# --- Standard thread fixtures ---

THREAD_NOTE='> [!note]- Test thread (Mar 15)
> **[Or]** This is a test note.
>
> ---
>
> **[junior]** Noted.'

THREAD_WARNING='> [!warning]- Urgent thing 👈
> **[Or]** This needs attention.'

THREAD_SUCCESS='> [!success]- Done thing (resolved Mar 15)
> Completed successfully.'

THREAD_INFO='> [!info]- How this works
> Instructions for using this file.'

THREAD_AGENT_WAITING='> [!note]- Agent should respond
> **[Or]** What do you think?'

THREAD_OR_WAITING='> [!note]- Or should respond
> **[Or]** Starting thought.
>
> ---
>
> **[junior]** Here is my response.'

THREAD_NO_AUTHORS='> [!note]- Empty thread
> No author markers here.'

# Thread with arrow chain authorship convention
THREAD_ARROW_CHAIN='> [!note]- Rewritten thread (Mar 15)
> **[Or → x1f9]** This message was clarified by x1f9.
>
> ---
>
> **[junior]** Looks good to me.'

# Thread with multi-hop arrow chain
THREAD_MULTI_ARROW='> [!note]- Multi-edit thread
> **[Or → x1f9 → brownie]** Edited twice.'

# Thread where Or's message was rewritten by an agent (arrow notation)
THREAD_OR_REWRITTEN_BY_AGENT='> [!note]- Or said something, agent rewrote
> **[Or → Zeke]** This is Or speaking, Zeke just cleaned up the prose.
>
> ---
>
> **[Zeke]** My actual response to Or.'

# Thread where agent's rewrite is the last message (should wait on agent)
THREAD_OR_REWRITTEN_LAST='> [!note]- Or spoke last via rewrite
> **[Zeke]** I said something first.
>
> ---
>
> **[Or → Zeke]** Or replied, Zeke cleaned it up.'

# Thread with multi-paragraph content (blank lines inside callout)
THREAD_MULTI_PARAGRAPH='> [!note]- Long discussion (Mar 15)
> **[Or]** First paragraph of thought.
>
> Second paragraph continues here.
>
> Third paragraph with more detail.
>
> ---
>
> **[junior]** My multi-paragraph reply.
>
> Continued thoughts here.'

# Two adjacent threads separated by a blank line
THREAD_ADJACENT_A='> [!note]- Thread A
> **[Or]** Content A.'

THREAD_ADJACENT_B='> [!note]- Thread B
> **[junior]** Content B.'

# A raw codeblock that tidy should convert
RAW_CODEBLOCK='```
[Or] Hey, what do you think about this?

[junior] I think it looks good.
```'
