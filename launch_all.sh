#!/usr/bin/env bash
# Launch all TOTALITY LaTeX deployment pipelines from one command.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash launch_all.sh [--with-auto] [--skip-open] [--no-git] [--help]

Runs the key TOTALITY pipelines in order:
  1) deploy_cover.sh
  2) deploy_totality_cover.sh
  3) deploy_totality_nexus.sh
  4) deploy_totality_auto.sh   (only when --with-auto is set)

Options:
  --with-auto  Include deploy_totality_auto.sh in the run.
  --skip-open  Disable auto-open for child scripts that support NO_OPEN=1.
  --no-git     Disable git commit/push in child scripts that support NO_GIT=1.
  --help       Show this help text.
USAGE
}

WITH_AUTO=0
SKIP_OPEN=0
NO_GIT=0

for arg in "$@"; do
  case "$arg" in
    --with-auto) WITH_AUTO=1 ;;
    --skip-open) SKIP_OPEN=1 ;;
    --no-git) NO_GIT=1 ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "❌ Unknown argument: $arg"
      usage
      exit 2
      ;;
  esac
done

if ! command -v pdflatex >/dev/null 2>&1; then
  echo "❌ pdflatex is not installed or not in PATH."
  exit 1
fi

if [[ "$WITH_AUTO" -eq 1 ]] && ! command -v bibtex >/dev/null 2>&1; then
  echo "❌ bibtex is not installed or not in PATH (required with --with-auto)."
  exit 1
fi

run_step() {
  local label="$1"
  local script="$2"

  if [[ ! -f "$script" ]]; then
    echo "⚠️ Skipping $label ($script not found)."
    return 0
  fi

  echo
  echo "▶️  $label"

  local -a env_prefix=()
  [[ "$SKIP_OPEN" -eq 1 ]] && env_prefix+=("NO_OPEN=1")
  [[ "$NO_GIT" -eq 1 ]] && env_prefix+=("NO_GIT=1")

  if [[ "${#env_prefix[@]}" -gt 0 ]]; then
    env "${env_prefix[@]}" bash "$script"
  else
    bash "$script"
  fi

  echo "✅ Completed: $label"
}

run_step "Build standalone cover" "deploy_cover.sh"
run_step "Build cover + optional git integration" "deploy_totality_cover.sh"
run_step "Build full Nexus thesis + optional git integration" "deploy_totality_nexus.sh"

if [[ "$WITH_AUTO" -eq 1 ]]; then
  run_step "Run full auto-sync pipeline" "deploy_totality_auto.sh"
else
  echo
  echo "ℹ️ Skipping deploy_totality_auto.sh (use --with-auto to include it)."
fi

echo
echo "🎉 launch_all completed."
