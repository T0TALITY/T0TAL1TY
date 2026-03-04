#!/bin/bash
# One-click LaTeX cover deployment for TOTALITY project

set -euo pipefail

NO_OPEN="${NO_OPEN:-0}"
NO_GIT="${NO_GIT:-0}"

if ! command -v pdflatex >/dev/null 2>&1; then
    echo "❌ pdflatex is not installed or not in PATH."
    exit 1
fi

# 1. Compile the LaTeX cover to PDF
pdflatex -interaction=nonstopmode cover.tex

# 2. Move output PDF to a standard name
mv -f cover.pdf TOTALITY_Cover.pdf

# 3. Open PDF automatically (Linux/macOS)
if [ "$NO_OPEN" != "1" ]; then
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open TOTALITY_Cover.pdf >/dev/null 2>&1 || true
    elif command -v open >/dev/null 2>&1; then
        open TOTALITY_Cover.pdf >/dev/null 2>&1 || true
    fi
fi

echo "✅ TOTALITY cover deployed: TOTALITY_Cover.pdf"
