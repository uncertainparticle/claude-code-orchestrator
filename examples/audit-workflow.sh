#!/usr/bin/env bash
# audit-workflow.sh — Run the full audit-fix loop
# Usage: ./audit-workflow.sh <audit_file> <repo_path> [branch]
#
# This script orchestrates the full workflow:
#   1. Read the audit file
#   2. Classify findings (code vs manual)
#   3. Delegate each code finding to Claude Code
#   4. Commit after each fix
#   5. Produce final summary
#
# Prerequisites:
#   - Claude Code CLI installed
#   - Git repo clean (or no uncommitted changes you care about)

set -euo pipefail

AUDIT_FILE="${1:?Usage: $0 <audit_file> <repo_path> [branch]}"
REPO_PATH="${2:?Repo path required}"
BRANCH="${3:-main}"

MODEL="${CLAUDE_MODEL:-claude-opus-4-6}"
FLAGS="${CLAUDE_FLAGS:---dangerously-skip-permissions --effort max --permission-mode plan}"

cd "$REPO_PATH"

echo "============================================"
echo "Audit → Fix Orchestrator"
echo "============================================"
echo "Audit:  $AUDIT_FILE"
echo "Repo:   $REPO_PATH"
echo "Branch: $BRANCH"
echo ""

# Step 1: Ask Claude Code to read the audit and classify findings
echo "Step 1: Reading and classifying findings..."
CLASSIFICATION=$(claude --model "$MODEL" $FLAGS \
  "Read $AUDIT_FILE and produce a structured classification:
   1. List all findings with their priority (CRITICAL/HIGH/MEDIUM/LOW) and number
   2. For each, mark CODE or MANUAL
   3. List the CODE findings in priority order
   Output as a simple markdown table." 2>&1 | tee /tmp/audit-classify.log)

echo "$CLASSIFICATION"
echo ""

# Step 2: Ask Claude Code to work through the code findings
echo "Step 2: Beginning fix loop..."
claude --model "$MODEL" $FLAGS \
  "You are orchestrating the fix loop for: $AUDIT_FILE

Working directory: $REPO_PATH
Branch: $BRANCH

Read $AUDIT_FILE. Work through each CODE-classified finding in priority order (CRITICAL first, then HIGH, MEDIUM, LOW).

For each finding:
1. Delegate: 'Implement the fix for [finding] based on $AUDIT_FILE. Focus on section [X].'
2. If the plan is off-target: 'This plan is off-scope. The finding is specifically about [X].'
3. Wait for completion.
4. If errors: 'Analyze the error and resolve the issue.'
5. If clean: 'Please commit and push to $BRANCH with message: fix: [finding title]'
6. Wait for commit confirmation.
7. Move to the next finding.

After all findings:
1. Produce a final summary table (Finding | Commit | Status)
2. List all MANUAL findings as a checklist for the human to complete.

Do NOT write any code yourself. Do all work through delegation." 2>&1 | tee /tmp/audit-fix.log

echo ""
echo "============================================"
echo "Audit fix loop complete."
echo "Review /tmp/audit-fix.log for the full session log."
echo "============================================"
