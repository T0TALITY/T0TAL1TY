#!/bin/bash
# TOTALITY NEXUS: Fully Automated One-Click Deployment

set -euo pipefail

NO_OPEN="${NO_OPEN:-0}"
NO_GIT="${NO_GIT:-0}"

echo "🔹 Starting TOTALITY Nexus auto-sync deployment..."

if ! command -v pdflatex >/dev/null 2>&1; then
    echo "❌ pdflatex is not installed or not in PATH."
    exit 1
fi

if ! command -v bibtex >/dev/null 2>&1; then
    echo "❌ bibtex is not installed or not in PATH."
    exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# 1) Pull latest content when origin is configured
if git remote get-url origin >/dev/null 2>&1; then
    git pull --rebase origin "$CURRENT_BRANCH"
else
    echo "⚠️ No 'origin' remote configured. Skipping pull."
fi

# 2) Ensure scaffold directories exist
mkdir -p chapters figures datasets

# 3) Compile LaTeX with bibliography and TOC resolution
pdflatex -interaction=nonstopmode TOTALITY_Master.tex >/dev/null
bibtex TOTALITY_Master >/dev/null
pdflatex -interaction=nonstopmode TOTALITY_Master.tex >/dev/null
pdflatex -interaction=nonstopmode TOTALITY_Master.tex >/dev/null

# 4) Rename output PDF
mv -f TOTALITY_Master.pdf TOTALITY_Nexus_Full_Auto.pdf

# 5) Commit and optionally push updates
FILES_TO_ADD=(
  TOTALITY_Master.tex
  references.bib
  TOTALITY_Nexus_Full_Auto.pdf
  chapters
  figures
  datasets
)

for path in "${FILES_TO_ADD[@]}"; do
    if [ -e "$path" ]; then
        git add "$path"
    fi
done

if [ "$NO_GIT" = "1" ]; then
    echo "ℹ️ NO_GIT=1 set; skipping git commit/push."
else
    if ! git diff --cached --quiet; then
        git commit -m "AUTO: TOTALITY Nexus update $(date '+%Y-%m-%d %H:%M:%S')"
        if git remote get-url origin >/dev/null 2>&1; then
            git push origin "$CURRENT_BRANCH"
        else
            echo "⚠️ No 'origin' remote configured. Skipping push."
        fi
    else
        echo "ℹ️ No changes detected after build; nothing to commit."
    fi
fi

# 6) Open PDF automatically
if [ "$NO_OPEN" != "1" ]; then
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open TOTALITY_Nexus_Full_Auto.pdf >/dev/null 2>&1 || true
    elif command -v open >/dev/null 2>&1; then
        open TOTALITY_Nexus_Full_Auto.pdf >/dev/null 2>&1 || true
    fi
fi

echo "✅ TOTALITY Nexus fully synced, compiled, and Git integration complete."
