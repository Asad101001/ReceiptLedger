import sys, os, re
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from pathlib import Path
from app.services.preprocessor import preprocess_image
from app.services.tesseract_client import extract_tokens
from app.services.ocr_router import reassemble_lines
from app.services.normalizer import _TAXONOMY, TaxonomyEntry, _load_taxonomy

# Let's test the new folding and parsing logic
print(f"Loaded {len(_TAXONOMY)} taxonomy items")

from Levenshtein import ratio as levenshtein_ratio
from rapidfuzz import fuzz
from app.core.config import settings
from app.core.models import LineItemCreate

_DIMENSION_RE = re.compile(
    r"\b\d+(?:\.\d+)?\s*(?:[xX*]\s*\d+(?:\.\d+)?\s*)?(?:cm|mm|m[#*]?|inch|in|ft|w|v|hz|fps|mah|sqft)\b",
    re.IGNORECASE,
)
_PRICE_RE = re.compile(
    r"(?:Rs\.?|PKR\s*)?"
    r"(?P<price>\d{1,6}(?:,\d{3})*(?:\.\d{1,2})?)",
    re.IGNORECASE,
)
_QTY_WITH_UNIT_RE = re.compile(
    r"\b(?P<qty>\d+(?:\.\d+)?)\s*(?P<unit>kg|k9|ke|kq|k|g|gm|gram|ltr|liter|litre|l|ml|pkt|packet|pcs|pc|dzn|dozen|dz)\b",
    re.IGNORECASE,
)
_LEADING_INDEX_RE = re.compile(r"^\s*(?:[A-Za-z0-9\(\[<>\-~*+.,_]+\s+)?\d+[\.,\)\-:]\s*")

_OCR_TYPO_MAP = {
    "witha": "sweet melon",
    "withaperkg": "sweet melon",
    "spnch": "spinach",
    "spnchperkg": "spinach",
    "disposibe": "disposable",
    "gass": "glass",
    "mi": "mineral",
    "rot": "roti",
    "alu": "aloo",
    "piaz": "pyaz",
    "tmatar": "tamatar",
    "timatar": "tamatar",
    "lehsan": "lehsan",
    "lahsun": "lehsan",
    "lasun": "lehsan",
    "adrak": "adrak",
    "andas": "andey",
    "anda": "andey",
    "anday": "andey",
    "mikpak": "milkpak",
    "milpak": "milkpak",
    "milkpack": "milkpak",
    "putter": "butter",
    "yoourt": "yogurt",
    "dahl": "dahi",
    "deal": "daal",
    "chavoal": "chawal",
    "cheer": "cheeni",
    "chini": "cheeni",
    "hee": "ghee",
    "aata": "atta",
    "ata": "atta",
    "juic": "juice",
    "ketchp": "ketchup",
    "mayo": "mayonnaise",
    "safguard": "safeguard",
    "colgat": "colgate",
}

# Pre-indexed lookup maps
_EXACT_MAP = {}
_NORM_MAP = {}
for entry in _TAXONOMY:
    candidates = entry.aliases + [entry.canonical_name.lower()]
    clean_canon = re.sub(r"\(.*?\)", "", entry.canonical_name).strip().lower()
    if clean_canon:
        candidates.append(clean_canon)
    for alias in candidates:
        a_clean = alias.strip().lower()
        if a_clean:
            _EXACT_MAP[a_clean] = entry
            norm = re.sub(r"[^a-z0-9]", "", a_clean)
            if norm:
                _NORM_MAP[norm] = entry

def clean_retail_text(text: str) -> str:
    s = text
    s = re.sub(r"^\s*(?:\d{4,16}\s+)+", "", s)
    s = re.sub(
        r"\bPER\s+(?:KG|K9|KE|KQ|LTR|L|DZ|DZN|PC|PCS|GM|G|PKT)\b(?:\s+\d+(?:\.\d+)?\s*[a-zA-Z]?)?",
        "",
        s,
        flags=re.IGNORECASE,
    )
    s = re.sub(r"\s+[a-zA-Z]$", "", s)
    s = _DIMENSION_RE.sub(" ", s)
    s = re.sub(r"\b(?:Rs\.?|PKR|RM|CHF|EUR|USD|\$|SR|GST|VAT|TX)\b", " ", s, flags=re.IGNORECASE)
    s = re.sub(r"[×xX@\-–/|*#:~^\\=\(\)\[\]\{\}“”\"_]+", " ", s)
    return " ".join(s.split()).strip(".,- ")

def upgraded_fuzzy_match(raw_text: str):
    query = raw_text.lower().strip()
    if len(query) < 2:
        return None

    # Try exact lookup first
    if query in _EXACT_MAP:
        return _EXACT_MAP[query]
    norm_q = re.sub(r"[^a-z0-9]", "", query)
    if norm_q in _NORM_MAP:
        return _NORM_MAP[norm_q]

    # Clean retail artifacts
    cleaned = clean_retail_text(query)
    if cleaned in _EXACT_MAP:
        return _EXACT_MAP[cleaned]
    norm_c = re.sub(r"[^a-z0-9]", "", cleaned)
    if norm_c in _NORM_MAP:
        return _NORM_MAP[norm_c]

    # Apply typo corrections
    words = (cleaned or query).split()
    corrected_words = [_OCR_TYPO_MAP.get(w.strip(".,-"), w) for w in words]
    corrected_query = " ".join(corrected_words)

    if corrected_query in _EXACT_MAP:
        return _EXACT_MAP[corrected_query]
    norm_corr = re.sub(r"[^a-z0-9]", "", corrected_query)
    if norm_corr in _NORM_MAP:
        return _NORM_MAP[norm_corr]

    # RapidFuzz scoring
    best_score = 0.0
    best_entry = None
    q_words = corrected_query.split()

    for entry in _TAXONOMY:
        candidates = entry.aliases + [entry.canonical_name.lower()]
        for alias in candidates:
            alias_lower = alias.lower()
            a_words = alias_lower.split()

            std_ratio = fuzz.ratio(corrected_query, alias_lower)
            token_set = fuzz.token_set_ratio(corrected_query, alias_lower)
            token_sort = fuzz.token_sort_ratio(corrected_query, alias_lower)

            if len(a_words) == 1:
                if len(q_words) == 1:
                    score = std_ratio / 100.0
                elif len(q_words) == 2 and a_words[0] in q_words:
                    score = 0.88
                else:
                    score = (token_sort * 0.70 + std_ratio * 0.30) / 100.0
            else:
                score = (token_set * 0.70 + token_sort * 0.30) / 100.0

            if score > best_score:
                best_score = score
                best_entry = entry

    if best_score >= 0.80:
        return best_entry
    return None

print("Testing fuzzy queries:")
test_queries = [
    "129728 129728 WITHA PER KG 0. 640 a",
    "101866 SPINACH PER KG 0.700 700. a",
    "A Disposibe Gass peepee 20",
    "> Mi Water iP 80",
    "foi s s SCiSSCdO Rot 6 150",
    "Nihari Nfeibabe_ 560_ 2P Double 500 2P 4,120 20",
    "panadol extra",
    "arinac forte",
    "surf excel",
    "lemon max bar",
]
for tq in test_queries:
    m = upgraded_fuzzy_match(tq)
    print(f"  '{tq}' -> {m.canonical_name if m else 'None'} ({m.category if m else ''})")
