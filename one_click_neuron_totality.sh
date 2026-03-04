#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${1:-/TOTAL1TY_SUPER_RELEASE}"

"$ROOT_DIR/neuron_totality_preflight.sh" "$ROOT_DIR/.codex/neuron_totality.toml"
"$ROOT_DIR/deploy_academic_tally.sh"

if command -v codex >/dev/null 2>&1; then
  "$ROOT_DIR/deploy_total1ty.sh" "$WORKSPACE"
else
  echo "WARN: codex CLI not found; skipped deploy_total1ty.sh"
fi

# Preview-safe deploy pathway for CI/sandbox by default.
FORCE_FALLBACK="${FORCE_FALLBACK:-1}" "$ROOT_DIR/one_click_preview_deploy.sh" "$ROOT_DIR"
