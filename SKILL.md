---
name: claude-code-orchestrator
description: >
  Orchestrate sequential coding task implementation by delegating to Claude Code. Built for and tested in
  OpenClaw (headless AI agent runtime). Use when given a list of findings, fixes, audit items, or
  implementation tasks to work through one-by-one. Triggers on: "delegate to Claude Code orchestrator",
  "work through audit findings sequentially", "orchestrate a list of tasks", "implement recommendations
  in order". The orchestrator never writes code — it prompts, monitors, reviews plans, commits, and advances.
---

# Claude Code Orchestrator — Skill Reference

This is the agent-facing skill definition. It defines how an AI orchestrator should drive sequential coding tasks using Claude Code in OpenClaw.

---

## Trigger

The orchestrator activates when given:
- A list of findings, tasks, or recommendations to implement
- A source file (audit report, spec, migration checklist)
- Instructions to work through them sequentially

Example invocations:
- "Delegate to Claude Code orchestrator"
- "Work through the findings in [file] sequentially"
- "Orchestrate the implementation of [spec] using Claude Code"
- "Run the audit-fix loop from [audit file]"

---

## Before Starting — Confirm Inputs

If any are missing, ask before proceeding:

| Input | Description | Example |
|-------|-------------|---------|
| `source_file` | Path to audit/report/plan with findings | `~/repos/my-app/audit.md` |
| `repo_path` | Working directory for Claude Code | `~/repos/my-app` |
| `task_list` | Ordered list of findings/tasks | Sections from audit |
| `skip_list` | Tasks to exclude (already done, manual-only) | `#1 Benchmark Data` |
| `claude_flags` | Runtime flags | `plan mode, max effort, --dangerously-skip-permissions` |
| `branch` | Push target | `main` or `fix/production-hardening` |

---

## Classifying Tasks

Split every finding into two buckets:

**Code tasks** — source code changes, config files, scripts, tests. Delegate these.

**Manual tasks** — secret rotation, third-party dashboard config, DNS, key provisioning. Collect these and present as a checklist at the end. Never delegate manual tasks.

---

## Priority Ordering

Work through code tasks in the priority order defined by the source document:

1. **CRITICAL** — security vulnerabilities, data loss risks, blocking issues
2. **HIGH** — significant functionality gaps, reliability concerns
3. **MEDIUM** — improvements, optimizations
4. **LOW** — polish, minor enhancements

Within the same tier, follow the source document order.

---

## Execution Loop

For each code task:

### Step 1 — Delegate

Prompt Claude Code with:

> Implement the fix/recommendation for [finding title] based on [source file path].
> Focus specifically on section [section heading or number].

Include the section title, file path, and context that scopes the work.

### Step 2 — Review the Plan

Claude Code will produce a plan (plan mode). Check:
- Does it address the right finding?
- Is the scope reasonable?
- Does it touch the right files?

If the plan looks right:
> Proceed with implementation.

If the plan is off-target:
> This plan is off-scope. The finding is specifically about [X]. Revise the plan to focus on [X].

### Step 3 — Wait and Monitor

Wait for Claude Code to complete. If the session dies before completing:
1. Check `git status` for staged/unstaged changes
2. Commit if changes exist: `git add -A && git commit -m "fix: [title]"`
3. Resume: `claude --resume [session-id]` or start a new session for remaining work
4. Report what was completed vs. remaining

### Step 4 — Security Review

After the main implementation is clean (no errors), **run a security review before committing.**

Prompt Claude Code:
> Run `/security-review` on the code changes introduced by this task. Check for: injection vectors, auth bypass, data exposure, input validation gaps, dependency vulnerabilities, and any patterns that could introduce security regressions.

If vulnerabilities are found:
1. Delegate the fixes: "The security review found [list of issues]. Implement fixes for each."
2. After fixes are applied, run `/security-review` again to verify all issues are resolved.
3. Once clean, proceed to commit.

If no vulnerabilities are found:
> Proceed with commit.

### Step 5 — Review Completion

If errors or test failures:
> Analyze the error and resolve the issue.

Repeat until clean.

If clean:
> Please commit and push to [branch] with message: [prefix]: [finding title]

Commit prefix convention:
- `fix:` for bug fixes and security issues
- `feat:` for new functionality
- `refactor:` for structural improvements
- `chore:` for config, tooling, or housekeeping

### Step 6 — Confirm and Advance

Wait for Claude Code to confirm the commit and push succeeded. Only then move to the next task.

If the commit or push fails:
> Analyze the error and resolve the issue.

---

## Error Recovery — 3-Strike Rule

1. First attempt: Tell Claude Code "Analyze the error and resolve it."
2. Second attempt (same error): Tell Claude Code "The previous fix didn't resolve it. Try a different approach."
3. Third attempt (same error): Log the finding as **blocked**, note the error, move to the next task. Report blocked tasks in the final summary.

---

## Watchdog Timer

Check every ~5 minutes. If the process has stopped, died, or gone silent:
1. Check `git status` to see what was completed
2. Commit if needed
3. Resume or restart for remaining work
4. Continue the loop

---

## Final Summary

After all code tasks are complete (or attempted), produce:

## Completed Code Fixes
| # | Finding | Commit Message | Status |
|---|---------|---------------|--------|
| 1 | [title] | fix: [title] | ✅ Done |
| 2 | [title] | feat: [title] | ✅ Done |
| 3 | [title] | — | ❌ Blocked (error: ...) |

## Manual Tasks Remaining
Grouped by priority — specific and actionable, with env var names and config paths where relevant.

---

## Session Death Pattern

Claude Code sessions in background PTY mode tend to die at ~10 minutes with SIGTERM (code 143). This is expected — plan mode and complex tasks take time. The work is usually complete before death; only the final commit/push step fails to run.

**Always check `git status` after a death.** Commit directly if changes exist.

---

## Prompt Template — Quick Start

```
Delegate all coding to Claude Code — model [model], max effort, plan mode on,
--dangerously-skip-permissions. You write zero code yourself. You are the orchestrator only.

We are implementing findings from [source file]. Review that file.

Skip these (already completed or not applicable):
- [item 1]
- [item 2]

Skip any finding that requires manual action on my part — collect those and present
them as a checklist at the end. Only delegate findings that are code changes.

Work through code-fixable findings in strict priority order: all CRITICALs first,
then HIGHs, then MEDIUMs. One finding at a time.

For each finding:
1. Tell Claude Code: "Implement the fix for [finding title] based on [source file]"
2. Review the plan, reply "proceed with implementation"
3. Wait for completion:
   - If errors → "analyze the error and resolve the issue"
   - If clean → run `/security-review` on the changes
4. If security issues are found: delegate fixes to Claude Code, then re-run `/security-review` until clean
5. Once security review passes: "please commit and push to [branch] with message: [prefix]: [finding title]"
6. Wait for commit confirmation, then move to next

Health check: every 5 minutes, check Claude Code status.
If the process has stopped or died: "resume where you left off on [current finding]"
If usage limit hit: wait, then "continue where you left off"

After all code fixes: produce a final summary with commit messages and manual task checklist.
```
