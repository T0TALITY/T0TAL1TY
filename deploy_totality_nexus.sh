#!/bin/bash
# TOTALITY NEXUS: Full One-Click Thesis + Cover Deployment

set -euo pipefail

NO_OPEN="${NO_OPEN:-0}"
NO_GIT="${NO_GIT:-0}"

echo "🔹 Starting TOTALITY Nexus full deployment..."

if ! command -v pdflatex >/dev/null 2>&1; then
    echo "❌ pdflatex is not installed or not in PATH."
    exit 1
fi

# 1) Compile master LaTeX document twice for TOC references
pdflatex -interaction=nonstopmode TOTALITY_Master.tex >/dev/null
pdflatex -interaction=nonstopmode TOTALITY_Master.tex >/dev/null

# 2) Rename final PDF
mv -f TOTALITY_Master.pdf TOTALITY_Nexus_Full.pdf

# 3) Git integration
if [ "$NO_GIT" = "1" ]; then
    echo "ℹ️ NO_GIT=1 set; skipping git commit/push."
else
    git add TOTALITY_Master.tex TOTALITY_Nexus_Full.pdf
    if ! git diff --cached --quiet; then
        git commit -m "TOTALITY Nexus full deployment $(date '+%Y-%m-%d %H:%M:%S')"
        CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
        if git remote get-url origin >/dev/null 2>&1; then
            git push origin "$CURRENT_BRANCH"
        else
            echo "⚠️ No 'origin' remote configured. Skipping push."
        fi
    else
        echo "ℹ️ No changes to commit for nexus artifacts."
    fi
fi

# 4) Open PDF automatically
if [ "$NO_OPEN" != "1" ]; then
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open TOTALITY_Nexus_Full.pdf >/dev/null 2>&1 || true
    elif command -v open >/dev/null 2>&1; then
        open TOTALITY_Nexus_Full.pdf >/dev/null 2>&1 || true
    fi
fi

echo "✅ TOTALITY Nexus fully deployed and Git integration complete."
