import sys, os, re
sys.path.insert(0, os.path.abspath('backend'))
sys.stdout.reconfigure(encoding='utf-8')

from pathlib import Path
from typing import List, Optional, Tuple, Dict, Any
from dataclasses import dataclass, field
from rapidfuzz import fuzz

from app.services.preprocessor import preprocess_image
from app.services.tesseract_client import extract_tokens
from app.services.ocr_router import reassemble_lines
from app.core.models import OCRToken, LineItemCreate

# Load taxonomy
_TAX_PATH = Path('data/local_taxonomy.json')
import json
with open(_TAX_PATH, encoding='utf-8') as f:
    _TAX_RAW = json.load(f)

@dataclass
class TaxEntry:
    canonical_name: str
    category: str
    standard_unit: str
    aliases: List[str]

TAXONOMY: List[TaxEntry] = [
    TaxEntry(
        canonical_name=x["canonical_name"],
        category=x["category"],
        standard_unit=x["standard_unit"],
        aliases=[a.lower() for a in x.get("aliases", [])],
    )
    for x in _TAX_RAW
]

_EXACT_MAP: Dict[str, TaxEntry] = {}
_NORM_MAP: Dict[str, TaxEntry] = {}
for entry in TAXONOMY:
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

_STOP_SECTION_RE = re.compile(
    r"\b("
    r"sub[\s-]?total|grand[\s-]?total|net[\s-]?total|net[\s-]?amount|total\s*sales|"
    r"round(?:ed|ing)?[\s-]?total|total\s*rounded|amount[\s-]?payable|payable[\s-]?amount|"
    r"bill[\s-]?total|total[\s-]?amount|total\s*items?|items?\s*total|total\s*qty|totalgty|totall?ttem|totall?y|"
    r"all\s*pri\s*ce\s*are\s*inclusive|item\s*count|"
    r"item\(s\)\s*\d+|qty\(s\)\s*:\s*\d+|"
    r"total[\s=:]+(?:rm|pkr|rs\.?|\$)?\s*\d|"
    r"cash\s*(?:rm|pkr|rs\.?|\$|paid|tendered|pald|back|[:=])|change\s*(?:rm|pkr|rs\.?|\$|[:=])|"
    r"sales\s*tax|sst|gst\s*inclusive|"
    r"ٹوٹل|کل"
    r")\b",
    re.IGNORECASE,
)

_NOISE_RE = re.compile(
    r"\b("
    r"total|grand[\s-]?total|net[\s-]?total|sub[\s-]?total|gross[\s-]?total|amount|vat|gst|gstin|pan|tax|discount|balance|change|cash|"
    r"bill|bill\s*to|ship\s*to|sold\s*to|customer|place\s*of\s*supply|terms|conditions|warranty|signature|signatory|authorised|"
    r"invoice|receipt|sntn|ntn|nin|strn|pos|terminal|date|pate|time|tne|items|rate|description|price|qty|"
    r"total\s*items|items\s*total|total\s*qty|item\s*count|"
    r"thank\s*you|branch|tel|phone|mob|mobile|cell|whatsapp|helpline|call|contact|"
    r"raast|transfer|transferred|stan|rrn|iban|account|acct|bank|easypaisa|jazzcash|nayapay|sadapay|wallet|"
    r"pechs|shahrah|karachi|clifton|khi|lahore|islamabad|rawalpindi|jaipur|rajasthan|"
    r"jalan|jln|taman|lorong|floor|lot\s*\d+|avenue|damansara|shah\s*alam|johor\s*bahru|grindelwald|entspricht|mwst|"
    r"selangor|kembangan|klang|bandar|seksyen|bukit|raja|setia\s*alam|utama|kathmandu|narephat|batangkali|subtotat|tender|"
    r"service\s*charge|service\s*tax|saving|rounding|co(?:mpany)?\s*reg|reg\s*ma|table\s*:\s*|able\s*:\s*bar|speed\s*mart|"
    r"cashier|server|table|pax|guest\s*check|order\s*taker|open\s*:\s*\d+|doc\s*no|document\s*no|inv\s*:\s*|invoice\s*no|co\s*reg|gst\s*reg|reg\s*no|tax\s*invoice|cash\s*bill|tel/fax|fax|"
    r"super\s*market|general\s*store|karyana\s*store|karyana|bismillah|imtiaz|al[\s-]?madina|supermarket|subhan|chaudhry|fazal|naheed"
    r")\b",
    re.IGNORECASE,
)
_PHONE_RE = re.compile(r"\b(?:03\d{2}[-\s]?\d{7}|0\d{2,3}[-\s]?\d{6,8}|\+?92[-\s]?\d{3}[-\s]?\d{7}|uan\b|uan\s*[:;]?\s*\+?\d+)\b", re.IGNORECASE)
_ACCOUNT_RE = re.compile(r"\b(?:stan|rrn|iban|acct|acc)\s*[:#]?\s*\d+\b", re.IGNORECASE)
_DATE_RE = re.compile(r"\b(?:\d{1,2}[-/](?:[a-zA-Z]{3}|\d{1,2})[-/]\d{2,4}|\d{4}[-/]\d{1,2}[-/]\d{1,2})\b", re.IGNORECASE)

