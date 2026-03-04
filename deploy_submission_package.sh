#!/usr/bin/env bash
# Scaffold and refresh the TOTALITY submission package directories/files.

set -euo pipefail

ROOT="Thesis_Submission"

mkdir -p \
  "$ROOT/Manuscripts" \
  "$ROOT/Combined_Thesis" \
  "$ROOT/Appendices/Data_Logs" \
  "$ROOT/References" \
  "$ROOT/Submission_Ready/Individual_Ready" \
  "$ROOT/Submission_Ready/Combined_Ready"

# Keep empty directories tracked.
for keep in \
  "$ROOT/Manuscripts/.gitkeep" \
  "$ROOT/Combined_Thesis/.gitkeep" \
  "$ROOT/Appendices/.gitkeep" \
  "$ROOT/Appendices/Data_Logs/.gitkeep" \
  "$ROOT/Submission_Ready/Individual_Ready/.gitkeep" \
  "$ROOT/Submission_Ready/Combined_Ready/.gitkeep"
  do
  [ -f "$keep" ] || : > "$keep"
done

# Seed bibliography placeholder if absent.
if [ ! -f "$ROOT/References/bibliography.bib" ]; then
  cat > "$ROOT/References/bibliography.bib" <<'BIB'
% Consolidated bibliography for TOTALITY submission package
@misc{totality_placeholder,
  title  = {TOTALITY Reference Placeholder},
  author = {TOTALITY Team},
  year   = {2026},
  note   = {Replace with publication-ready references}
}
BIB
fi

# Mirror existing repository bibliography into submission package for convenience.
if [ -f references.bib ]; then
  cp -f references.bib "$ROOT/References/bibliography.bib"
fi

# Copy known generated thesis artifact when present.
if [ -f TOTALITY_Nexus_Full.pdf ]; then
  cp -f TOTALITY_Nexus_Full.pdf "$ROOT/Combined_Thesis/CAM_3iAtlas_Full_Thesis.pdf"
fi

echo "✅ Submission package scaffolded at $ROOT"
