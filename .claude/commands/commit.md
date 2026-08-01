---
description: Commit all uncommitted changes in this repo's commit-message style, splitting unrelated work into its own commit
argument-hint: "[optional scope hint, e.g. 'only the color label fix']"
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git reset:*), Bash(git commit:*), Bash(git log:*), Bash(git rev-parse:*), Read, Grep, Glob
---

Commit the current uncommitted work. $ARGUMENTS

## Gather context

Run these first, in parallel:

- `git status --short --untracked-files=all` — what is modified, staged,
  untracked. Use `--untracked-files=all`: plain `--short` collapses an
  untracked directory into a single `?? dir/` line and hides the files in it.
- `git diff` and `git diff --staged` — the actual change
- `git log --format='%s%n%b---' -10` — the house style you must match

Read any file whose diff alone does not tell you *why* the change was made. The
commit message has to explain the why, so you need to understand it.

## Decide the commits

**Everything in the working tree gets committed** — modified, deleted *and
untracked* files, including tooling and config (`.claude/`, `skills/`,
`Makefile`, docs). "Not part of the feature" is never a reason to leave a file
behind; it is a reason to give it its own commit. You are done only when
`git status --short` prints nothing.

The sole exceptions, which you skip and then **name explicitly in your final
report**: files git already ignores, build output, `.env` or anything holding a
secret, and scratch/debug files created while working.

**Group the paths.** Identify the main change — the largest set of edits that
belong to one story. Every remaining path joins a second group, or a third if
two clearly different themes remain (say, unrelated agent tooling *and* an
unrelated drive-by fix). Aim for at most three commits; when torn between two
groups and one, prefer one.

**Then stage and commit one group at a time**, in this exact order:

```bash
git reset                       # unstage everything, so nothing leaks in
git add <paths for this group>  # explicit paths only
git status --short              # confirm precisely the intended paths are staged
git commit -F - <<'EOF'
...
EOF
```

Repeat per group, main change first. Re-run `git reset` before each group —
skipping it is how unrelated files end up in the wrong commit.

Never `git add -A` or `git add .`, never `git reset --hard`, and never amend,
rebase or revert. Do not push (it is denied by policy anyway).

## Write the message

Match the existing log exactly — it is a consistent, distinctive style. Every
commit gets this treatment, including the small side commits: a tooling or
config commit still needs a real subject and a why-first body (`chore: add a
/commit slash command`), not a bare one-liner.

**Subject**: `type: lowercase imperative summary`, no trailing period, ≤72
chars. Types in use: `feat`, `fix`, `refactor`, `perf`, `chore`, `docs`.

**Body**: hard-wrapped prose at ~76 columns, blank line after the subject.
The **first sentence states the problem** — what the code did before and why
that was wrong or missing. Only then what the change does about it. Name the
concrete classes, files and flags involved. Mention deliberate non-obvious
decisions and known limitations. Use `- ` bullets only when the change really
is several separable parts; otherwise paragraphs.

This is a real commit from this repo — copy its shape:

```
feat: delete a meal along with all its records

Ungrouping was the only way to get rid of a meal, and it left every record
behind. The new option sits right below it in the meal options sheet, behind a
confirmation dialog that names the record count and total kcal and points back
at ungroup for anyone who wanted to keep the records.
```

Note what it does: problem first, in plain past tense; then the fix, with the
actual UI/class names; no bullet list; no restating of the diff.

A body like this is **wrong** for this repo, even though it is accurate:

```
- Add deleteMeal() to MealRepository
- Add a confirmation dialog
- Update tests
```

It lists what the diff already shows and never says why the change exists.

**Trailer**: blank line, then

```
Co-Authored-By: Claude <model name> <noreply@anthropic.com>
```

using your own model name from your environment context (e.g. `Claude Opus 5`).

## Check before you commit

Answer these three about your drafted message. If any answer is no, rewrite it
before running `git commit`:

1. Does the first sentence describe the situation **before** this change?
2. Would the body still be useful to someone who cannot see the diff?
3. Is it free of bullet lists that merely enumerate edited files or methods?

If you cannot answer 1 because you do not know why the change was made, go
read more of the code before writing anything.

Then pass the message via a heredoc so the wrapping survives:

```bash
git commit -F - <<'EOF'
feat: ...
EOF
```

## Finish

Run `git status --short --untracked-files=all` after the last commit. It must
print nothing. If anything remains, either commit it too or state in your
report why it falls under the exceptions above — do not end the turn silently
leaving files behind.

Report the subject line of each commit you made, and why you split them if you
made more than one.

If the commit fails because a hook rewrote or rejected files, fix the cause,
re-stage, and retry once — do not bypass hooks with `--no-verify`.
