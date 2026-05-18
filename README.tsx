/** @jsxImportSource jsx-md */

import { readFileSync, readdirSync } from "fs";
import { join, resolve } from "path";

import {
  Heading, Paragraph, CodeBlock, LineBreak, HR,
  Bold, Italic, Code, Link, Image,
  Badge, Badges, Center, Section, Details,
  List, Item,
  Raw, HtmlLink, Sub,
  HtmlTable, HtmlTr, HtmlTd, Align,
} from "readme/src/components";

// ── Dynamic data ─────────────────────────────────────────────

const ROOT = resolve(import.meta.dirname);
const TASK_DIR = join(ROOT, ".mise/tasks");
const TEST_DIR = join(ROOT, "test");
const LIB_DIR = join(ROOT, "lib");

const taskFiles = readdirSync(TASK_DIR).filter(
  (f) => !f.startsWith(".") && !f.startsWith("_") && f !== "test"
);
const taskCount = taskFiles.length;

const testFiles = readdirSync(TEST_DIR).filter((f) => f.endsWith(".bats"));
const testSrc = testFiles
  .map((f) => readFileSync(join(TEST_DIR, f), "utf-8"))
  .join("\n");
const testCount = [...testSrc.matchAll(/@test "/g)].length;

const parserLines = readFileSync(join(LIB_DIR, "human_threads.py"), "utf-8")
  .trimEnd().split("\n").length;

const templateDir = join(ROOT, "templates");
const templateCount = readdirSync(templateDir).filter((f) => f.endsWith(".md")).length;

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
        {"Parse, format, and archive "}
        <Link href="https://help.obsidian.md/callouts">Obsidian-style callout</Link>
        {" threads.\nThe async communication layer for humans and agents."}
      </Paragraph>

      <Badges>
        <Badge label="lang" value="python + bash" color="3776AB" logo="python" logoColor="white" />
        <Badge label="tests" value={`${testCount} passing`} color="brightgreen" href="test/" />
        <Badge label="commands" value={`${taskCount}`} color="blue" />
        <Badge label="license" value="MIT" color="blue" />
      </Badges>
    </Center>

    <CodeBlock>{[
      "$ threads template HUMAN > HUMAN.md",
      "",
      "$ cat HUMAN.md",
      "# HUMAN",
      "",
      "> [!info]- How this works",
      "> Async scratchpad for human-agent conversations.",
      "> ...",
      "",
      "# A human writes raw thoughts anywhere in the file:",
      "",
      "  [Or] We should add retry logic to the webhook handler.",
      "  [ikma] Agree — exponential backoff with jitter?",
      "  [Or] Yeah. Can you draft it?",
      "",
      "$ threads fmt",
      "Formatted: converted 1 codeblock, promoted 1 to warning, sorted.",
      "",
      "$ cat HUMAN.md",
      "# HUMAN",
      "",
      "> [!info]- How this works",
      "> ...",
      "",
      "> [!warning]- TODO: title this thread 👈",
      "> **[Or]** We should add retry logic to the webhook handler.",
      ">",
      "> ---",
      ">",
      "> **[ikma]** Agree — exponential backoff with jitter?",
      ">",
      "> ---",
      ">",
      "> **[Or]** Yeah. Can you draft it?",
    ].join("\n")}</CodeBlock>

    <LineBreak />

    <Section title="What it looks like">
      <Paragraph>
        {"Threads are plain markdown — but in "}
        <Link href="https://obsidian.md">Obsidian</Link>
        {", callouts render as collapsible, color-coded blocks:"}
      </Paragraph>

      <HtmlTable>
        <HtmlTr>
          <HtmlTd width="50%" valign="top">
            <Align align="center">
              <Raw>{`<a href="assets/human.png"><img src="assets/human.png" alt="HUMAN.md rendered in Obsidian" width="400" /></a>`}</Raw>
              <Raw>{`<br /><b>HUMAN.md</b> — human ↔ agent scratchpad`}</Raw>
            </Align>
          </HtmlTd>
          <HtmlTd width="50%" valign="top">
            <Align align="center">
              <Raw>{`<a href="assets/bulletin.png"><img src="assets/bulletin.png" alt="BULLETIN.md rendered in Obsidian" width="400" /></a>`}</Raw>
              <Raw>{`<br /><b>BULLETIN.md</b> — cross-team bulletin board`}</Raw>
            </Align>
          </HtmlTd>
        </HtmlTr>
      </HtmlTable>
    </Section>

    <Section title="Quick start">
      <CodeBlock lang="bash">{[
        "# Install",
        "shiv install threads",
        "",
        "# Create a threads file from a template",
        "threads template HUMAN > HUMAN.md",
        "",
        "# After humans and agents have been writing...",
        "threads fmt              # convert codeblocks, promote/demote, sort",
        "threads ls               # see who's waiting on whom",
        "threads status           # one-line summary",
        "threads archive          # move resolved threads to archive",
        "threads template          # list available templates",
      ].join("\n")}</CodeBlock>
    </Section>

    <Section title="How it works">
      <Paragraph>
        {"A threads file is plain markdown — a flat sequence of "}
        <Link href="https://help.obsidian.md/callouts">Obsidian callouts</Link>
        {", each representing a conversation thread:"}
      </Paragraph>

      <List>
        <Item>
          <Code>{"[!info]-"}</Code>
          {" — pinned instructions (always at top, never reordered)"}
        </Item>
        <Item>
          <Code>{"[!warning]- 👈"}</Code>
          {" — needs human attention"}
        </Item>
        <Item>
          <Code>{"[!note]-"}</Code>
          {" — active thread"}
        </Item>
        <Item>
          <Code>{"[!success]-"}</Code>
          {" — resolved (ready to archive)"}
        </Item>
      </List>

      <Paragraph>
        {"Messages within a thread start with "}
        <Code>{"**[Name]**"}</Code>
        {", separated by "}
        <Code>{"> ---"}</Code>
        {" dividers. Arrow notation tracks rewrites: "}
        <Code>{"**[Or → ikma]**"}</Code>
        {" means \"Or's words, as rewritten by ikma.\""}
      </Paragraph>

      <Paragraph>
        <Bold>{"Turn-taking drives automation."}</Bold>
        {" The last sender determines who's waiting. If a human sent the last message, agents are waiting. If an agent replied, the human is waiting. "}
        <Code>fmt</Code>
        {" uses this to auto-promote threads to "}
        <Code>[!warning]</Code>
        {" when they need human attention, demote back to "}
        <Code>[!note]</Code>
        {" when the human has replied, and sort warnings to the top."}
      </Paragraph>

      <Paragraph>
        {"The human name defaults to "}
        <Code>Or</Code>
        {" but is configurable via "}
        <Code>THREADS_HUMAN</Code>
        {". When unset, turn-taking is disabled — useful for peer-to-peer files like bulletin boards where there's no human in the loop."}
      </Paragraph>
    </Section>

    <Section title="Daily workflow">
      <CodeBlock lang="bash">{[
        "$ threads ls",
        "╭───────────┬──────────────────────────────────────┬───────────────────┬────────────╮",
        "│ Status    │ Thread                               │ Participants      │ Waiting on │",
        "├───────────┼──────────────────────────────────────┼───────────────────┼────────────┤",
        "│ info      │ How this works                       │ —                 │ —          │",
        "│ attention │ Retry logic for webhook handler      │ Or+, ikma*        │ Or         │",
        "│ active    │ Refactor auth module                 │ ikma+*, Or        │ agent      │",
        "│ resolved  │ Fix CI timeout                       │ Or+, baby-joel*   │ resolved   │",
        "╰───────────┴──────────────────────────────────────┴───────────────────┴────────────╯",
        "  + started thread  * last sender",
        "",
        "$ threads fmt",
        "Formatted: promoted 1 to warning, sorted.",
        "",
        "$ threads status",
        "4 threads: 1 waiting on agent, 1 waiting on Or, 1 resolved, 1 no messages",
        "",
        "$ threads archive",
        "Archived 1 resolved thread(s) to HUMAN.archive.md.",
      ].join("\n")}</CodeBlock>
    </Section>

    <Section title="File resolution">
      <Paragraph>
        {"Every command accepts "}
        <Code>--file</Code>
        {" to specify the threads file. Without it, threads checks "}
        <Code>$THREADS_FILE</Code>
        {", then falls back to "}
        <Code>HUMAN.md</Code>
        {" in the current directory."}
      </Paragraph>

      <CodeBlock lang="bash">{[
        "# Explicit",
        "threads ls --file ~/path/to/HUMAN.md",
        "",
        "# Via environment",
        "export THREADS_FILE=\"$HUMAN_MD\"",
        "threads ls",
        "",
        "# Default: ./HUMAN.md",
        "cd ~/project && threads ls",
      ].join("\n")}</CodeBlock>
    </Section>

    <Section title="Development">
      <CodeBlock lang="bash">{[
        "git clone https://github.com/KnickKnackLabs/threads.git",
        "cd threads && mise trust && mise install",
        "mise run test",
      ].join("\n")}</CodeBlock>

      <Paragraph>
        <Bold>{`${testCount} tests`}</Bold>
        {` across ${testFiles.length} suites. The parser is ${parserLines} lines of Python in `}
        <Code>lib/human_threads.py</Code>
        {". Core commands are Python mise file tasks that call into the shared parser; shell remains for small wrappers and tests. Templates use "}
        <Link href="https://github.com/KnickKnackLabs/farts">farts</Link>
        {" for frontmatter."}
      </Paragraph>

      <Details summary="Project structure">
        <CodeBlock>{[
          "threads/",
          "├── .mise/tasks/",
          `│   ├── fmt        # Format: codeblock→callout, promote/demote, sort`,
          `│   ├── ls         # List threads with status and waiting-on`,
          `│   ├── status     # Quick thread count summary`,
          `│   ├── archive    # Move resolved threads to archive file`,
          `│   └── template   # Output a template to stdout`,
          "├── lib/",
          "│   └── human_threads.py   # Parser: callouts, authors, waiting-on logic",
          "├── templates/",
          `│   └── *.md               # ${templateCount} template(s) with frontmatter metadata`,
          "└── test/",
          `    └── *.bats             # ${testCount} tests`,
        ].join("\n")}</CodeBlock>
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