def _normalise_unit(unit: str) -> str:
    mapping = {
        "gram": "g", "gm": "g",
        "liter": "ltr", "litre": "ltr", "l": "ltr",
        "packet": "pkt",
        "dozen": "dzn", "dz": "dzn",
        "pc": "pcs",
        "k9": "kg", "ke": "kg", "kq": "kg", "k": "kg",
    }
    return mapping.get(unit.lower(), unit.lower())

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

def fuzzy_match(raw_text: str) -> Optional[TaxEntry]:
    query = raw_text.lower().strip()
    if len(query) < 2:
        return None

    # Exact alias check
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

    # Typo corrections
    words = (cleaned or query).split()
    corrected_words = [_OCR_TYPO_MAP.get(w.strip(".,-"), w) for w in words]
    corrected_query = " ".join(corrected_words)

    if corrected_query in _EXACT_MAP:
        return _EXACT_MAP[corrected_query]
    norm_corr = re.sub(r"[^a-z0-9]", "", corrected_query)
    if norm_corr in _NORM_MAP:
        return _NORM_MAP[norm_corr]

    # Check individual distinctive staple words if query has multiple noise tokens
    for w in corrected_words:
        if len(w) >= 3 and w in _EXACT_MAP:
            # Match only if word is a recognized staple/brand
            return _EXACT_MAP[w]

    # RapidFuzz multi-metric scoring
    best_score = 0.0
    best_entry = None
    q_words = corrected_query.split()

    for entry in TAXONOMY:
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

def is_price_continuation(text: str) -> bool:
    stripped = text.strip()
    if not stripped:
        return False
    if _STOP_SECTION_RE.search(stripped):
        return False
    decimals = re.findall(r"\b\d+[.,]\d{2}\b", stripped)
    letters = re.findall(r"[A-Za-z]", stripped)
    return len(decimals) >= 1 and len(letters) <= 5

def fold_continuation_lines(text_lines: List[List[OCRToken]]) -> List[List[OCRToken]]:
    merged: List[List[OCRToken]] = []
    i = 0
    n = len(text_lines)

    while i < n:
        lt = " ".join(t.text for t in text_lines[i]).strip()
        if _STOP_SECTION_RE.search(lt):
            merged.append(text_lines[i])
            i += 1
            continue

        if is_noise_line(lt):
            merged.append(text_lines[i])
            i += 1
            continue

        folded = False
        if i + 1 < n:
            next_lt = " ".join(t.text for t in text_lines[i + 1]).strip()
            if not _STOP_SECTION_RE.search(next_lt):
                if is_price_continuation(next_lt) or re.search(
                    r"\b(?:\d{6,16}\s+)?(?:\d+\s*[xX*@]\s*)?(?:RM|Rs\.?|\$)?\s*\d+[.,]\d{2}\b",
                    next_lt,
                ):
                    combined_tokens = text_lines[i] + text_lines[i + 1]
                    merged.append(combined_tokens)
                    i += 2
                    folded = True
        if not folded:
            merged.append(text_lines[i])
            i += 1
    return merged

def extract_prices(text: str) -> List[float]:
    clean_text = _DIMENSION_RE.sub(" ", text)
    results = []
    for match in _PRICE_RE.finditer(clean_text):
        raw = match.group("price").replace(",", "")
        try:
            val = float(raw)
            if 0 < val <= 50000.0:
                results.append(val)
        except ValueError:
            continue
    if len(results) >= 2:
        decimal_or_realistic = [p for p in results if (not p.is_integer() or p >= 20.0)]
        if decimal_or_realistic:
            return decimal_or_realistic
    return results

def is_noise_line(text: str) -> bool:
    stripped = text.strip().lower()
    if len(stripped) < 3:
        return True
    if _PHONE_RE.search(stripped):
        return True
    if _ACCOUNT_RE.search(stripped):
        return True
    if re.search(r"^\s*\d{4,5}(?:\s+\d{2,4})?\s+[A-Za-z\s,.-]+$", stripped):
        return True
    if _NOISE_RE.search(stripped):
        if not re.search(r"\b(atta|rice|oil|milk|tea|sugar|bread|eggs|butter|dahi|ghee|soap|chawal|daal|doodh|cheeni|panadol|disprin|sancos|surf|aloo|pyaz|tamatar|adrak|lehsan|ketchup|masala|mask|tuc|water|glass|roti|nihari)\b", stripped):
            return True
    if _DATE_RE.search(stripped) and not re.search(r"\b(atta|rice|oil|milk|tea|sugar|bread|eggs|butter|dahi|ghee|soap|chawal|daal|doodh|cheeni|panadol|disprin|sancos|surf|aloo|pyaz|tamatar|adrak|lehsan|ketchup|masala|mask|tuc|water|glass|roti|nihari)\b", stripped):
        return True
    if re.match(r"^[-=*_.~^|#]+$", stripped):
        return True
    return False

