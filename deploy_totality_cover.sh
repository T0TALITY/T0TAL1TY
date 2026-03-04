#!/bin/bash
# TOTALITY One-Click Cover Deployment

set -euo pipefail

NO_OPEN="${NO_OPEN:-0}"
NO_GIT="${NO_GIT:-0}"

echo "🔹 Starting TOTALITY cover deployment..."

if ! command -v pdflatex >/dev/null 2>&1; then
    echo "❌ pdflatex is not installed or not in PATH."
    exit 1
fi

# 1) Compile LaTeX
pdflatex -interaction=nonstopmode cover.tex >/dev/null

# 2) Rename output PDF
mv -f cover.pdf TOTALITY_Cover.pdf

# 3) Git integration (commit only when there are staged changes)
if [ "$NO_GIT" = "1" ]; then
    echo "ℹ️ NO_GIT=1 set; skipping git commit/push."
else
    git add cover.tex TOTALITY_Cover.pdf
    if ! git diff --cached --quiet; then
        git commit -m "TOTALITY Cover updated $(date '+%Y-%m-%d %H:%M:%S')"
        CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
        if git remote get-url origin >/dev/null 2>&1; then
            git push origin "$CURRENT_BRANCH"
        else
            echo "⚠️ No 'origin' remote configured. Skipping push."
        fi
    else
        echo "ℹ️ No changes to commit for cover artifacts."
    fi
fi

# 4) Open PDF automatically
if [ "$NO_OPEN" != "1" ]; then
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open TOTALITY_Cover.pdf >/dev/null 2>&1 || true
    elif command -v open >/dev/null 2>&1; then
        open TOTALITY_Cover.pdf >/dev/null 2>&1 || true
    fi
fi

echo "✅ TOTALITY cover deployed, compiled, and Git integration complete."
