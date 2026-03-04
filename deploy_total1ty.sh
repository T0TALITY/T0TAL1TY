#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${1:-/TOTAL1TY_SUPER_RELEASE}"
LOG_DIR="$WORKSPACE/logs"
STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/deploy_total1ty_${STAMP}.log"

mkdir -p "$LOG_DIR"

if ! command -v codex >/dev/null 2>&1; then
  echo "Error: codex CLI not found in PATH" | tee -a "$LOG_FILE"
  exit 127
fi

run_step() {
  local desc="$1"
  shift
  echo "\n==> $desc" | tee -a "$LOG_FILE"
  echo "Command: $*" | tee -a "$LOG_FILE"
  "$@" 2>&1 | tee -a "$LOG_FILE"
}

echo "Starting TOTAL1TY deployment workflow" | tee -a "$LOG_FILE"
echo "Workspace: $WORKSPACE" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"

run_step "Deploy all modules" \
  codex deploy --workspace "$WORKSPACE" --modules Research,Engine_Designs,Systems_Integrations,Combined_Release

run_step "Run full simulation suite" \
  codex simulate --workspace "$WORKSPACE" --supersimulation --hypersimulation --hubbleVoyagerSim --molten5D --infinityBattery --matterWhipSim

run_step "Compile combined LaTeX release" \
  codex compile --workspace "$WORKSPACE" --output Combined_Release/TOTAL1TY_LaTeX.tex

run_step "Compile combined Markdown release" \
  codex compile --workspace "$WORKSPACE" --output Combined_Release/TOTAL1TY_Markdown.md

run_step "Launch telemetry and webhook monitoring" \
  codex monitor --workspace "$WORKSPACE" --telemetry --webhooks

echo "\nTOTAL1TY workflow completed successfully." | tee -a "$LOG_FILE"
