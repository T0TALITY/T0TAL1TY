#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

APPROVED_VERSION="${1:-v1.1.0}"

python3 codex_launch.py --doctrine .codex/agent_registry.json --report .codex/orchestrator_report.json
python3 codex_publish.py \
  --config .codex/publish_config.json \
  --report .codex/orchestrator_report.json \
  --proposal minor \
  --approve-version "$APPROVED_VERSION"
