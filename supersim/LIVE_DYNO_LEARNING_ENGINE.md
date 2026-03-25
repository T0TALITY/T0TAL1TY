# TOTALITY Live Dyno Learning Engine

## Purpose
Add a local learning loop to the TOTALITY Super Simulation stack.

## Capabilities
- ingest predicted outputs and actual dyno/log results
- compare prediction vs actual
- track confidence by engine family and variant
- generate workshop learning reports
- improve future preflight recommendations

## Included local package files
- `ingest_prediction_and_actual.py`
- `update_learning_ledger.py`
- `generate_workshop_report.py`
- `workshop_dashboard_spec.md`
- `variant_confidence_schema.json`

## Boundary
Supports workshop intelligence and iteration. Does not replace dyno validation or perform ECU flashing.
