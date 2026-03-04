#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${TOTALITY_BASE:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
cd "$BASE_DIR"

LOG_FILE="nexus-pro-lab.log"
: > "$LOG_FILE"
nohup python3 nexus-pro-lab.py serve > "$LOG_FILE" 2>&1 &
PID=$!
sleep 1

if ! kill -0 "$PID" >/dev/null 2>&1; then
  echo "TOTALITY PRO LAB failed to start. Recent log output:"
  tail -n 20 "$LOG_FILE" || true
  exit 1
fi

echo "TOTALITY PRO LAB started on http://localhost:8120 (pid=$PID)"
