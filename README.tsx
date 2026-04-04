/** @jsxImportSource jsx-md */

import { readFileSync, readdirSync } from "fs";
import { join, resolve } from "path";

import {
  Heading, Paragraph, CodeBlock, LineBreak, HR,
  Bold, Italic, Code, Link,
  Badge, Badges, Center, Section, Details,
  List, Item,
  Raw, HtmlLink, Sub,
} from "readme/src/components";

// ── Dynamic data ─────────────────────────────────────────────

const ROOT = resolve(import.meta.dirname);
const TASK_DIR = join(ROOT, ".mise/tasks");
const TEST_DIR = join(ROOT, "test");
const LIB_DIR = join(ROOT, "lib");

// Count tasks (excluding hidden/meta)
const taskFiles = readdirSync(TASK_DIR).filter(
  (f) => !f.startsWith(".") && !f.startsWith("_") && f !== "test"
);
const taskCount = taskFiles.length;

// Count tests from .bats files
const testFiles = readdirSync(TEST_DIR).filter((f) => f.endsWith(".bats"));
const testSrc = testFiles
  .map((f) => readFileSync(join(TEST_DIR, f), "utf-8"))
  .join("\n");
const testCount = [...testSrc.matchAll(/@test "/g)].length;

// Parser lines
const parserLines = readFileSync(join(LIB_DIR, "human_threads.py"), "utf-8")
  .split("\n").length;

// Extract tool versions from mise.toml
const miseToml = readFileSync(join(ROOT, "mise.toml"), "utf-8");
const batsVersion =
  miseToml.match(/bats\s*=\s*"([^"]+)"/)?.[1] ?? "latest";

// ── Visual hook ──────────────────────────────────────────────

const beforeAfter = [
  "# Before — raw thoughts dumped into the file",
  "",
  "  [Or] We should add retry logic to the webhook handler.",
  "  [ikma] Agree, but the backoff strategy matters — exponential?",
  "  [Or] Yeah, with jitter. Can you draft it?",
  "",
  "$ threads tidy",
  "Tidied: converted 1 codeblock.",
  "",
  "$ threads sort",
  "Sorted: 1 thread reordered.",
  "",
  "# After — structured callout, sorted by who's waiting",
  "",
  "> [!note]- Retry logic for webhook handler",
  "> **[Or → ikma]** We should add retry logic to the webhook handler.",
  ">",
  "> ---",
  ">",
  "> **[ikma]** Agree, but the backoff strategy matters — exponential?",
  ">",
  "> ---",
  ">",
  "> **[Or]** Yeah, with jitter. Can you draft it?",
].join("\n");

// ── Lifecycle diagram ────────────────────────────────────────

const lifecycle = [
  "  human writes raw thoughts    ─→  agents run tidy     ─→  structured callouts",
  "  discussion happens inline    ─→  agents run sort     ─→  warnings float up",
  "  thread reaches resolution    ─→  agents run archive  ─→  resolved threads move out",
].join("\n");

// ── README ───────────────────────────────────────────────────

const readme = (
  <>
    <Center>
      <Heading level={1}>threads</Heading>

      <Paragraph>
        <Bold>
          {"Manage threaded conversations in a single markdown file."}
        </Bold>
      </Paragraph>

      <Paragraph>
        {"Parse, tidy, sort, and archive Obsidian-style callout threads."}
        {"\n"}
        {"The async communication layer between humans and agents."}
      </Paragraph>

      <Badges>
        <Badge label="lang" value="bash + python" color="4EAA25" logo="gnubash" logoColor="white" />
        <Badge label="tests" value={`${testCount} passing`} color="brightgreen" href="test/" />
        <Badge label="commands" value={`${taskCount}`} color="blue" />
        <Badge label="license" value="MIT" color="blue" />
      </Badges>
    </Center>

    <CodeBlock>{beforeAfter}</CodeBlock>

    <LineBreak />

    <Section title="Quick start">
      <CodeBlock lang="bash">{`# Install
shiv install threads

# Initialize a threads file
threads init --file HUMAN.md

# After humans and agents have been writing...
threads tidy    # convert raw codeblocks → callouts, promote/demote
threads sort    # reorder: warnings first, then notes, then resolved
threads list    # see who's waiting on whom
threads archive # move resolved threads to HUMAN.archive.md`}</CodeBlock>
    </Section>

    <Section title="How it works">
      <Paragraph>
        {"A threads file is plain markdown with a header and a body. The header (everything above "}
        <Code>--- HEADER END ---</Code>
        {") explains the format. The body contains conversation threads as "}
        <Link href="https://help.obsidian.md/callouts">Obsidian callouts</Link>
        {":"}
      </Paragraph>

      <List>
        <Item>
          <Code>{"[!note]-"}</Code>
          {" — active thread, waiting on an agent"}
        </Item>
        <Item>
          <Code>{"[!warning]- 👈"}</Code>
          {" — needs human attention (yellow accent in Obsidian)"}
        </Item>
        <Item>
          <Code>{"[!success]-"}</Code>
          {" — resolved thread (green, ready to archive)"}
        </Item>
      </List>

      <Paragraph>
        {"Each message within a thread starts with "}
        <Code>{"**[Name]**"}</Code>
        {", separated by "}
        <Code>{"> ---"}</Code>
        {" dividers. Arrow notation tracks rewrites: "}
        <Code>{"**[Or → ikma]**"}</Code>
        {" means \"Or's words, as tidied by ikma.\""}
      </Paragraph>

      <CodeBlock>{lifecycle}</CodeBlock>

      <Paragraph>
        {"The key insight: "}
        <Bold>who sent the last message determines who's waiting.</Bold>
        {" If the last sender is a known human, agents are waiting. If it's an agent, the human is waiting. "}
        <Code>tidy</Code>
        {" auto-promotes threads to "}
        <Code>[!warning]</Code>
        {" when they need human attention, and demotes back to "}
        <Code>[!note]</Code>
        {" when the human has replied. "}
        <Code>sort</Code>
        {" then floats warnings to the top so the most urgent threads are always visible first."}
      </Paragraph>
    </Section>

    <Section title="Daily workflow">
      <Paragraph>
        {"In practice, agents run two commands when they wake up:"}
      </Paragraph>

      <CodeBlock lang="bash">{`# Orient: what needs attention?
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
Sorted: 3 threads reordered.`}</CodeBlock>

      <Paragraph>
        {"When threads reach resolution, archive them:"}
      </Paragraph>

      <CodeBlock lang="bash">{`$ threads archive --file HUMAN.md
Archived 1 resolved thread(s) to HUMAN.archive.md.`}</CodeBlock>
    </Section>

    <Section title="File resolution">
      <Paragraph>
        {"Every command accepts "}
        <Code>--file</Code>
        {" to specify the threads file explicitly. Without it, threads checks "}
        <Code>$THREADS_FILE</Code>
        {", then falls back to "}
        <Code>HUMAN.md</Code>
        {" in the current directory."}
      </Paragraph>

      <CodeBlock lang="bash">{`# Explicit
threads list --file ~/path/to/HUMAN.md

# Via environment
export THREADS_FILE="$HUMAN_MD"
threads list

# Default: ./HUMAN.md
cd ~/project && threads list`}</CodeBlock>
    </Section>

    <Section title="Development">
      <CodeBlock lang="bash">{`git clone https://github.com/KnickKnackLabs/threads.git
cd threads && mise trust && mise install
mise run test`}</CodeBlock>

      <Paragraph>
        <Bold>{`${testCount} tests`}</Bold>
        {` across ${testFiles.length} suites, using `}
        <Link href="https://github.com/bats-core/bats-core">{`BATS ${batsVersion}`}</Link>
        {`. The parser is ${parserLines} lines of Python in `}
        <Code>lib/human_threads.py</Code>
        {". Tasks are bash scripts that call into the parser for the heavy lifting."}
      </Paragraph>

      <Details summary="Project structure">
        <CodeBlock>{`threads/
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
    └── *.bats             # ${testCount} tests`}</CodeBlock>
      </Details>
    </Section>

    <LineBreak />

    <Center>
      <HR />

      <Sub>
        {"Async conversations, structured by convention, maintained by tools."}
        <Raw>{"<br />"}</Raw>{"\n"}
        <Raw>{"<br />"}</Raw>{"\n"}
        {"This README was generated from "}
        <HtmlLink href="https://github.com/KnickKnackLabs/readme">README.tsx</HtmlLink>
        {"."}
      </Sub>
    </Center>
  </>
);

console.log(readme);
