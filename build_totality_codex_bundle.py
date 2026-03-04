#!/usr/bin/env python3
"""Build the TOTALITY Codex v1 portable bundle.

This script assembles a distributable folder and ZIP containing:
- Codex_Academic_Release_v1_TOTALITY.pdf
- TOTALITY_Codex_v1_Executive_Dashboard.pdf (fallback copy if no dedicated source exists)
- codex_index.html
- codex_manifest.json
- codex_manifest.xml
- optional light assets (SVG schematics)
"""

from __future__ import annotations

import json
import shutil
import zipfile
from dataclasses import asdict, dataclass
from datetime import date
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, tostring

ROOT = Path(__file__).resolve().parent
DIST_DIR = ROOT / "dist"
BUNDLE_NAME = "TOTALITY_Codex_v1"
BUNDLE_DIR = DIST_DIR / BUNDLE_NAME
ASSETS_DIR = BUNDLE_DIR / "assets"

SOURCE_FULL_CODEX_PDF = ROOT / "TOTALITY_FULL_BUILD.pdf"
TARGET_FULL_CODEX_PDF = BUNDLE_DIR / "Codex_Academic_Release_v1_TOTALITY.pdf"
TARGET_EXEC_PDF = BUNDLE_DIR / "TOTALITY_Codex_v1_Executive_Dashboard.pdf"


@dataclass
class ManifestMeta:
    version: str
    deployment_date: str
    lineage: str
    total_elements: int


def codex_elements() -> list[dict[str, str]]:
    """Return canonical element listing for audit/reference."""
    labels = [
        "Chapter 01 - Overview",
        "Chapter 02 - Doctrine",
        "Chapter 03 - Harmonic Resonance",
        "Chapter 04 - Algorithmic Sequencing",
        "Chapter 05 - Matter Whip Technology",
        "Chapter 06 - Mechanical Engines",
        "Chapter 07 - Electric Motor Systems",
        "Chapter 08 - Molten 5D Batteries",
        "Chapter 09 - Infinity Batteries",
        "Chapter 10 - Systems Integration",
        "Chapter 11 - LLM/AI Hooks",
        "Chapter 12 - Automation",
        "Chapter 13 - Telemetry",
        "Chapter 14 - Simulations",
        "Chapter 15 - Proofs",
        "Chapter 16 - Deployment Pipeline",
        "Chapter 17 - Security Model",
        "Chapter 18 - Compliance",
        "Chapter 19 - Validation",
        "Chapter 20 - Operations",
        "Appendix A - Mathematical Proofs",
        "Appendix B - Simulation Outputs",
        "Appendix C - Telemetry Snapshots",
        "Appendix D - CAD Excerpts",
        "Appendix E - Schematics",
        "Appendix F - Source Maps",
        "Appendix G - Cross-Reference Index",
        "Appendix H - Glossary",
        "Engine Diagram - Mechanical",
        "Engine Diagram - Electric",
        "Battery Diagram - Molten 5D",
        "Battery Diagram - Infinity",
        "Workflow Diagram - Knowledge Pipeline",
        "Executive Dashboard",
        "Master Deployment Map",
        "Manifest JSON",
        "Manifest XML",
    ]
    return [
        {
            "id": f"E{i:03d}",
            "name": name,
            "status": "included",
            "verification": "ready",
        }
        for i, name in enumerate(labels, start=1)
    ]


