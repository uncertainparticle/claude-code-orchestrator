# Claude Code Orchestrator

A lightweight, reusable orchestration pattern for delegating sequential coding tasks to Claude Code. Designed for and tested in **OpenClaw** (headless AI agent runtime) running in background PTY sessions — the orchestrator prompts, monitors, handles failures, and drives tasks to completion without writing any code itself.

> **Built for OpenClaw.** This pattern was developed and tested in production with OpenClaw. The orchestrator runs as an AI agent that coordinates Claude Code via background PTY sessions, automatically committing after each task and resuming if sessions are interrupted.

---

## What It Does

You (the orchestrator) take a list of tasks and drive them to completion by delegating each one to Claude Code. You never write or edit code yourself. You prompt, monitor, review, and advance.

**Key principles:**
- You write zero code. All implementation is delegated to Claude Code.
- One task at a time. Never start the next task until the current one is committed.
- Security review before every commit. After each task, run `/security-review` — if vulnerabilities are found, fix them first, then commit.
- Watchdog duty. Actively monitor Claude Code and intervene if it stalls or dies.
- Structured handoffs. Every prompt to Claude Code is specific and references the source document.

---

## Setup

### Prerequisites

- **OpenClaw** installed and running (this pattern is designed for OpenClaw agents)
- Claude Code CLI installed (`npm install -g @anthropic-ai/claude-code`)
- Git
- Model: `claude-opus-4-6` (or your preferred model)
- Flags: `--dangerously-skip-permissions` (bypasses permission prompts for automated use)

### Quick Start

```bash
# Clone or copy this repo
git clone https://github.com/uncertainparticle/claude-code-orchestrator.git
cd claude-code-orchestrator

# Make the run script executable
chmod +x run.sh

# Edit run.sh — set your MODEL and FLAGS
# Then run the orchestrator:
./run.sh
```

---

## How It Works

### The Execution Loop

For each task in priority order:

1. **Delegate** — Prompt Claude Code with the specific task, source file, and scope
2. **Review the plan** — If plan mode produces a plan, check it for relevance
3. **Monitor** — Wait for completion. If the session dies, check git status, commit what exists, resume
4. **Confirm** — If clean: ask Claude Code to commit and push. If errors: ask it to fix
5. **Advance** — Move to the next task

### Error Recovery

| Situation | Action |
|-----------|--------|
| Session dies mid-task | Check `git status`, commit what exists, resume |
| Session hangs/stops producing output | Interrupt and restart with remaining work |
| Usage limit hit | Wait for reset, resume with "continue where you left off" |
| Plan is off-target | Revise scope, don't proceed |

### Session Death Pattern

Claude Code sessions in background PTY mode tend to die at ~10 minutes with SIGTERM (code 143). This is expected — plan mode and complex tasks take time. The work is usually complete before death; only the final commit/push step fails to run.

**Always check `git status` after a death.** Commit directly if changes exist.

---

## Project Structure

```
claude-code-orchestrator/
├── README.md              — This file
├── SKILL.md               — The orchestrator skill (agent-facing)
├── run.sh                 — Quick-start shell script
├── src/
│   ├── orchestrator.sh     — Core orchestration loop (shell)
│   ├── delegate.sh          — Claude Code invocation wrapper
│   ├── monitor.sh           — Watchdog / status checker
│   └── commit.sh           — Commit & push helper
└── examples/
    ├── audit-workflow.sh   — Example: audit → prioritize → fix loop
    └── migration-workflow.sh — Example: sequential migration tasks
```

---

## Usage Patterns

### Pattern 1: Audit → Fix Loop

1. Give the orchestrator an audit report (Markdown with findings)
2. It classifies each finding as **code** or **manual**
3. Code findings are delegated to Claude Code one-by-one
4. Each fix is committed before moving to the next
5. At the end: a structured report of what was done + manual tasks checklist

### Pattern 2: Sequential Feature Implementation

1. Give the orchestrator a spec document with numbered sections
2. It works through sections in priority order
3. Each section is delegated, reviewed, committed
4. Dependencies are noted and respected

### Pattern 3: Tech Debt Backlog

1. Give the orchestrator a backlog with priorities
2. It works through items highest-priority first
3. Each item is a discrete, independently-committable change

---

## Running Without the Shell scripts

If you prefer to run manually or integrate into your own tooling:

```bash
# Delegate a task
MODEL="claude-opus-4-6"
FLAGS="--dangerously-skip-permissions --effort max --permission-mode plan"

claude --model $MODEL $FLAGS "Implement the fix for [finding title] based on [source file]. [specific scope]. Report what was changed."

# Wait for completion, then:
git add -A && git commit -m "[commit message]" && git push origin main
```

---

## Customization

### Model & Flags

Edit `run.sh` to set your preferred model and flags:

```bash
MODEL="claude-opus-4-6"
FLAGS="--dangerously-skip-permissions --effort max --permission-mode plan"
BRANCH="main"
```

### Commit Prefix Convention

Use consistent prefixes across all commits:

- `fix:` — bug fixes and security issues
- `feat:` — new functionality
- `refactor:` — structural improvements
- `chore:` — config, tooling, housekeeping

---

## License

MIT — Use freely, modify, distribute, commercial or personal.

---

## Contributing

PRs welcome. Key areas for improvement:
- Integration with GitHub Actions for CI-based orchestration
- Support for parallel task execution with dependency tracking
- Webhook-based completion detection (instead of polling)
- Integration with task managers (Linear, Notion, etc.)
