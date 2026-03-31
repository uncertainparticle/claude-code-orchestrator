#!/usr/bin/env bash
# delegate.sh — Invoke Claude Code with structured task prompt
# Usage: ./delegate.sh <session_id> <task> <source_file> <repo_path>
#
# Example:
#   ./delegate.sh abc123 "Implement fix for C-1..." audit.md ~/repos/myapp

set -euo pipefail

SESSION_ID="${1:?Usage: $0 <session_id> <task> <source_file> <repo_path>}"
TASK="${2:?Task description required}"
SOURCE_FILE="${3:?Source file required}"
REPO_PATH="${4:?Repo path required}"

MODEL="${CLAUDE_MODEL:-claude-opus-4-6}"
FLAGS="${CLAUDE_FLAGS:---dangerously-skip-permissions --effort max --permission-mode plan}"

PROMPT="Implement the fix for: ${TASK}

Based on: ${SOURCE_FILE}
Working directory: ${REPO_PATH}

Read the relevant section in ${SOURCE_FILE}, implement the fix, and report what was changed.
Do NOT run any notification commands."

cd "$REPO_PATH"
claude --model "$MODEL" $FLAGS "$PROMPT"
