#!/usr/bin/env bash
# migration-workflow.sh — Run sequential database/API migrations
# Usage: ./migration-workflow.sh <migration_file> <repo_path> [branch]
#
# Works through a migration checklist, delegating each migration to Claude Code
# and committing after each successful migration.

set -euo pipefail

MIGRATION_FILE="${1:?Usage: $0 <migration_file> <repo_path> [branch]}"
REPO_PATH="${2:?Repo path required}"
BRANCH="${3:-main}"

MODEL="${CLAUDE_MODEL:-claude-opus-4-6}"
FLAGS="${CLAUDE_FLAGS:---dangerously-skip-permissions --effort max --permission-mode plan}"

cd "$REPO_PATH"

echo "Migration Orchestrator — $MIGRATION_FILE"
echo ""

claude --model "$MODEL" $FLAGS \
  "Work through the migration tasks in: $MIGRATION_FILE

For each migration task:
1. Delegate: 'Apply the migration: [task description] from $MIGRATION_FILE'
2. After applying, run any associated tests or verify the migration succeeded
3. If tests fail: 'The migration caused test failures. Analyze and fix.'
4. If clean: 'Commit this migration with message: migrate: [task description]'
5. Move to the next task.

If a migration is blocked by a prior one (dependency): skip it, note it, and continue.

After all migrations:
- List any blocked/skipped migrations with reasons
- List any rollback steps needed if a migration goes wrong" 2>&1
