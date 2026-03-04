# T0TAL1TY
Mmorpg

## Documentation
- [Agent internet access](AGENT_INTERNET_ACCESS.md)

## Codex IDE setup (TOTAL1TY SUPER RELEASE)
- Codex IDE configuration template: [`.codex/config.toml`](.codex/config.toml)
- One-command deployment workflow script: [`deploy_total1ty.sh`](deploy_total1ty.sh)

### Quick start
```bash
# Optional: install into your Codex home
mkdir -p ~/.codex
cp .codex/config.toml ~/.codex/config.toml

# Run full deploy + simulation + compile + monitor workflow
./deploy_total1ty.sh /TOTAL1TY_SUPER_RELEASE
```

## Academic tally one-click deploy
- Source tally dataset: [`data/academic_tally.json`](data/academic_tally.json)
- Deployment utility: [`tools/deploy_academic_tally.py`](tools/deploy_academic_tally.py)
- One-click wrapper script: [`deploy_academic_tally.sh`](deploy_academic_tally.sh)

```bash
# Generate deployable JSON + markdown report
./deploy_academic_tally.sh

# Outputs:
# - artifacts/academic/academic_tally.deployed.json
# - artifacts/academic/academic_tally_report.md
```

## One-click preview deploy skill package
- Skill instructions: [`skills/vercel-one-click-deploy/SKILL.md`](skills/vercel-one-click-deploy/SKILL.md)
- Deploy script: [`skills/vercel-one-click-deploy/scripts/deploy.sh`](skills/vercel-one-click-deploy/scripts/deploy.sh)
- Verify script: [`skills/vercel-one-click-deploy/scripts/verify.sh`](skills/vercel-one-click-deploy/scripts/verify.sh)
- Root wrapper command: [`one_click_preview_deploy.sh`](one_click_preview_deploy.sh)

```bash
# Safe default: preview deploy
./one_click_preview_deploy.sh .

# Force fallback JSON mode (for CI/sandbox or no auth)
FORCE_FALLBACK=1 ./one_click_preview_deploy.sh .
```


## Neuron TOTALITY upgrade
- Command-center config: [`.codex/neuron_totality.toml`](.codex/neuron_totality.toml)
- Config preflight check: [`neuron_totality_preflight.sh`](neuron_totality_preflight.sh)
- One-click orchestrator: [`one_click_neuron_totality.sh`](one_click_neuron_totality.sh)

```bash
# Validate Neuron TOTALITY command-center configuration
./neuron_totality_preflight.sh

# Run full one-click flow (preflight + academic deploy + TOTAL1TY deploy if codex exists + preview deploy)
./one_click_neuron_totality.sh /TOTAL1TY_SUPER_RELEASE
```


## Study Mode: multi-agent orchestrator scaffold
- Agent registry (editable roles + skills): [`.codex/agent_registry.json`](.codex/agent_registry.json)
- Parallel orchestrator scaffold: [`codex_launch.py`](codex_launch.py)

```bash
# Launch 5 default agents in parallel (Planner, Coder, Reviewer, Tester, Documenter)
python3 codex_launch.py --doctrine .codex/agent_registry.json --report .codex/orchestrator_report.json

# Inspect orchestration verification summary
cat .codex/orchestrator_report.json
```


## Layered publish storage (flat + timestamped + versioned)
- Publish config (9 departments, hybrid versioning): [`.codex/publish_config.json`](.codex/publish_config.json)
- External briefing registry: [`.codex/external_briefings.json`](.codex/external_briefings.json)
- Briefing registration tool: [`tools/register_external_briefing.py`](tools/register_external_briefing.py)
- Publisher: [`codex_publish.py`](codex_publish.py)
- One-click publish runner: [`one_click_publish.sh`](one_click_publish.sh)

```bash
# Step 1: run orchestrator to generate verified report
python3 codex_launch.py --doctrine .codex/agent_registry.json --report .codex/orchestrator_report.json

# Step 2: publish with operator-approved version (hybrid mode)
python3 codex_publish.py --config .codex/publish_config.json --report .codex/orchestrator_report.json --proposal minor --approve-version v1.1.0

# One-click (runs both steps)
./one_click_publish.sh v1.1.0

# Register a URL even if fetch is blocked in this environment
python3 tools/register_external_briefing.py "https://example.com/post" --fetch-status unavailable_in_environment --notes "proxy blocked"
```
