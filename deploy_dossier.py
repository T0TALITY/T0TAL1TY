#!/usr/bin/env python3
"""One-click academic dossier generator.

Creates a prefilled Markdown dossier from:
1) a local PDF, or
2) a local text/markdown file, or
3) a URL (best-effort HTML extraction).

Usage:
  python deploy_dossier.py "Author Name" "https://facebook.com/posturl" "post_or_pdf.pdf"
"""

from __future__ import annotations

import argparse
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Iterable
from urllib.parse import urlparse
from urllib.request import Request, urlopen

OUTPUT_DIR = Path("Academic_Dossiers")


def extract_text_from_pdf(pdf_path: Path) -> str:
    """Extract text from a PDF using pdfplumber if installed."""
    try:
        import pdfplumber  # type: ignore
    except ImportError as exc:
        raise RuntimeError(
            "pdfplumber is required for PDF input. Install with: pip install pdfplumber"
        ) from exc

    text_parts: list[str] = []
    with pdfplumber.open(str(pdf_path)) as pdf:
        for page in pdf.pages:
            page_text = page.extract_text() or ""
            if page_text:
                text_parts.append(page_text)
    return "\n".join(text_parts)


def extract_text_from_html(html: str) -> str:
    """Convert HTML to plain text using BeautifulSoup if available."""
    try:
        from bs4 import BeautifulSoup  # type: ignore
    except ImportError:
        # Fallback to rough text extraction.
        text = re.sub(r"<script.*?</script>", " ", html, flags=re.DOTALL | re.IGNORECASE)
        text = re.sub(r"<style.*?</style>", " ", text, flags=re.DOTALL | re.IGNORECASE)
        return re.sub(r"<[^>]+>", " ", text)

    soup = BeautifulSoup(html, "html.parser")

    for tag in soup(["script", "style", "noscript"]):
        tag.decompose()

    return soup.get_text(" ", strip=True)


def extract_images_from_html(html: str) -> list[str]:
    """Extract image URLs from HTML using BeautifulSoup if available."""
    try:
        from bs4 import BeautifulSoup  # type: ignore
    except ImportError:
        return []

    soup = BeautifulSoup(html, "html.parser")
    images: list[str] = []
    for img in soup.find_all("img"):
        src = img.get("src")
        if src:
            images.append(src)
    return dedupe_keep_order(images)


def extract_links(text: str) -> list[str]:
    """Extract all HTTP(S) links from plain text."""
    return dedupe_keep_order(re.findall(r"https?://[^\s)\]>\"']+", text))


