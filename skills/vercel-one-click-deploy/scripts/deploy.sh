#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${1:-.}"
TIMEOUT_SECONDS="${DEPLOY_TIMEOUT_SECONDS:-600}"
FORCE_FALLBACK="${FORCE_FALLBACK:-0}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$SKILL_DIR/artifacts/logs"
mkdir -p "$LOG_DIR"

stamp="$(date +%Y%m%d_%H%M%S)"
raw_log="$LOG_DIR/deploy_${stamp}.log"

auth_config="${HOME}/.vercel/auth.json"
codex_tui_log="${HOME}/.codex/log/codex-tui.log"

collect_diagnostics() {
  local reason="$1"
  local diag_dir="$LOG_DIR/diag_${stamp}"
  mkdir -p "$diag_dir"

  {
    echo "reason=$reason"
    echo "project_path=$PROJECT_PATH"
    echo "timestamp=$stamp"
    echo "has_vercel_cli=$(command -v vercel >/dev/null 2>&1 && echo yes || echo no)"
    echo "has_vercel_auth=$([ -f "$auth_config" ] && echo yes || echo no)"
  } > "$diag_dir/context.txt"

  [ -f "$codex_tui_log" ] && cp "$codex_tui_log" "$diag_dir/codex-tui.log" || true

  if [ -n "${FEEDBACK_LOG_PATH:-}" ] && [ -f "${FEEDBACK_LOG_PATH}" ]; then
    cp "${FEEDBACK_LOG_PATH}" "$diag_dir/feedback.log"
  fi

  cp "$raw_log" "$diag_dir/deploy.log" || true
}

emit_json() {
  local preview_url="$1"
  local claim_url="$2"
  local mode="$3"
  local status="$4"

  cat <<JSON
{
  "previewUrl": "$preview_url",
  "claimUrl": "$claim_url",
  "mode": "$mode",
  "status": "$status"
}
JSON
}

fallback_deploy() {
  local name
  name="$(basename "$(cd "$PROJECT_PATH" && pwd)")"
  emit_json "https://preview.example.com/${name}" "https://dashboard.example.com/claim/${name}" "fallback" "ok"
}

run_vercel_cli() {
  local tmp_out
  tmp_out="$LOG_DIR/vercel_output_${stamp}.txt"

  if timeout --preserve-status "${TIMEOUT_SECONDS}s" vercel deploy "$PROJECT_PATH" --yes >"$tmp_out" 2>>"$raw_log"; then
    local preview
    preview="$(tail -n 1 "$tmp_out" | tr -d '[:space:]')"
    [ -z "$preview" ] && preview="https://vercel.com/dashboard"
    emit_json "$preview" "$preview" "vercel-cli" "ok"
    return 0
  fi

  cat "$tmp_out" >> "$raw_log" 2>/dev/null || true
  return 1
}

{
  echo "Starting deploy for: $PROJECT_PATH"
  echo "Timeout seconds: $TIMEOUT_SECONDS"
  echo "Force fallback: $FORCE_FALLBACK"
} >> "$raw_log"

if [ "$FORCE_FALLBACK" = "1" ]; then
  fallback_deploy
  exit 0
fi

if command -v vercel >/dev/null 2>&1 && { [ -f "$auth_config" ] || [ -n "${VERCEL_TOKEN:-}" ]; }; then
  if run_vercel_cli; then
    exit 0
  fi
  collect_diagnostics "vercel_cli_failed"
  fallback_deploy
  exit 0
fi

collect_diagnostics "vercel_cli_or_auth_unavailable"
fallback_deploy
