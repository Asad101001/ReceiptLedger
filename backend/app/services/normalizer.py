"""
ReceiptLedger – NLP Normalization & Fuzzy Domain Correction
=============================================================
Converts raw OCR output lines into structured, canonical LineItemCreate objects.

Pipeline per text-line:
  1. Regex extraction: quantity, unit, price tokens
  2. Remainder text → raw item name
  3. Levenshtein fuzzy match against local_taxonomy.json (threshold ≥ 0.80)
  4. Canonical mapping: canonical_name, category, standard_unit
  5. Confidence tagging: items below threshold → review queue flag

Regex patterns are specified in docs/09_DEVELOPMENT_PLAN.md § 3.4.

References:
  docs/09_DEVELOPMENT_PLAN.md § 3.4
  docs/03_SDS.md § 2.3
"""

from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from Levenshtein import ratio as levenshtein_ratio

from app.core.config import settings
from app.core.models import LineItemCreate, OCRToken

logger = logging.getLogger(__name__)

# ── Taxonomy loading ─────────────────────────────────────────────────────────

_TAXONOMY_PATH = Path(__file__).resolve().parents[3] / "data" / "local_taxonomy.json"

@dataclass
class TaxonomyEntry:
    canonical_name: str
    category: str
    standard_unit: str
    aliases: List[str] = field(default_factory=list)


def _load_taxonomy() -> List[TaxonomyEntry]:
    """Load and validate the local taxonomy dictionary from data/local_taxonomy.json."""
    if not _TAXONOMY_PATH.exists():
        logger.warning("Taxonomy file not found at %s; fuzzy matching disabled.", _TAXONOMY_PATH)
        return []
    with _TAXONOMY_PATH.open(encoding="utf-8") as f:
        raw: List[Dict[str, Any]] = json.load(f)
    entries = []
    for item in raw:
        entries.append(
            TaxonomyEntry(
                canonical_name=item["canonical_name"],
                category=item["category"],
                standard_unit=item["standard_unit"],
                aliases=[a.lower() for a in item.get("aliases", [])],
            )
        )
    logger.debug("Loaded %d taxonomy entries.", len(entries))
    return entries


# Module-level singleton
_TAXONOMY: List[TaxonomyEntry] = _load_taxonomy()


# ── Regex Patterns (from dev plan § 3.4) ────────────────────────────────────

# Quantity + optional unit (e.g. "5kg", "2.5 ltr", "500g")
_QTY_UNIT_RE = re.compile(
    r"(?P<qty>\d+(?:\.\d+)?)\s*"
    r"(?P<unit>kg|g|gm|gram|ltr|liter|litre|ml|pkt|packet|pcs|pc|dzn|dozen)?",
    re.IGNORECASE,
)

# Price / amount (e.g. "Rs.1450", "PKR 200", "1,450.00", "450")
_PRICE_RE = re.compile(
    r"(?:Rs\.?|PKR\s*)?"
    r"(?P<price>\d{1,6}(?:,\d{3})*(?:\.\d{1,2})?)",
    re.IGNORECASE,
)

# Strip common receipt header noise
_NOISE_RE = re.compile(
    r"(total|sub[\s-]?total|amount|vat|gst|tax|discount|balance|change|cash|bill|invoice)",
    re.IGNORECASE,
)


# ── Public Interface ──────────────────────────────────────────────────────────

def parse_lines_to_items(
    text_lines: List[List[OCRToken]],
    base_confidence: float = 0.90,
) -> List[LineItemCreate]:
    """
    Convert a list of text lines (each being a list of OCRToken) into
    a list of structured LineItemCreate objects.

    Args:
        text_lines: Output of ocr_router.reassemble_lines().
        base_confidence: Nominal confidence for this OCR result
                         (mean token confidence from the engine).

    Returns:
        List of LineItemCreate ready for deduplication and storage.
    """
    items: List[LineItemCreate] = []

    for line_tokens in text_lines:
        line_text = " ".join(t.text for t in line_tokens).strip()
        if not line_text or _is_noise_line(line_text):
            continue

        # Compute per-line confidence as mean token confidence
        line_conf = (
            sum(t.confidence for t in line_tokens) / len(line_tokens)
            if line_tokens else base_confidence
        )

        item = _parse_single_line(line_text, line_conf)
        if item:
            items.append(item)

    logger.debug("Parsed %d line items from %d text lines.", len(items), len(text_lines))
    return items