def dedupe_keep_order(items: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            out.append(item)
    return out


def clean_text(text: str) -> str:
    """Normalize whitespace for markdown embedding."""
    return re.sub(r"\s+", " ", text).strip()


def is_url(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme in {"http", "https"} and bool(parsed.netloc)


def fetch_url_text(url: str) -> tuple[str, list[str], list[str]]:
    """Fetch URL and return cleaned text, links, and image references."""
    req = Request(url, headers={"User-Agent": "Mozilla/5.0 (Codex Dossier Builder)"})
    with urlopen(req, timeout=20) as resp:  # nosec B310 - expected URL input
        raw = resp.read().decode("utf-8", errors="replace")

    text = extract_text_from_html(raw)
    links = extract_links(raw)
    images = extract_images_from_html(raw)
    return clean_text(text), links, images


def create_markdown(
    author_name: str,
    post_url: str,
    extracted_text: str,
    links: list[str],
    images: list[str],
    output_file: Path,
) -> None:
    """Create the markdown dossier file."""
    date_str = datetime.now().strftime("%Y-%m-%d")

    if links:
        links_rows = "\n".join(
            f"| External Link | [Link {i + 1}]({link}) | [ ] |" for i, link in enumerate(links)
        )
    else:
        links_rows = "| External Link | No external links found | [ ] |"

    if images:
        image_rows = "\n".join(
            f"| Image | Extracted media {i + 1} | {img} | [ ] |" for i, img in enumerate(images)
        )
    else:
        image_rows = "| Image | No images detected | N/A | [ ] |"

    md_content = f"""# 📄 Academic Dossier

**Author Name:** {author_name}
**ORCID:** [ORCID iD]
**ResearchGate:** [Profile URL]
**Google Scholar:** [Profile URL]
**Semantic Scholar:** [Profile URL]
**Institutional Affiliation:** [University / Research Center]

**Primary Discipline / Field:** [Field of Study]
**Secondary Fields:** [Optional Fields]
**Date Compiled:** {date_str}
**Compiled By:** Codex Automation

---

## 1. Source Metadata

- **Original Facebook Post URL:** {post_url}
- **Archived Snapshot:** [URL if archived]
- **Privacy Level:** [Public / Friends / Private]

---

## 2. Author Verification

- **Full Legal Name:** {author_name}
- **Aliases / Pen Names:** [Optional]
- **Linked Profiles:** [ORCID, ResearchGate, Google Scholar, Semantic Scholar]
- **Institutional Records:** [Verification Notes / Links]

---

## 3. Multimedia & External References

| Type | Description | Link / Reference | Verified (Y/N) |
|------|-------------|------------------|----------------|
{image_rows}
{links_rows}

---

## 4. Academic Doctrines / Statements

- **Extracted Text / Statements from Post / PDF:**
{extracted_text if extracted_text else '[No text extracted]'}

---

## 5. Degrees & Credentials

| Degree | Field | Institution | Year | Honors / Distinctions | Verified (Y/N) |
|--------|-------|------------|------|-----------------------|----------------|
| [BSc / BA / Other] | [Field] | [Institution Name] | [YYYY] | [ ] | [ ] |
| [MSc / MA / Other] | [Field] | [Institution Name] | [YYYY] | [ ] | [ ] |
| [PhD / DPhil / Other] | [Field] | [Institution Name] | [YYYY] | [ ] | [ ] |

---

## 6. Research Contributions

| Type | Title / Description | DOI / Link | Year | Verified (Y/N) |
|------|---------------------|------------|------|----------------|
| [Publication / Paper] | [Title] | [DOI / URL] | [YYYY] | [ ] |

---

## 7. Honors & Awards

| Award | Issuer | Year | Verified (Y/N) |
|-------|--------|------|----------------|
| [Award Name] | [Institution / Organization] | [YYYY] | [ ] |

---

## 8. Supporting Documentation

| Document Type | Description | File / Link | Verified (Y/N) |
|---------------|-------------|-------------|----------------|
| [Certificate / Transcript / Thesis / Award] | [Description] | [File / URL] | [ ] |

---

## 9. Verification Notes

- **Automated Tools Used:** Codex PDF/Text Extraction
- **Outstanding Items:** [List any items requiring further verification]

---

## 10. Legal, Ethical, and Privacy Considerations

- Public data or data with consent only
- Secure storage for personal files
- De-identify sensitive information before publishing

---

## ✅ Checklist Before Release

- [ ] All degrees verified
- [ ] All publications verified
- [ ] All awards verified
- [ ] All external links archived
- [ ] Ethical review completed
- [ ] Notarization / Apostille completed for official documents
"""

    output_file.write_text(md_content, encoding="utf-8")
    print(f"Dossier created at: {output_file}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate an academic dossier markdown file.")
    parser.add_argument("author_name", help="Author full name")
    parser.add_argument("facebook_post_url", help="Source post URL (for metadata)")
    parser.add_argument(
        "input_source",
        help="Path to PDF/text file, or an http(s) URL to scrape text from.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    author_name = args.author_name.strip()
    post_url = args.facebook_post_url.strip()
    input_source = args.input_source.strip()

    OUTPUT_DIR.mkdir(exist_ok=True)

    extracted_text = ""
    links: list[str] = []
    images: list[str] = []

    if is_url(input_source):
        try:
            extracted_text, links, images = fetch_url_text(input_source)
        except Exception as exc:
            print(f"Error fetching URL input '{input_source}': {exc}", file=sys.stderr)
            return 1
    else:
        input_path = Path(input_source)
        if not input_path.exists():
            print(f"Input file not found: {input_path}", file=sys.stderr)
            return 1

        if input_path.suffix.lower() == ".pdf":
            try:
                extracted_text = extract_text_from_pdf(input_path)
            except Exception as exc:
                print(f"Error reading PDF '{input_path}': {exc}", file=sys.stderr)
                return 1
        else:
            try:
                extracted_text = input_path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                extracted_text = input_path.read_text(encoding="latin-1")

        extracted_text = clean_text(extracted_text)
        links = extract_links(extracted_text)

    safe_name = re.sub(r"[^A-Za-z0-9_-]+", "_", author_name).strip("_") or "Unknown_Author"
    output_file = OUTPUT_DIR / f"{safe_name}_Dossier.md"

    create_markdown(author_name, post_url, extracted_text, links, images, output_file)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