def parse_single_line(line_text: str, confidence: float) -> Optional[LineItemCreate]:
    cleaned_line = re.sub(r"[\u2018\u2019\u201c\u201d'\"`]", "", line_text)
    cleaned_line = re.sub(r"^[?><~+*.,_\-|\s]+", "", cleaned_line).strip()
    cleaned_line = re.sub(r"^\s*(?:\d{4,16}\s+)+", "", cleaned_line)
    cleaned_line = re.sub(r"\b\d{7,16}\b", " ", cleaned_line)
    cleaned_line = re.sub(r"^\s*\d{3,6}\s+([A-Za-z])", r"\1", cleaned_line)
    cleaned_line = re.sub(r"(\d+),(\d{2})\b", r"\1.\2", cleaned_line)
    cleaned_line = re.sub(r"\b(\d+)\s*\.\s*(\d+)\b", r"\1.\2", cleaned_line)
    cleaned_line = re.sub(r"\b(100|200|250|400|430|450|500|800|900|1000)[6bB9]\b", r"\1g", cleaned_line)
    cleaned_line = re.sub(r"_+", " ", cleaned_line)
    cleaned_line = re.sub(r"\b[lI|1][oO0]\s*(kg|k9|ke|kq|ka)\b", r"10kg", cleaned_line, flags=re.IGNORECASE)
    cleaned_line = re.sub(r"\b[aAzZ]\s*(kg|k9|ke|kq)\b", r"2kg", cleaned_line, flags=re.IGNORECASE)
    cleaned_line = re.sub(r"\b[tT1]ke\b|\b[tT]kg\b", r"1kg", cleaned_line, flags=re.IGNORECASE)
    cleaned_line = re.sub(r"\b(1|i|l|t)\s*(de|dz|dze|dzn|da)\b", r"1dz", cleaned_line, flags=re.IGNORECASE)
    cleaned_line = re.sub(r"(?:[“\"'\b]|^)[tT1]4[oO0]{2}\b", r" 1400", cleaned_line)
    cleaned_line = re.sub(r"\b(\d+(?:\.\d+)?\s*(?:kg|k9|ke|kq|ka|g|gm|ltr|l|ml|pkt|dzn|dz))\s+\1\b", r"\1", cleaned_line, flags=re.IGNORECASE)
    line_body = _LEADING_INDEX_RE.sub("", cleaned_line).strip()

    m_embed = re.search(r"(?:total|tole|totl|ٹوٹل|کل)[\s=:_]+(?P<total>\d{2,6})\b|[=:]\s*(?P<total2>\d{2,6})\s*[=:]?$", line_body, re.IGNORECASE)
    if m_embed:
        item_prefix = line_body[:m_embed.start()].strip()
        item_prefix = re.sub(r"^(?:total|tole|totl|ٹوٹل|کل)[\s=:_]+", "", item_prefix, flags=re.IGNORECASE).strip()
        if len(re.sub(r"[^a-zA-Z]", "", item_prefix)) >= 3:
            line_body = item_prefix
        else:
            return None

    if _DATE_RE.search(line_body) and not re.search(r"\b(atta|rice|oil|milk|tea|sugar|bread|eggs|butter|dahi|ghee|soap|chawal|daal|doodh|cheeni|panadol|disprin|sancos|surf|aloo|pyaz|tamatar|adrak|lehsan|ketchup|masala|mask|tuc|water|glass|roti|nihari)\b", line_body, re.IGNORECASE):
        return None

    # Check produce: PER KG 0.640
    qty = 1.0
    unit = "pcs"
    m_per = re.search(
        r"\bPER\s+(?P<unit>KG|K9|KE|KQ|LTR|L|DZ|DZN|PC|PCS|GM|G|PKT)\s+(?P<qty>\d+(?:\.\d+)?)\b",
        line_body,
        re.IGNORECASE,
    )
    if m_per:
        qty = float(m_per.group("qty"))
        unit = _normalise_unit(m_per.group("unit"))
    else:
        m_unit = _QTY_WITH_UNIT_RE.search(line_body)
        if m_unit:
            qty = float(m_unit.group("qty"))
            unit = _normalise_unit(m_unit.group("unit"))
        else:
            m_mult = re.search(r"\b(?P<qty>\d+)\s*[xX*@]\b|\b[xX*@]\s*(?P<qty2>\d+)\b", line_body)
            if m_mult:
                qty_val = float(m_mult.group("qty") or m_mult.group("qty2"))
                if 0 < qty_val <= 100:
                    qty = qty_val

    # Prices
    line_for_prices = _QTY_WITH_UNIT_RE.sub(" ", line_body)
    prices = extract_prices(line_for_prices)
    if not prices:
        all_candidate_prices = extract_prices(line_body)
        prices = [p for p in all_candidate_prices if abs(p - qty) > 0.001 or p >= 20.0]

    # Extract clean raw item name
    clean_body = clean_retail_text(line_body)
    raw_name = clean_body
    raw_name = _PRICE_RE.sub("", raw_name)
    raw_name = _QTY_WITH_UNIT_RE.sub("", raw_name)
    raw_name = re.sub(r"\b\d+\b", "", raw_name)
    raw_name = " ".join(raw_name.split()).strip(".,- ")

    if not raw_name or len(re.sub(r"[^a-zA-Z]", "", raw_name)) < 2:
        return None

    match = fuzzy_match(raw_name)

    if not prices:
        if not match or not _QTY_WITH_UNIT_RE.search(line_body):
            return None
        if unit == "pcs":
            unit = match.standard_unit
        return LineItemCreate(
            raw_text=line_text,
            item_name=match.canonical_name,
            quantity=qty,
            unit=unit,
            unit_price=0.0,
            total_price=0.0,
            confidence_score=round(max(confidence, 0.85), 3),
            category=match.category,
            is_verified=False,
        )

    has_decimals = any("." in w and any(c.isdigit() for c in w) for w in line_body.split())
    if len(prices) >= 3 and has_decimals:
        # Multi-column table (Metro / Carrefour / Imtiaz)
        total_price = prices[-1]
        unit_price = prices[0]
    elif has_decimals or len(prices) == 1:
        total_price = prices[-1]
        unit_price = prices[-2] if len(prices) >= 2 else total_price
    else:
        # Integer prices on slip, e.g. 'Rot 6 150':
        if len(prices) == 2 and prices[0].is_integer() and 1 <= prices[0] <= 50 and prices[1] > prices[0]:
            qty = prices[0]
            total_price = prices[1]
            unit_price = round(total_price / qty, 2)
        else:
            total_price = prices[0]
            unit_price = total_price

    if total_price > 50000.0 or total_price <= 0.0:
        return None
    if unit_price > 50000.0:
        unit_price = total_price

    if match:
        canonical_name = match.canonical_name
        category = match.category
        if unit == "pcs":
            unit = match.standard_unit
        item_conf = max(confidence, 0.85)
    else:
        if confidence < 0.45 or total_price <= 5.0 or len(re.sub(r"[^a-zA-Z]", "", raw_name)) < 3:
            return None
        canonical_name = raw_name.title()
        category = "Miscellaneous"
        item_conf = min(confidence, 0.60)

    return LineItemCreate(
        raw_text=line_text,
        item_name=canonical_name,
        quantity=qty,
        unit=unit,
        unit_price=round(unit_price, 2),
        total_price=round(total_price, 2),
        confidence_score=round(item_conf, 3),
        category=category,
        is_verified=False,
    )

