#!/usr/bin/env bash
# monitor.sh — Watchdog for Claude Code sessions
# Usage: ./monitor.sh <session_id> [interval_seconds]
#
# Watches a Claude Code session and reports if it dies or goes silent.
# Checks every 60 seconds by default.

set -euo pipefail

SESSION_ID="${1:?Usage: $0 <session_id> [interval_seconds]}"
INTERVAL="${2:-60}"

echo "Monitoring session: $SESSION_ID (every ${INTERVAL}s)"
echo "Press Ctrl+C to stop monitoring"
echo ""

LAST_LOG_SIZE=0

while true; do
  if ! pgrep -f "claude.*$SESSION_ID" > /dev/null 2>&1; then
    echo "[$(date)] ⚠️  Session $SESSION_ID appears to have stopped."
    echo ""
    echo "Last known status:"
    git -C "$REPO_PATH" status --short 2>/dev/null || echo "  (could not read git status)"
    break
  fi

  LOG_SIZE=$(wc -c < /tmp/orchestrator-output.$$.log 2>/dev/null || echo 0)
  if [[ "$LOG_SIZE" -eq "$LAST_LOG_SIZE" ]]; then
    echo "[$(date)] 💤 Silent for ${INTERVAL}s (no new output)"
  else
    echo "[$(date)] ✅ Active — ${LOG_SIZE} bytes logged"
  fi
  LAST_LOG_SIZE=$LOG_SIZE

  sleep "$INTERVAL"
done
