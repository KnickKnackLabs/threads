#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

setup() {
  load helpers
}

# --- _resolve-file ---

@test "_resolve-file: absolute path passes through" {
  run bash "$REPO_DIR/.mise/tasks/_resolve-file" "/tmp/absolute/HUMAN.md"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/absolute/HUMAN.md" ]
}

@test "_resolve-file: relative path resolves against THREADS_CALLER_PWD" {
  run env THREADS_CALLER_PWD="/tmp/caller" bash "$REPO_DIR/.mise/tasks/_resolve-file" "notes/BULLETIN.md"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/caller/notes/BULLETIN.md" ]
}

@test "_resolve-file: no arg defaults to THREADS_CALLER_PWD/HUMAN.md" {
  run env THREADS_CALLER_PWD="/tmp/caller" THREADS_FILE= bash "$REPO_DIR/.mise/tasks/_resolve-file"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/caller/HUMAN.md" ]
}

@test "_resolve-file: THREADS_FILE env is also CWD-relative" {
  run env THREADS_CALLER_PWD="/tmp/caller" THREADS_FILE="notes/B.md" bash "$REPO_DIR/.mise/tasks/_resolve-file"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/caller/notes/B.md" ]
}

@test "_resolve-file: legacy CALLER_PWD fallback still works during migration" {
  run env CALLER_PWD="/tmp/legacy" bash "$REPO_DIR/.mise/tasks/_resolve-file" "notes/BULLETIN.md"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/legacy/notes/BULLETIN.md" ]
}

# --- parse_threads ---

@test "parser: extracts note thread" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import parse_threads
_, threads = parse_threads('\n> [!note]- Title\n> Content\n')
assert len(threads) == 1
assert threads[0][0] == 'note'
"
  [ "$status" -eq 0 ]
}

@test "parser: extracts warning thread" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import parse_threads
_, threads = parse_threads('\n> [!warning]- Title 👈\n> Content\n')
assert len(threads) == 1
assert threads[0][0] == 'warning'
"
  [ "$status" -eq 0 ]
}

@test "parser: extracts success thread" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import parse_threads
_, threads = parse_threads('\n> [!success]- Title\n> Content\n')
assert len(threads) == 1
assert threads[0][0] == 'success'
"
  [ "$status" -eq 0 ]
}

@test "parser: handles multiple threads" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import parse_threads
body = '''
> [!note]- First
> Content A

> [!warning]- Second
> Content B

> [!success]- Third
> Content C
'''
_, threads = parse_threads(body)
assert len(threads) == 3
assert [t[0] for t in threads] == ['note', 'warning', 'success']
"
  [ "$status" -eq 0 ]
}

@test "parser: preserves multi-paragraph content" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import parse_threads
body = '''
> [!note]- Multi
> **[Or]** Para one.
>
> Para two.
>
> ---
>
> **[junior]** Reply.
'''
_, threads = parse_threads(body)
assert len(threads) == 1
# Should have all lines including blank continuation lines
lines = threads[0][1]
assert any('Para two' in l for l in lines)
"
  [ "$status" -eq 0 ]
}

# --- extract_authors / extract_message_senders ---

@test "parser: extracts authors from body" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import extract_authors
lines = ['**[Or]** Hello.', '', '---', '', '**[junior]** Reply.']
authors = extract_authors(lines)
assert authors == ['Or', 'junior'], f'got: {authors}'
"
  [ "$status" -eq 0 ]
}

@test "parser: arrow chain yields last name as author" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import extract_authors
lines = ['**[Or → Zeke]** Rewritten message.']
authors = extract_authors(lines)
assert authors == ['Zeke'], f'got: {authors}'
"
  [ "$status" -eq 0 ]
}

@test "parser: message senders yields first name in chain" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import extract_message_senders
lines = ['**[Or → Zeke]** Rewritten message.']
senders = extract_message_senders(lines)
assert senders == ['Or'], f'got: {senders}'
"
  [ "$status" -eq 0 ]
}

@test "parser: thread starter is oldest sender in newest-first order" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import extract_thread_starter
lines = ['**[junior]** Latest reply.', '', '---', '', '**[Or → Zeke]** Original request.']
starter = extract_thread_starter(lines)
assert starter == 'Or', f'got: {starter}'
"
  [ "$status" -eq 0 ]
}

# --- thread_waiting_on ---

@test "parser: human latest sender means waiting on agent" {
  run python3 -c "
import sys, os; sys.path.insert(0, '$REPO_DIR/lib')
os.environ['THREADS_HUMAN'] = 'Or'
from human_threads import thread_waiting_on
assert thread_waiting_on('note', ['Or']) == 'agent'
"
  [ "$status" -eq 0 ]
}

@test "parser: agent latest sender means waiting on human" {
  run python3 -c "
import sys, os; sys.path.insert(0, '$REPO_DIR/lib')
os.environ['THREADS_HUMAN'] = 'Or'
from human_threads import thread_waiting_on
assert thread_waiting_on('note', ['junior', 'Or']) == 'Or'
"
  [ "$status" -eq 0 ]
}

@test "parser: success thread is resolved" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import thread_waiting_on
assert thread_waiting_on('success', ['Or']) == 'resolved'
"
  [ "$status" -eq 0 ]
}

@test "parser: no authors returns dash" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import thread_waiting_on
assert thread_waiting_on('note', []) == '—'
"
  [ "$status" -eq 0 ]
}

@test "parser: no human configured returns dash for all active threads" {
  run python3 -c "
import sys, os; sys.path.insert(0, '$REPO_DIR/lib')
os.environ.pop('THREADS_HUMAN', None)
from human_threads import thread_waiting_on
assert thread_waiting_on('note', ['junior', 'Or']) == '—'
assert thread_waiting_on('warning', ['junior']) == '—'
assert thread_waiting_on('success', ['Or']) == 'resolved'
"
  [ "$status" -eq 0 ]
}

@test "parser: explicit human_name argument overrides env" {
  run python3 -c "
import sys, os; sys.path.insert(0, '$REPO_DIR/lib')
os.environ['THREADS_HUMAN'] = 'Or'
from human_threads import thread_waiting_on
assert thread_waiting_on('note', ['Alice'], human_name='Alice') == 'agent'
assert thread_waiting_on('note', ['junior'], human_name='Alice') == 'Alice'
"
  [ "$status" -eq 0 ]
}

# --- thread_title ---

@test "parser: extracts title from opener" {
  run python3 -c "
import sys; sys.path.insert(0, '$REPO_DIR/lib')
from human_threads import thread_title
assert thread_title('> [!warning]- Urgent thing 👈') == 'Urgent thing'
assert thread_title('> [!note]- Simple title') == 'Simple title'
assert thread_title('> [!success]- Done (resolved)') == 'Done (resolved)'
"
  [ "$status" -eq 0 ]
}