def write_assets() -> None:
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    engine_svg = """<svg xmlns='http://www.w3.org/2000/svg' width='900' height='220'>
<rect width='900' height='220' fill='#0b1020'/>
<text x='30' y='40' fill='#9be7ff' font-size='24' font-family='Arial'>TOTALITY Engine Systems (Light Asset)</text>
<rect x='40' y='70' width='220' height='100' fill='#1f2a44' stroke='#64ffda'/>
<rect x='330' y='70' width='220' height='100' fill='#1f2a44' stroke='#64ffda'/>
<rect x='620' y='70' width='220' height='100' fill='#1f2a44' stroke='#64ffda'/>
<text x='70' y='125' fill='white' font-size='16'>Mechanical Engines</text>
<text x='365' y='125' fill='white' font-size='16'>Electric Motors</text>
<text x='700' y='125' fill='white' font-size='16'>Battery Systems</text>
<line x1='260' y1='120' x2='330' y2='120' stroke='#64ffda' stroke-width='3'/>
<line x1='550' y1='120' x2='620' y2='120' stroke='#64ffda' stroke-width='3'/>
</svg>
"""

    pipeline_svg = """<svg xmlns='http://www.w3.org/2000/svg' width='900' height='240'>
<rect width='900' height='240' fill='#101522'/>
<text x='30' y='36' fill='#ffd180' font-size='24' font-family='Arial'>TOTALITY Knowledge Pipeline (Light Asset)</text>
<rect x='40' y='70' width='170' height='80' fill='#263238' stroke='#ffd180'/>
<rect x='250' y='70' width='170' height='80' fill='#263238' stroke='#ffd180'/>
<rect x='460' y='70' width='170' height='80' fill='#263238' stroke='#ffd180'/>
<rect x='670' y='70' width='170' height='80' fill='#263238' stroke='#ffd180'/>
<text x='74' y='115' fill='white' font-size='14'>Research Input</text>
<text x='296' y='115' fill='white' font-size='14'>Simulation</text>
<text x='493' y='115' fill='white' font-size='14'>Verification</text>
<text x='706' y='115' fill='white' font-size='14'>Release Output</text>
<line x1='210' y1='110' x2='250' y2='110' stroke='#ffd180' stroke-width='3'/>
<line x1='420' y1='110' x2='460' y2='110' stroke='#ffd180' stroke-width='3'/>
<line x1='630' y1='110' x2='670' y2='110' stroke='#ffd180' stroke-width='3'/>
</svg>
"""

    (ASSETS_DIR / "engine_systems_light.svg").write_text(engine_svg, encoding="utf-8")
    (ASSETS_DIR / "knowledge_pipeline_light.svg").write_text(pipeline_svg, encoding="utf-8")