def fuzzy_match(raw_text: str) -> Optional[TaxonomyEntry]:
    """
    Find the best matching taxonomy entry for a raw item name string.

    Uses normalised Levenshtein ratio:
        Score = 1 - levenshtein_distance(s1, s2) / max(len(s1), len(s2))

    Returns the best entry if score ≥ settings.fuzzy_match_threshold, else None.
    """
    if not _TAXONOMY:
        return None

    query = raw_text.lower().strip()
    best_score = 0.0
    best_entry: Optional[TaxonomyEntry] = None

    for entry in _TAXONOMY:
        for alias in entry.aliases:
            score = levenshtein_ratio(query, alias)
            if score > best_score:
                best_score = score
                best_entry = entry

    if best_score >= settings.fuzzy_match_threshold:
        logger.debug(
            "Fuzzy match: '%s' → '%s' (score=%.2f)",
            raw_text, best_entry.canonical_name, best_score,
        )
        return best_entry

    logger.debug("No fuzzy match for '%s' (best score=%.2f).", raw_text, best_score)
    return None


# ── Private Helpers ───────────────────────────────────────────────────────────

def _parse_single_line(line_text: str, confidence: float) -> Optional[LineItemCreate]:
    """
    Extract structured fields from a single receipt line string.

    Strategy:
      - Find ALL price-like numbers; the last one is treated as total_price,
        the second-to-last (if present) as unit_price.
      - Find quantity + unit token near the start of the line.
      - Whatever remains after stripping numeric tokens is the raw item name.
    """
    # Find all price candidates
    prices = _extract_prices(line_text)
    if not prices:
        return None  # Lines without any numeric value are unlikely to be items

    total_price = prices[-1]
    unit_price = prices[-2] if len(prices) >= 2 else total_price

    # Extract quantity + unit
    qty, unit = _extract_qty_unit(line_text)

    # Extract raw item name: remove numeric tokens from the line
    raw_name = _extract_item_name(line_text)
    if not raw_name:
        return None

    # Fuzzy match against taxonomy
    match = fuzzy_match(raw_name)
    if match:
        canonical_name = match.canonical_name
        category = match.category
        if unit == "pcs":  # If unit was not parsed, use the standard unit from taxonomy
            unit = match.standard_unit
    else:
        canonical_name = raw_name.title()
        category = "Miscellaneous"

    return LineItemCreate(
        raw_text=line_text,
        item_name=canonical_name,
        quantity=qty,
        unit=unit,
        unit_price=round(unit_price, 2),
        total_price=round(total_price, 2),
        confidence_score=round(confidence, 3),
        category=category,
        is_verified=False,
    )


def _extract_prices(text: str) -> List[float]:
    """Extract all price-like float values from a text string."""
    results = []
    for match in _PRICE_RE.finditer(text):
        raw = match.group("price").replace(",", "")
        try:
            results.append(float(raw))
        except ValueError:
            continue
    return results


def _extract_qty_unit(text: str) -> Tuple[float, str]:
    """
    Extract the first (quantity, unit) pair found in the text.
    Returns (1.0, 'pcs') as default if nothing is found.
    """
    m = _QTY_UNIT_RE.search(text)
    if m:
        qty_str = m.group("qty")
        unit_str = (m.group("unit") or "pcs").lower()
        # Normalise unit aliases
        unit_str = _normalise_unit(unit_str)
        try:
            return float(qty_str), unit_str
        except ValueError:
            pass
    return 1.0, "pcs"


def _extract_item_name(text: str) -> str:
    """
    Strip price and quantity tokens from the line to isolate the item description.
    """
    # Remove price patterns
    cleaned = _PRICE_RE.sub("", text)
    # Remove quantity+unit patterns
    cleaned = _QTY_UNIT_RE.sub("", cleaned)
    # Remove leading currency symbols and separators
    cleaned = re.sub(r"[Rs\.PKR×xX@\-–]", " ", cleaned)
    # Remove stray digits
    cleaned = re.sub(r"\b\d+\b", "", cleaned)
    # Collapse whitespace
    cleaned = " ".join(cleaned.split()).strip(".,- ")
    return cleaned if len(cleaned) >= 2 else ""


def _is_noise_line(text: str) -> bool:
    """Return True for header/footer lines that should be skipped."""
    stripped = text.strip().lower()
    # Skip very short lines
    if len(stripped) < 3:
        return True
    # Skip common receipt noise keywords
    if _NOISE_RE.search(stripped):
        return True
    # Skip lines that are only punctuation / separators
    if re.match(r"^[-=*_.]+$", stripped):
        return True
    return False


def _normalise_unit(unit: str) -> str:
    """Map unit aliases to canonical unit abbreviations."""
    mapping = {
        "gram": "g", "gm": "g",
        "liter": "ltr", "litre": "ltr",
        "packet": "pkt",
        "dozen": "dzn",
        "pc": "pcs",
    }
    return mapping.get(unit.lower(), unit.lower())
