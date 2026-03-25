# TOTALITY Trial v0.1

Read-only OBD logging, dyno import, thermal modelling, and advisory reporting for real-world testing.

## What it does
- OBD baseline logging
- dyno CSV import
- thermal / torque advisory summaries
- universal simulation outputs for comparison

## What it does NOT do
- no ECU flashing
- no timing/fueling writes
- no remote tuning changes
- no vehicle-side calibration deployment

## Included in this repo
- `scripts/totality_hsv_lsa_suite.py`
- `scripts/totality_universal_thermal_combustion_module.py`
- `sample_data/sample_baseline.csv`
- `sample_data/sample_dyno_pull.csv`
- `docs/RELEASE_NOTE.md`
- `docs/TESTER_INSTRUCTIONS.md`
- `docs/FEEDBACK_FORM.md`

## Quick start
```bash
pip install obd flask
python scripts/totality_hsv_lsa_suite.py analyze --input ./sample_data/sample_baseline.csv --outdir ./reports
python scripts/totality_hsv_lsa_suite.py dyno-import --input ./sample_data/sample_dyno_pull.csv --outdir ./reports
python scripts/totality_universal_thermal_combustion_module.py simulate --json-out ./reports/simulation_results.json
```

## Live vehicle logging later
```bash
python scripts/totality_hsv_lsa_suite.py log --port auto --duration 120 --outdir ./logs
```

## Feedback requested
Please return:
- CSV logs
- JSON summaries
- vehicle make/model/year
- engine and transmission
- OBD adapter used
- operating system
- screenshots or error text
