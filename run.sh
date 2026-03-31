#!/usr/bin/env bash
# Claude Code Orchestrator — Quick Start Script
# Usage: ./run.sh [source_file] [repo_path] [branch]
#
# Example:
#   ./run.sh ~/repos/myapp/audit.md ~/repos/myapp main

set -euo pipefail

# ── Configuration ────────────────────────────────────────────
MODEL="${CLAUDE_MODEL:-claude-opus-4-6}"
FLAGS="${CLAUDE_FLAGS:---dangerously-skip-permissions --effort max --permission-mode plan}"
BRANCH="${CLAUDE_BRANCH:-main}"
# ────────────────────────────────────────────────────────────

SOURCE_FILE="${1:-}"
REPO_PATH="${2:-.}"
TARGET_BRANCH="${3:-$BRANCH}"

if [[ -z "$SOURCE_FILE" ]]; then
  echo "Usage: $0 <source_file> <repo_path> [branch]"
  echo "  source_file  — Path to audit/report/migration file"
  echo "  repo_path    — Working directory for Claude Code (default: .)"
  echo "  branch       — Git branch to push to (default: main)"
  echo ""
  echo "Environment variables:"
  echo "  CLAUDE_MODEL      — Model to use (default: claude-opus-4-6)"
  echo "  CLAUDE_FLAGS      — CLI flags (default: --dangerously-skip-permissions --effort max --permission-mode plan)"
  echo "  CLAUDE_BRANCH     — Default branch (default: main)"
  exit 1
fi

echo "============================================"
echo "Claude Code Orchestrator"
echo "============================================"
echo "Source:    $SOURCE_FILE"
echo "Repo:     $REPO_PATH"
echo "Branch:   $TARGET_BRANCH"
echo "Model:    $MODEL"
echo "Flags:    $FLAGS"
echo "============================================"

cd "$REPO_PATH"

echo ""
echo "Paste your task prompt below. Example:"
echo "  'Work through the findings in $SOURCE_FILE...'"
echo "  (Ctrl+D to submit)"
echo ""

# Read multi-line prompt from stdin
PROMPT=$(cat)

SESSION_ID=$(claude --model "$MODEL" $FLAGS "$PROMPT" 2>&1 \
  | tee /tmp/orchestrator-output.$$.log \
  | grep -o '[a-z0-9]\{4,12\}-[a-z0-9]\{4,12\}' | tail -1 || true)

if [[ -n "$SESSION_ID" ]]; then
  echo ""
  echo "Session started: $SESSION_ID"
  echo "Monitor with: ./src/monitor.sh $SESSION_ID"
fi
