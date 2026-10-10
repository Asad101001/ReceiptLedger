"""
ReceiptLedger – Deduplication Engine
======================================
Two-layer duplicate detection as specified in docs/09_DEVELOPMENT_PLAN.md § 3.5:

  Layer 1 — Visual (perceptual image hashing):
    • Compute 64-bit DCT pHash from the preprocessed image using `imagehash`.
    • Compare via Hamming distance against all stored hashes.
    • Threshold: Hamming ≤ 4 → suspected visual duplicate.

  Layer 2 — Textual (cryptographic fingerprint):
    • Compose fingerprint from: merchant_slug + ISO date + total_amount_cents.
    • SHA-256 hash of the composite string.
    • Exact match in the stored set → definite text duplicate.

Storage is backed by Supabase when configured; otherwise falls back to a
module-level in-memory store (suitable for development / CLI testing).

References:
  docs/09_DEVELOPMENT_PLAN.md § 3.5
  docs/03_SDS.md § 2.4
"""

from __future__ import annotations

import hashlib
import logging
import re
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

import imagehash
import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)


# ── Domain Types ──────────────────────────────────────────────────────────────

@dataclass
class HashRecord:
    receipt_id: str
    phash_64: str       # 16-char hex string from imagehash (= 64-bit DCT hash)
    text_sha256: str    # SHA-256 hex of the textual fingerprint


# ── In-Memory Store (dev / test fallback) ────────────────────────────────────

# Maps receipt_id → HashRecord
_hash_store: Dict[str, HashRecord] = {}


# ── Public Interface ──────────────────────────────────────────────────────────

def compute_phash(image: np.ndarray) -> str:
    """
    Compute the 64-bit DCT perceptual hash of the given image.

    Args:
        image: 2-D grayscale numpy array (preprocessed receipt image).

    Returns:
        16-character lowercase hexadecimal string representing the 64-bit pHash.
    """
    try:
        import cv2
        if len(image.shape) == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        else:
            gray = image
        resized = cv2.resize(gray, (32, 32), interpolation=cv2.INTER_AREA)
        dct = cv2.dct(np.float32(resized))
        low_freq = dct[:8, :8]
        med = float(np.median(low_freq.flatten()[1:]))
        diff = low_freq > med
        hash_int = 0
        for b in diff.flatten():
            hash_int = (hash_int << 1) | int(b)
        return f"{hash_int:016x}"
    except Exception as exc:
        logger.warning("cv2 DCT pHash failed (%s), trying imagehash fallback", exc)
        try:
            pil_image = Image.fromarray(image)
            return str(imagehash.phash(pil_image))
        except Exception:
            return "0" * 16


def compute_text_fingerprint(
    merchant_name: Optional[str],
    receipt_date: Optional[str],
    total_amount: float,
) -> str:
    """
    Compute a SHA-256 text fingerprint from the receipt's key metadata.

    Normalisation:
        merchant_slug = lowercase alphanumeric only (no spaces/punctuation)
        date_iso      = YYYY-MM-DD (fall back to "unknown" if missing)
        total_cents   = round(amount * 100) as integer string

    Returns:
        64-character lowercase SHA-256 hex string.
    """
    merchant_slug = re.sub(r"[^a-z0-9]", "", (merchant_name or "").lower())
    date_iso = receipt_date or "unknown"
    total_cents = str(round(total_amount * 100))

    composite = f"{merchant_slug}|{date_iso}|{total_cents}"
    return hashlib.sha256(composite.encode("utf-8")).hexdigest()


def hamming_distance(hash1: str, hash2: str) -> int:
    """
    Compute the Hamming distance between two hexadecimal pHash strings.

    Returns:
        int: Number of differing bits.
    """
    try:
        val1 = int(hash1, 16)
        val2 = int(hash2, 16)
        return (val1 ^ val2).bit_count()
    except Exception as exc:
        logger.warning("hamming_distance failed: %s", exc)
        return 999  # safe fallback → treat as non-duplicate


def check_duplicate(
    phash: str,
    text_fingerprint: str,
    existing_records: Optional[List[HashRecord]] = None,
    hamming_threshold: int = 4,
) -> Tuple[bool, Optional[str]]:
    """
    Check whether the given hashes match any stored receipt.

    Args:
        phash:             Perceptual hash of the new receipt image.
        text_fingerprint:  SHA-256 text fingerprint of the new receipt metadata.
        existing_records:  List of HashRecord to compare against.
                           If None, uses the in-memory _hash_store.
        hamming_threshold: Max Hamming distance to consider a visual match.

    Returns:
        (is_duplicate, matched_receipt_id)
    """
    records = existing_records if existing_records is not None else list(_hash_store.values())

    for record in records:
        # Layer 2: Exact text fingerprint match
        if text_fingerprint and record.text_sha256 and record.text_sha256 == text_fingerprint:
            logger.info(
                "Text fingerprint duplicate detected: receipt_id=%s", record.receipt_id
            )
            return True, record.receipt_id

        # Layer 1: Visual pHash match
        if phash and record.phash_64:
            dist = hamming_distance(phash, record.phash_64)
            if dist <= hamming_threshold:
                logger.info(
                    "Visual pHash duplicate detected (Hamming=%d): receipt_id=%s",
                    dist, record.receipt_id,
                )
                return True, record.receipt_id

    return False, None


def register_hashes(
    receipt_id: str,
    phash: str,
    text_fingerprint: str,
) -> HashRecord:
    """
    Register the computed hashes in the in-memory store (and return the record
    for the caller to also persist to the database).

    Args:
        receipt_id:        The UUID of the newly created receipt.
        phash:             64-bit pHash hex string.
        text_fingerprint:  SHA-256 text fingerprint.

    Returns:
        The created HashRecord.
    """
    record = HashRecord(
        receipt_id=receipt_id,
        phash_64=phash,
        text_sha256=text_fingerprint,
    )
    _hash_store[receipt_id] = record
    logger.debug("Registered hashes for receipt_id=%s.", receipt_id)
    return record


def load_hashes_from_db(records: List[Dict]) -> None:
    """
    Populate the in-memory store from a list of database records.
    Each dict should have keys: receipt_id, phash_64, text_fingerprint_sha256.
    Call this at startup when Supabase is available.
    """
    for r in records:
        _hash_store[r["receipt_id"]] = HashRecord(
            receipt_id=r["receipt_id"],
            phash_64=r["phash_64"],
            text_sha256=r["text_fingerprint_sha256"],
        )
    logger.info("Loaded %d hash records from database into memory.", len(records))
