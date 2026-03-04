#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

python3 tools/deploy_academic_tally.py --input data/academic_tally.json --output-dir artifacts/academic
