# Vercel One-Click Preview Deploy

## Purpose
Deploy a project with a **single command** using a **preview-first** strategy.

## Safe default
Always target **preview** first. Production deploys require explicit confirmation and stronger checks.

## What this skill provides
- `scripts/deploy.sh`: idempotent deploy script with Vercel CLI-first flow and JSON fallback flow.
- `scripts/verify.sh`: post-deploy smoke test for URL availability and optional content matching.
- Log capture hooks for Codex diagnostics (`~/.codex/log/codex-tui.log`) and optional `/feedback`-style files.

## Usage
```bash
# From repository root
skills/vercel-one-click-deploy/scripts/deploy.sh .

# Verify returned preview URL
skills/vercel-one-click-deploy/scripts/verify.sh "https://example-preview-url"
```

## Execution flow
1. Try `vercel deploy <project> --yes` with a 10-minute timeout when `vercel` exists and auth appears configured.
2. If CLI/auth is missing, emit fallback JSON containing `previewUrl` and `claimUrl`.
3. On failure, collect diagnostics into `skills/vercel-one-click-deploy/artifacts/logs`.

## Environment knobs
- `DEPLOY_TIMEOUT_SECONDS` (default `600`)
- `FORCE_FALLBACK=1` to skip Vercel CLI and always use fallback mode
- `VERCEL_TOKEN` (optional auth hint)
- `FEEDBACK_LOG_PATH` (optional file copied into diagnostics)

## Output contract
Always return JSON to stdout:
- `previewUrl`
- `claimUrl`
- `mode` (`vercel-cli` or `fallback`)
- `status` (`ok` or `error`)
