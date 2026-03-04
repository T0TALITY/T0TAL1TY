#!/usr/bin/env python3
"""Layered publisher for Codex study-mode artifacts.

Writes each department's text+bundle artifacts into:
1) flat output            .codex/output/<department>/{text,bundle}
2) timestamped release    .codex/releases/<timestamp>/<department>/{text,bundle}
3) versioned release      .codex/releases/v<semver>/<department>/{text,bundle}

Hybrid versioning mode is default: system proposes a version, operator approves/overrides.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any


@dataclass
class PublishConfig:
    versioning_mode: str
    current_version: str
    departments: list[str]
    external_briefings_file: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Publish artifacts to layered storage")
    parser.add_argument("--config", default=".codex/publish_config.json")
    parser.add_argument("--report", default=".codex/orchestrator_report.json")
    parser.add_argument("--proposal", choices=["major", "minor", "patch"], default="minor")
    parser.add_argument("--approve-version", default="", help="Approved version (e.g., v1.1.0)")
    parser.add_argument("--allow-unapproved", action="store_true", help="Bypass approval gate")
    return parser.parse_args()


def load_config(path: Path) -> PublishConfig:
    raw: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    return PublishConfig(
        versioning_mode=raw.get("versioning_mode", "hybrid"),
        current_version=raw.get("current_version", "v1.0.0"),
        departments=raw.get("departments", []),
        external_briefings_file=raw.get("external_briefings_file", ".codex/external_briefings.json"),
    )


def load_external_briefings(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    raw: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    return raw.get("briefings", [])


def bump(version: str, proposal: str) -> str:
    clean = version.lstrip("v")
    major, minor, patch = [int(x) for x in clean.split(".")]
    if proposal == "major":
        major += 1
        minor = 0
        patch = 0
    elif proposal == "minor":
        minor += 1
        patch = 0
    else:
        patch += 1
    return f"v{major}.{minor}.{patch}"


def write_artifacts(base: Path, department: str, payload: dict[str, Any]) -> int:
    text_dir = base / department / "text"
    bundle_dir = base / department / "bundle"
    text_dir.mkdir(parents=True, exist_ok=True)
    bundle_dir.mkdir(parents=True, exist_ok=True)

    summary = text_dir / f"{department}_summary.md"
    bundle = bundle_dir / f"{department}_bundle.json"

    summary.write_text(
        "\n".join(
            [
                f"# {department.title()} Publish Summary",
                "",
                f"- status: {payload['status']}",
                f"- source_report: {payload['source_report']}",
                f"- timestamp: {payload['timestamp']}",
                f"- version: {payload['version']}",
                f"- external_briefings: {payload['external_briefings_count']}",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    bundle.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return 2


def main() -> None:
    args = parse_args()
    config = load_config(Path(args.config))
    report_path = Path(args.report)

    if not config.departments:
        raise ValueError("No departments defined in publish config.")
    if not report_path.exists():
        raise FileNotFoundError(f"Orchestrator report not found: {report_path}")

    report = json.loads(report_path.read_text(encoding="utf-8"))
    if not report.get("all_completed", False):
        raise RuntimeError("Verification failed: not all agents completed.")

    proposed = bump(config.current_version, args.proposal)
    approved = args.approve_version or proposed

    if config.versioning_mode == "hybrid" and not args.allow_unapproved and not args.approve_version:
        raise RuntimeError(
            "Hybrid mode requires operator approval. Re-run with --approve-version <vX.Y.Z> "
            "or pass --allow-unapproved for study-mode dry approval."
        )

    external_briefings = load_external_briefings(Path(config.external_briefings_file))

    now = datetime.utcnow()
    ts = now.strftime("%Y-%m-%d_%H-%M-%S")

    flat_base = Path(".codex/output")
    ts_base = Path(".codex/releases") / ts
    ver_base = Path(".codex/releases") / approved

    written = 0
    for department in config.departments:
        payload = {
            "department": department,
            "status": "published",
            "source_report": str(report_path),
            "timestamp": ts,
            "version": approved,
            "proposed_version": proposed,
            "agent_count": report.get("agent_count", 0),
            "completed_count": report.get("completed_count", 0),
            "external_briefings_count": len(external_briefings),
            "external_briefings": external_briefings,
        }
        written += write_artifacts(flat_base, department, payload)
        written += write_artifacts(ts_base, department, payload)
        written += write_artifacts(ver_base, department, payload)

    result = {
        "versioning_mode": config.versioning_mode,
        "proposed_version": proposed,
        "approved_version": approved,
        "timestamp_release": str(ts_base),
        "version_release": str(ver_base),
        "flat_output": str(flat_base),
        "departments": len(config.departments),
        "artifacts_written": written,
        "external_briefings_file": config.external_briefings_file,
        "external_briefings_count": len(external_briefings),
    }
    out = Path(".codex/publish_report.json")
    out.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
