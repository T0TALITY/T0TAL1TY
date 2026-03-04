# T0TAL1TY

TOTALITY Pro Lab utilities for agent orchestration experiments.

## PRO LAB Dashboard

This repository includes a Dash-powered lab dashboard with:

- **Agent Activity Timeline** (latest lines from `autonomy.log`)
- **Interactive Task Board** (queue/start/stop/complete task lifecycle in `tasks.json`)
- **Academic Auto Push** (copy docs/papers into `academic_repo`, then commit/push if git is configured)

## Install dependencies

```bash
pip install dash dash-bootstrap-components
```

## Start web UI

```bash
./nexus-pro-lab-start.sh
```

Then open `http://localhost:8120`.

The starter now validates boot success and prints the recent log output if startup fails.

## CLI operations (no web UI required)

```bash
python3 nexus-pro-lab.py task list
python3 nexus-pro-lab.py task queue "Review new paper" --owner research-agent
python3 nexus-pro-lab.py task set 0 running
python3 nexus-pro-lab.py push-academics
```

## Optional configuration

Set `TOTALITY_BASE` to point at a different project directory:

```bash
TOTALITY_BASE=~/TOTALITY ./nexus-pro-lab-start.sh
```
