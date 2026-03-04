#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$ROOT_DIR/skills/vercel-one-click-deploy/scripts/deploy.sh" "${1:-$ROOT_DIR}"
