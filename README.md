# T0TAL1TY

MMORPG deployment and release assets.

## Super Release Documentation

- Master Deployment Map: `TOTAL1TY_SUPER_RELEASE_MASTER_DEPLOYMENT_MAP.md`

## Academic Dossier Automation

- One-click script: `deploy_dossier.py`
- Generates an academic dossier markdown file from a PDF, text file, or URL input.

Example:

```bash
python deploy_dossier.py "Author Name" "https://facebook.com/posturl" "post_or_pdf.pdf"
```

## TOTALITY Codex Bundle Builder

- Bundle script: `build_totality_codex_bundle.py`
- Produces a portable distribution bundle with:
  - `Codex_Academic_Release_v1_TOTALITY.pdf`
  - `TOTALITY_Codex_v1_Executive_Dashboard.pdf`
  - `codex_index.html`
  - `codex_manifest.json`
  - `codex_manifest.xml`
  - light SVG assets

Build command:

```bash
python build_totality_codex_bundle.py
```

Output:

- Directory: `dist/TOTALITY_Codex_v1/`
- ZIP: `dist/TOTALITY_Codex_v1_bundle.zip`
