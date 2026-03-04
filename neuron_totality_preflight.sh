#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-.codex/neuron_totality.toml}"

if [ ! -f "$CONFIG_PATH" ]; then
  echo "FAIL: missing config at $CONFIG_PATH" >&2
  exit 1
fi

required_patterns=(
  '^\[system\]'
  '^\[profiles\.fast\]'
  '^\[profiles\.deep\]'
  '^\[skills\]'
  '^\[automations\.morning_commit_pulse\]'
  '^\[ask_features\]'
  '^\[security\]'
  '^\[verification\]'
  '^\[ui\]'
)

for pattern in "${required_patterns[@]}"; do
  if ! rg -q "$pattern" "$CONFIG_PATH"; then
    echo "FAIL: required section missing: $pattern" >&2
    exit 1
  fi
done

echo "PASS: neuron totality config preflight checks passed ($CONFIG_PATH)"
