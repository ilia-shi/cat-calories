---
name: command-authoring
description: How to write slash commands (`.claude/commands/*.md`) and skills in this repo so they execute reliably on every assistant, including the least capable one that might run them. Use whenever creating or editing a command or skill file, or when a command produced a sloppy or incomplete result and the instructions need tightening. Its central rule: a command must contain no step that requires judgment the weakest reader cannot supply — replace every vague qualifier with an explicit rule, an exact command sequence, and a checkable end state. Do NOT use for ordinary feature, UI, or refactor work.
---

# Writing commands and skills

A command file is a program whose interpreter varies. The same file may be executed by a
highly capable assistant or a small, fast one, and you do not get to choose which. Write for
the least capable reader: assume it will not infer your conventions, will not read code you
did not tell it to read, and will take the shortest path that satisfies the literal text.

Capability differences show up in judgment, not mechanics. Every assistant can run
`git add`; the weak point is any step where the file says *decide something*. So the work of
authoring is converting judgment into procedure.

Never name a specific assistant or model in a command — the file has no way to know which one
is executing it, and instructions keyed to a name silently fail everywhere else. Write
capability-neutral steps that are correct for all of them.

## Rule 1 — Vague qualifiers are the loophole

Words like *clearly*, *obviously*, *if appropriate*, *when it makes sense*, *as needed* read
as precision to you and as permission to skip to a weaker reader. It will find the
interpretation that ends the turn soonest, and it will be able to defend that reading.

This repo hit exactly that. `/commit` said *"include untracked files that are clearly part of
the work"*, so a new untracked directory was declared not-part-of-the-work and left behind —
correctly, per the text. The fix was to remove the judgment entirely:

```markdown
<!-- BEFORE — the qualifier decides the outcome, and the reader owns the decision -->
Include untracked files that are clearly part of the work.

<!-- AFTER — a rule, a closed exception list, and a duty to speak up -->
Everything in the working tree gets committed, including untracked files.
"Not part of the feature" is never a reason to leave a file behind; it is a
reason to give it its own commit. The sole exceptions, which you skip and then
name explicitly in your report: gitignored files, build output, secrets, and
scratch files created while working.
```

State the rule, then enumerate the exceptions exhaustively. An open-ended exception is not an
exception, it is an escape hatch.

## Rule 2 — Show a worked example instead of describing a style

Abstract style guidance ("explain *why* the change was made, don't restate the diff") is the
single hardest kind of instruction to follow. Assistants pattern-match far more reliably than
they follow prose rules, and a weaker one falls back to the generic convention it already
knows unless something concrete overrides it.

Paste a real artifact from this repo, then say what to notice about it. Pair it with a
**counter-example** that is plausible but wrong — that blocks the specific default the reader
would otherwise reach for. `/commit` carries both: a real commit message, and the bulleted
diff-summary body that would be accurate and still wrong here.

One good example beats three paragraphs of description, and it is shorter.

## Rule 3 — Give exact commands, in order, with the flags that matter

Do not describe a goal and trust the reader to reach it. Write the sequence:

```bash
git reset                       # unstage everything, so nothing leaks in
git add <paths for this group>  # explicit paths only
git status --short              # confirm precisely the intended paths are staged
```

Include flags whose absence changes what the reader *sees*, and say why: plain
`git status --short` collapses an untracked directory to one `?? dir/` line, so a reader
using it never learns which files it is skipping. A missing flag like that causes silent
wrong behavior, not an error.

Where a step exists to prevent a specific failure, attach the consequence to it inline —
*"re-run this before each group; skipping it is how unrelated files end up in the wrong
commit"*. A step with a stated purpose survives; a bare step gets optimized away.

## Rule 4 — End on a checkable state, not a feeling

Finish every command with something whose output has one acceptable shape, and say what that
shape is:

```markdown
Run `git status --short --untracked-files=all` after the last commit. It must
print nothing. If anything remains, either commit it too or state why it falls
under the exceptions above — do not end the turn silently leaving files behind.
```

For work products that no command can verify — a written message, a design choice — use a
short list of yes/no questions the reader must answer about its own draft before proceeding.
Three is plenty. Questions with a factual answer ("does the first sentence describe the
situation *before* this change?") work; questions asking for a quality rating do not.

## Rule 5 — One default path, and keep it short

Every branch is a chance to take the wrong one. Prefer a single default procedure; where a
variant is genuinely needed, bound it (*"at most three commits; when torn, prefer fewer"*)
and give it its own fixed sequence rather than leaving the reader to improvise.

Length actively hurts. More prose means more to skim past and dilutes the parts that matter,
so a tightened command is usually a *shorter* one — cut description, keep procedure and
examples. Put each constraint immediately before the action it constrains, not in a preamble.

## Rule 6 — Wire the frontmatter to the procedure

- `description` states when to use the command and when not to. It is the only part read
  before the file is loaded, so vagueness here means it never runs or runs at the wrong time.
- `allowed-tools` must cover every command the procedure actually issues. A step that stalls
  on a permission prompt is a step that gets abandoned or worked around.
- `argument-hint` shows the invocation shape when the command takes arguments.

## Verify

Run the command against a real, messy working tree — not a hypothetical one — and read the
transcript for the first point where it deviated from what you intended. That point is a
defect in the file, not in the assistant: find the sentence that permitted the deviation and
replace it per Rule 1. Re-run until the transcript is boring.

Skills live in `skills/<name>/SKILL.md` and are shared with other tools by symlink; edit them
there, never through `.claude/skills`. Commands live in `.claude/commands/<name>.md`.
