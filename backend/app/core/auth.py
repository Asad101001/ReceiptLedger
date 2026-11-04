"""
ReceiptLedger – Authentication & Session Management
===================================================
Provides JWT and Bearer token authentication, user session models, and FastAPI
dependency injection for securing API endpoints.

Supports:
1. Supabase Auth JWT verification & database persistence in public.users.
2. Local HMAC-SHA256 JWT sessions (for zero-dependency offline/dev usage).
3. Pre-seeded demo and administrator accounts.
4. Resilient multi-tier auth fallback.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import logging
import re
import time
import uuid
from typing import Any, Dict, Optional

from fastapi import Depends, Header, HTTPException, Request, status
from pydantic import BaseModel, Field, field_validator

from app.core.config import settings

logger = logging.getLogger(__name__)

# Fallback secret for dev JWT signing
_AUTH_SECRET = getattr(settings, "jwt_secret", "receiptledger-secure-dev-session-secret-2026")


# ── Schemas ───────────────────────────────────────────────────────────────────

class UserSession(BaseModel):
    user_id: str
    email: str
    full_name: Optional[str] = "ReceiptLedger User"
    role: str = "user"  # "user" or "admin"
    is_authenticated: bool = True
    created_at: Optional[str] = None


_EMAIL_REGEX = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class LoginRequest(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=4, description="User password")

    @field_validator("email")
    @classmethod
    def validate_email_format(cls, v: str) -> str:
        if not _EMAIL_REGEX.match(v):
            raise ValueError("Invalid email address format.")
        return v.lower().strip()


class RegisterRequest(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=6, description="User password (min 6 chars)")
    full_name: Optional[str] = Field("User", description="Display name")

    @field_validator("email")
    @classmethod
    def validate_email_format(cls, v: str) -> str:
        if not _EMAIL_REGEX.match(v):
            raise ValueError("Invalid email address format.")
        return v.lower().strip()


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = 86400  # 24 hours
    user: UserSession


def _hash_pw(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


# ── Seeded User Store (UUIDs matching Supabase PostgreSQL public.users) ────────

_USER_STORE: Dict[str, Dict[str, Any]] = {
    "muhammadasadk42@gmail.com": {
        "user_id": "6dc36ca5-fe30-459b-8e72-715b39800240",
        "email": "muhammadasadk42@gmail.com",
        "password_hash": _hash_pw("asad1234"),
        "full_name": "Asad",
        "role": "admin",
        "created_at": "2026-11-03T14:26:39Z",
    },
    "user@receiptledger.com": {
        "user_id": "3522f8b8-cb86-45c7-acd4-34aad6336945",
        "email": "user@receiptledger.com",
        "password_hash": _hash_pw("demo1234"),
        "full_name": "Demo Household Manager",
        "role": "admin",
        "created_at": "2026-11-03T14:26:59Z",
    },
    "operator@receiptledger.com": {
        "user_id": "81eea267-5a41-4ba1-a95f-3432e0acc333",
        "email": "operator@receiptledger.com",
        "password_hash": _hash_pw("demo1234"),
        "full_name": "Operations Lead",
        "role": "operator",
        "created_at": "2026-11-03T14:26:59Z",
    },
    "auditor@receiptledger.com": {
        "user_id": "0a14f29b-f5d3-4fc4-9b03-14c6c8bb3d1b",
        "email": "auditor@receiptledger.com",
        "password_hash": _hash_pw("demo1234"),
        "full_name": "Compliance Auditor",
        "role": "auditor",
        "created_at": "2026-11-03T14:27:00Z",
    },
}


# ── JWT Utility (Lightweight, pure Python standard library) ───────────────────

def create_access_token(user: UserSession, expires_in: int = 86400) -> str:
    """Create a signed HMAC-SHA256 JWT without requiring external C-dependencies."""
    header = {"alg": "HS256", "typ": "JWT"}
    now = int(time.time())
    payload = {
        "sub": user.user_id,
        "email": user.email,
        "name": user.full_name,
        "role": user.role,
        "iat": now,
        "exp": now + expires_in,
        "iss": "receiptledger-api",
    }

    def b64url(data: bytes) -> str:
        return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")

    enc_header = b64url(json.dumps(header).encode("utf-8"))
    enc_payload = b64url(json.dumps(payload).encode("utf-8"))
    signing_input = f"{enc_header}.{enc_payload}".encode("ascii")
    signature = hmac.new(_AUTH_SECRET.encode("utf-8"), signing_input, hashlib.sha256).digest()
    enc_signature = b64url(signature)

    return f"{enc_header}.{enc_payload}.{enc_signature}"


def decode_access_token(token: str) -> Optional[Dict[str, Any]]:
    """Verify and decode a JWT. Returns payload dict or None if invalid/expired."""
    parts = token.split(".")
    if len(parts) != 3:
        return None

    enc_header, enc_payload, enc_signature = parts

    # Verify signature
    signing_input = f"{enc_header}.{enc_payload}".encode("ascii")
    expected_sig = hmac.new(_AUTH_SECRET.encode("utf-8"), signing_input, hashlib.sha256).digest()

    def b64url_decode(s: str) -> bytes:
        rem = len(s) % 4
        if rem > 0:
            s += "=" * (4 - rem)
        return base64.urlsafe_b64decode(s)

    try:
        sig_bytes = b64url_decode(enc_signature)
        if not hmac.compare_digest(expected_sig, sig_bytes):
            return None

        payload_bytes = b64url_decode(enc_payload)
        payload = json.loads(payload_bytes.decode("utf-8"))

        if payload.get("exp", 0) < int(time.time()):
            logger.debug("Token has expired.")
            return None

        return payload
    except Exception as exc:
        logger.debug("JWT decode failed: %s", exc)
        return None


# ── User Account Operations ───────────────────────────────────────────────────

def authenticate_user(email: str, password: str) -> Optional[UserSession]:
    """
    Verify user credentials and return a UserSession, or None if invalid.
    1. Checks local / pre-seeded memory store first for sub-millisecond response.
    2. Falls back to Supabase Auth verification if not present locally.
    """
    email_clean = email.strip().lower()

    # 1. Local / pre-seeded store (<1ms zero latency)
    user_record = _USER_STORE.get(email_clean)
    if user_record:
        if user_record["password_hash"] == _hash_pw(password):
            return UserSession(
                user_id=user_record["user_id"],
                email=user_record["email"],
                full_name=user_record.get("full_name"),
                role=user_record.get("role", "user"),
                is_authenticated=True,
                created_at=user_record.get("created_at"),
            )
        return None

    # 2. Check Supabase Auth
    try:
        from app.services.store import get_supabase_client
        client = get_supabase_client()
        if client:
            try:
                auth_res = client.auth.sign_in_with_password({"email": email_clean, "password": password})
                if auth_res and auth_res.user:
                    user_id = auth_res.user.id
                    meta = auth_res.user.user_metadata or {}
                    name = meta.get("full_name") or meta.get("name")
                    if not name:
                        try:
                            rows = client.table("users").select("full_name").eq("id", user_id).execute().data
                            if rows and rows[0].get("full_name"):
                                name = rows[0]["full_name"]
                        except Exception:
                            pass

                    role = "admin" if email_clean in ("muhammadasadk42@gmail.com", "user@receiptledger.com") else "user"
                    session = UserSession(
                        user_id=user_id,
                        email=email_clean,
                        full_name=name or "ReceiptLedger User",
                        role=role,
                        is_authenticated=True,
                        created_at=auth_res.user.created_at,
                    )
                    _USER_STORE[email_clean] = {
                        "user_id": user_id,
                        "email": email_clean,
                        "password_hash": _hash_pw(password),
                        "full_name": session.full_name,
                        "role": role,
                        "created_at": auth_res.user.created_at,
                    }
                    return session
            except Exception as auth_err:
                logger.debug("Supabase auth sign-in check: %s", auth_err)
    except Exception as exc:
        logger.debug("Supabase client check: %s", exc)

    return None


def register_user(email: str, password: str, full_name: Optional[str] = None) -> UserSession:
    """
    Register a new user account:
    1. Creates the user in Supabase Auth (if configured)
    2. Inserts into Supabase public.users table (for relational FKs and table viewing)
    3. Caches in local memory store for zero-latency lookups
    """
    email_clean = email.strip().lower()
    user_uuid: Optional[str] = None

    # Check local store first for duplicate check
    if email_clean in _USER_STORE and _USER_STORE[email_clean].get("password_hash") != _hash_pw(password):
        raise ValueError(f"User with email '{email}' already exists.")

    # 1. Supabase Persistence
    try:
        from app.services.store import get_supabase_client
        client = get_supabase_client()
        if client:
            try:
                auth_res = client.auth.admin.create_user({
                    "email": email_clean,
                    "password": password,
                    "email_confirm": True,
                    "user_metadata": {"full_name": full_name or "ReceiptLedger User"},
                })
                user_uuid = auth_res.user.id
                logger.info("Created Supabase Auth user: %s (%s)", email_clean, user_uuid)
            except Exception as auth_err:
                err_msg = str(auth_err).lower()
                if "already" in err_msg or "unique" in err_msg or "exists" in err_msg:
                    # User exists in Supabase Auth, verify password or fetch id
                    try:
                        login_res = client.auth.sign_in_with_password({"email": email_clean, "password": password})
                        if login_res and login_res.user:
                            user_uuid = login_res.user.id
                    except Exception:
                        pass
                logger.debug("Supabase auth create note: %s", auth_err)

            if not user_uuid:
                # Query public.users to see if UUID exists
                try:
                    existing = client.table("users").select("id").eq("email", email_clean).execute().data
                    if existing:
                        user_uuid = existing[0]["id"]
                except Exception:
                    pass

            if not user_uuid:
                user_uuid = str(uuid.uuid4())

            # Sync into public.users mirror table
            try:
                existing_rows = client.table("users").select("id").eq("email", email_clean).execute().data
                if existing_rows:
                    user_uuid = existing_rows[0]["id"]
                    client.table("users").update({"full_name": full_name or "ReceiptLedger User"}).eq("id", user_uuid).execute()
                else:
                    client.table("users").insert({
                        "id": user_uuid,
                        "email": email_clean,
                        "full_name": full_name or "ReceiptLedger User",
                    }).execute()
                logger.info("Synchronized user in Supabase public.users table: %s (%s)", email_clean, user_uuid)
            except Exception as db_err:
                logger.warning("Failed to sync to public.users: %s", db_err)
    except Exception as exc:
        logger.warning("Supabase registration sync error: %s", exc)

    if not user_uuid:
        user_uuid = str(uuid.uuid4())

    created_at = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    record = {
        "user_id": user_uuid,
        "email": email_clean,
        "password_hash": _hash_pw(password),
        "full_name": full_name or "ReceiptLedger User",
        "role": "admin" if email_clean in ("muhammadasadk42@gmail.com", "user@receiptledger.com") else "user",
        "created_at": created_at,
    }
    _USER_STORE[email_clean] = record

    return UserSession(
        user_id=user_uuid,
        email=email_clean,
        full_name=record["full_name"],
        role=record["role"],
        is_authenticated=True,
        created_at=created_at,
    )


# ── FastAPI Dependencies ──────────────────────────────────────────────────────

async def get_current_user(
    authorization: Optional[str] = Header(None, description="Bearer <token>"),
) -> UserSession:
    """
    Dependency that resolves the current user session.
    - If a Bearer token is provided: decodes and authenticates.
    - If unauthenticated in development mode: defaults to a development session
      only when needed.
    """
    if authorization and authorization.lower().startswith("bearer "):
        token = authorization[7:].strip()
        payload = decode_access_token(token)
        if payload:
            sub = payload.get("sub", "")
            email = payload.get("email", "")
            return UserSession(
                user_id=sub or str(uuid.uuid4()),
                email=email,
                full_name=payload.get("name", "User"),
                role=payload.get("role", "user"),
                is_authenticated=True,
            )

    # In development mode, provide default user session
    if settings.is_development:
        return UserSession(
            user_id="6dc36ca5-fe30-459b-8e72-715b39800240",
            email="muhammadasadk42@gmail.com",
            full_name="Asad",
            role="admin",
            is_authenticated=True,
        )

    # In strict production mode without token:
    return UserSession(
        user_id="anonymous",
        email="",
        full_name="Anonymous Guest",
        role="guest",
        is_authenticated=False,
    )


async def require_auth(
    current_user: UserSession = Depends(get_current_user),
) -> UserSession:
    """Dependency that strictly requires an authenticated user session."""
    if not current_user.is_authenticated or current_user.user_id == "anonymous":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Please log in or provide a valid Bearer token.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return current_user