def parse_lines_to_items(text_lines: List[List[OCRToken]], base_confidence: float = 0.90) -> List[LineItemCreate]:
    items: List[LineItemCreate] = []
    processed = fold_continuation_lines(text_lines)

    for line_tokens in processed:
        line_text = " ".join(t.text for t in line_tokens).strip()
        if not line_text or is_noise_line(line_text):
            continue

        if _STOP_SECTION_RE.search(line_text):
            break

        line_conf = sum(t.confidence for t in line_tokens) / len(line_tokens) if line_tokens else base_confidence
        item = parse_single_line(line_text, line_conf)
        if item:
            items.append(item)
    return items

# Test on Metro & Javed
for name in ['metro_safari_park_sample.png', 'javed_nahari_sample.png']:
    p = Path('data/sample_receipts') / name
    if p.exists():
        img_bytes = p.read_bytes()
        p_img, _ = preprocess_image(img_bytes)
        lines = reassemble_lines(extract_tokens(p_img))
        items = parse_lines_to_items(lines, 0.9)
        print(f"\n=== {name} ({len(items)} items) ===")
        total_sum = sum(it.total_price for it in items)
        for it in items:
            print(f"  {it.item_name:<35} qty={it.quantity:<6} {it.unit:<5} unit_price={it.unit_price:<8} total={it.total_price:<8} conf={it.confidence_score} cat={it.category}")
        print(f"  --> TOTAL EXTRACTED SUM: {total_sum}")
