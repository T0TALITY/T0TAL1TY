# T0TAL1TY
Mmorpg

## TOTALITY LaTeX One-Click Pipelines

- `deploy_cover.sh`: minimal helper that builds `cover.tex` into `TOTALITY_Cover.pdf`.
- `deploy_totality_cover.sh`: cover pipeline with build + optional git integration.
- `deploy_totality_nexus.sh`: full thesis pipeline using `TOTALITY_Master.tex` + optional git integration.
- `deploy_totality_auto.sh`: auto-sync pipeline (pull, build with bibliography, optional commit/push).
- `launch_all.sh`: orchestration entrypoint that runs all major pipelines in sequence.

### Recommended structure

```text
.
├── TOTALITY_Master.tex
├── cover.tex
├── chapters/
│   ├── introduction.tex
│   ├── methodology.tex
│   ├── results.tex
│   ├── discussion.tex
│   └── conclusion.tex
├── figures/
├── datasets/
├── references.bib
└── logo.png
```

### Quick start

```bash
# Launch core build flow (cover + nexus)
bash launch_all.sh --skip-open --no-git

# Include the auto-sync + bibliography pass
bash launch_all.sh --with-auto --skip-open --no-git
```

### Useful flags/environment controls

- `launch_all.sh --with-auto`: include `deploy_totality_auto.sh`.
- `launch_all.sh --skip-open`: prevent automatic opening of generated PDFs.
- `launch_all.sh --no-git`: prevent commit/push actions in child scripts.
- `NO_OPEN=1`: can be used directly with any deploy script to disable PDF auto-open.
- `NO_GIT=1`: can be used directly with git-enabled deploy scripts to skip commit/push.

> Requirements: `pdflatex`, `bibtex` (for auto pipeline), git repo initialized, and `logo.png` in the repo root.

## TOTALITY Submission Package (Finalized Layout)

A finalized submission-ready scaffold now lives in `Thesis_Submission/` for:

- separate manuscript submission flow, and
- combined thesis submission flow.

Initialize/refresh it with:

```bash
bash deploy_submission_package.sh
```


## Codex Webhook Production Workflow

A production webhook receiver scaffold is available in `codex-webhook-handler/` with:

- Express-based webhook endpoint (`/codex-webhook`),
- optional HMAC signature verification,
- deduplication handling,
- Docker and PM2 deployment files.

Quick start:

```bash
cd codex-webhook-handler
cp .env.example .env
npm install
npm start
```
