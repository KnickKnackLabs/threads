<div align="center">

# threads

**Manage threaded conversations in a single markdown file.**

Parse, tidy, sort, and archive Obsidian-style callout threads.
The async communication layer between humans and agents.

![lang: bash + python](https://img.shields.io/badge/lang-bash%20%2B%20python-4EAA25?style=flat&logo=gnubash&logoColor=white)
[![tests: 47 passing](https://img.shields.io/badge/tests-47%20passing-brightgreen?style=flat)](test/)
![commands: 6](https://img.shields.io/badge/commands-6-blue?style=flat)
![license: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat)

</div>

```
# Before — raw thoughts dumped into the file

  [Or] We should add retry logic to the webhook handler.
  [ikma] Agree, but the backoff strategy matters — exponential?
  [Or] Yeah, with jitter. Can you draft it?

$ threads tidy
Tidied: converted 1 codeblock.

$ threads sort
Sorted: 1 thread reordered.

# After — structured callout, sorted by who's waiting

> [!note]- Retry logic for webhook handler
> **[Or → ikma]** We should add retry logic to the webhook handler.
>
> ---
>
> **[ikma]** Agree, but the backoff strategy matters — exponential?
>
> ---
>
> **[Or]** Yeah, with jitter. Can you draft it?
```

<br />

## Quick start

```bash
# Install
shiv install threads

# Initialize a threads file
threads init --file HUMAN.md

# After humans and agents have been writing...
threads tidy    # convert raw codeblocks → callouts, promote/demote
threads sort    # reorder: warnings first, then notes, then resolved
threads list    # see who's waiting on whom
threads archive # move resolved threads to HUMAN.archive.md
```

## How it works

A threads file is plain markdown with a header and a body. The header (everything above `--- HEADER END ---`) explains the format. The body contains conversation threads as [Obsidian callouts](https://help.obsidian.md/callouts):

- `[!note]-` — active thread, waiting on an agent
- `[!warning]- 👈` — needs human attention (yellow accent in Obsidian)
- `[!success]-` — resolved thread (green, ready to archive)

Each message within a thread starts with `**[Name]**`, separated by `> ---` dividers. Arrow notation tracks rewrites: `**[Or → ikma]**` means "Or's words, as tidied by ikma."

```
  human writes raw thoughts    ─→  agents run tidy     ─→  structured callouts
  discussion happens inline    ─→  agents run sort     ─→  warnings float up
  thread reaches resolution    ─→  agents run archive  ─→  resolved threads move out
```

The key insight: **who sent the last message determines who's waiting.** If the last sender is a known human, agents are waiting. If it's an agent, the human is waiting. `tidy` auto-promotes threads to `[!warning]` when they need human attention, and demotes back to `[!note]` when the human has replied. `sort` then floats warnings to the top so the most urgent threads are always visible first.

## Daily workflow

In practice, agents run two commands when they wake up:

```bash
# Orient: what needs attention?
$ threads list --file HUMAN.md
╭────┬──────────────────────────────────────────┬───────────────────┬────────────╮
│    │ Thread                                   │ Participants      │ Waiting on │
├────┼──────────────────────────────────────────┼───────────────────┼────────────┤
│ 👈 │ Retry logic for webhook handler          │ Or+, ikma*        │ Or         │
│    │ Refactor auth module                     │ ikma+*, Or        │ agent      │
│ ✓  │ Fix CI timeout                           │ Or+, baby-joel*   │ resolved   │
╰────┴──────────────────────────────────────────┴───────────────────┴────────────╯
  + started thread  * last sender

# Maintain: tidy raw input, sort by priority
$ threads tidy --file HUMAN.md
Tidied: converted 2 codeblocks, promoted 1 to warning.

$ threads sort --file HUMAN.md
Sorted: 3 threads reordered.
```

When threads reach resolution, archive them:

```bash
$ threads archive --file HUMAN.md
Archived 1 resolved thread(s) to HUMAN.archive.md.
```

## File resolution

Every command accepts `--file` to specify the threads file explicitly. Without it, threads checks `$THREADS_FILE`, then falls back to `HUMAN.md` in the current directory.

```bash
# Explicit
threads list --file ~/path/to/HUMAN.md

# Via environment
export THREADS_FILE="$HUMAN_MD"
threads list

# Default: ./HUMAN.md
cd ~/project && threads list
```

## Development

```bash
git clone https://github.com/KnickKnackLabs/threads.git
cd threads && mise trust && mise install
mise run test
```

**47 tests** across 7 suites, using [BATS 1.13.0](https://github.com/bats-core/bats-core). The parser is 234 lines of Python in `lib/human_threads.py`. Tasks are bash scripts that call into the parser for the heavy lifting.

<details>
<summary><b>Project structure</b></summary>

```
threads/
├── .mise/tasks/
│   ├── init       # Initialize a threads file from template
│   ├── list       # List threads with status and waiting-on
│   ├── status     # Quick thread count summary
│   ├── tidy       # Codeblock→callout conversion + promote/demote
│   ├── sort       # Reorder by callout type (warning → note → success)
│   └── archive    # Move resolved threads to archive file
├── lib/
│   └── human_threads.py   # Parser: callouts, authors, waiting-on logic
├── templates/
│   └── HUMAN.md           # Default template with format guide
└── test/
    └── *.bats             # 47 tests
```

</details>

<br />

<div align="center">

---

<sub>
Async conversations, structured by convention, maintained by tools.<br />
<br />
This README was generated from <a href="https://github.com/KnickKnackLabs/readme">README.tsx</a>.
</sub></div>