def write_manifest(elements: list[dict[str, str]]) -> None:
    meta = ManifestMeta(
        version="1.0",
        deployment_date="2026-03-04",
        lineage="TOTALITY -> Flamecourt -> WØLX INDUSTRIES",
        total_elements=len(elements),
    )

    manifest_json = {
        "meta": asdict(meta),
        "generated_on": str(date.today()),
        "bundle": BUNDLE_NAME,
        "files": [
            "Codex_Academic_Release_v1_TOTALITY.pdf",
            "TOTALITY_Codex_v1_Executive_Dashboard.pdf",
            "codex_index.html",
            "codex_manifest.json",
            "codex_manifest.xml",
            "assets/engine_systems_light.svg",
            "assets/knowledge_pipeline_light.svg",
        ],
        "elements": elements,
    }
    (BUNDLE_DIR / "codex_manifest.json").write_text(
        json.dumps(manifest_json, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    root = Element("codex_manifest")
    meta_el = SubElement(root, "meta")
    for key, value in asdict(meta).items():
        child = SubElement(meta_el, key)
        child.text = str(value)

    generated_on = SubElement(root, "generated_on")
    generated_on.text = str(date.today())

    files_el = SubElement(root, "files")
    for file_name in manifest_json["files"]:
        f = SubElement(files_el, "file")
        f.text = file_name

    elements_el = SubElement(root, "elements")
    for item in elements:
        e = SubElement(elements_el, "element", id=item["id"])
        SubElement(e, "name").text = item["name"]
        SubElement(e, "status").text = item["status"]
        SubElement(e, "verification").text = item["verification"]

    xml_bytes = tostring(root, encoding="utf-8", xml_declaration=True)
    (BUNDLE_DIR / "codex_manifest.xml").write_bytes(xml_bytes)


def write_html_index() -> None:
    html = f"""<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
  <title>TOTALITY Codex v1 — Index</title>
  <style>
    body {{ font-family: Arial, sans-serif; margin: 2rem; color: #0f172a; }}
    .box {{ border: 1px solid #cbd5e1; padding: 1rem; border-radius: 10px; margin-bottom: 1rem; }}
    code {{ background: #f1f5f9; padding: 0.2rem 0.4rem; border-radius: 4px; }}
  </style>
</head>
<body>
  <h1>TOTALITY Codex v1 — Executive Index</h1>
  <p>Portable bundle for posting, archival, and stakeholder distribution.</p>

  <div class=\"box\">
    <h2>Core PDFs</h2>
    <ul>
      <li><a href=\"Codex_Academic_Release_v1_TOTALITY.pdf\">Codex_Academic_Release_v1_TOTALITY.pdf</a></li>
      <li><a href=\"TOTALITY_Codex_v1_Executive_Dashboard.pdf\">TOTALITY_Codex_v1_Executive_Dashboard.pdf</a></li>
    </ul>
  </div>

  <div class=\"box\">
    <h2>Reference + Metadata</h2>
    <ul>
      <li><a href=\"codex_manifest.json\">codex_manifest.json</a></li>
      <li><a href=\"codex_manifest.xml\">codex_manifest.xml</a></li>
      <li><a href=\"assets/engine_systems_light.svg\">Engine schematic (SVG)</a></li>
      <li><a href=\"assets/knowledge_pipeline_light.svg\">Knowledge pipeline (SVG)</a></li>
    </ul>
  </div>

  <div class=\"box\">
    <h2>Bundle Metadata</h2>
    <p><strong>Version:</strong> 1.0</p>
    <p><strong>Deployment Date:</strong> 2026-03-04</p>
    <p><strong>Lineage:</strong> TOTALITY → Flamecourt → WØLX INDUSTRIES</p>
    <p><strong>Element Count:</strong> 37</p>
  </div>

  <p>Generated by <code>build_totality_codex_bundle.py</code>.</p>
</body>
</html>
"""
    (BUNDLE_DIR / "codex_index.html").write_text(html, encoding="utf-8")


def write_notes() -> None:
    notes = """# TOTALITY Codex v1 Bundle Notes

This bundle is assembled from repository artifacts.

- `Codex_Academic_Release_v1_TOTALITY.pdf` is sourced from `TOTALITY_FULL_BUILD.pdf`.
- `TOTALITY_Codex_v1_Executive_Dashboard.pdf` currently mirrors the same source PDF as a fallback
  when a dedicated dashboard PDF is not separately provided.
- `codex_manifest.json` and `codex_manifest.xml` include 37 tracked codex elements for audit.
"""
    (BUNDLE_DIR / "BUNDLE_NOTES.md").write_text(notes, encoding="utf-8")


def build_zip() -> Path:
    zip_path = DIST_DIR / "TOTALITY_Codex_v1_bundle.zip"
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(BUNDLE_DIR.rglob("*")):
            if path.is_file():
                zf.write(path, arcname=path.relative_to(BUNDLE_DIR.parent))
    return zip_path


def main() -> int:
    if not SOURCE_FULL_CODEX_PDF.exists():
        raise FileNotFoundError(f"Missing source PDF: {SOURCE_FULL_CODEX_PDF}")

    if BUNDLE_DIR.exists():
        shutil.rmtree(BUNDLE_DIR)
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    BUNDLE_DIR.mkdir(parents=True, exist_ok=True)

    shutil.copy2(SOURCE_FULL_CODEX_PDF, TARGET_FULL_CODEX_PDF)
    shutil.copy2(SOURCE_FULL_CODEX_PDF, TARGET_EXEC_PDF)

    elements = codex_elements()
    write_assets()
    write_manifest(elements)
    write_html_index()
    write_notes()
    zip_path = build_zip()

    print(f"Bundle directory: {BUNDLE_DIR}")
    print(f"ZIP package: {zip_path}")
    print(f"Element count: {len(elements)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
