#!/usr/bin/env python3
"""Register external briefing links for publish metadata.

This utility stores links even when remote fetch is blocked in the environment.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Register an external briefing URL")
    parser.add_argument("url", help="External reference URL")
    parser.add_argument("--source", default="user-provided")
    parser.add_argument("--fetch-status", default="not_checked")
    parser.add_argument("--notes", default="")
    parser.add_argument("--file", default=".codex/external_briefings.json")
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {"briefings": []}


def main() -> None:
    args = parse_args()
    path = Path(args.file)
    path.parent.mkdir(parents=True, exist_ok=True)

    payload = load_json(path)
    entries = payload.setdefault("briefings", [])
    entries.append(
        {
            "url": args.url,
            "source": args.source,
            "fetch_status": args.fetch_status,
            "notes": args.notes,
            "captured_at": datetime.now(timezone.utc).isoformat(),
        }
    )

    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"Registered briefing: {args.url}")
    print(f"File: {path}")


if __name__ == "__main__":
    main()
