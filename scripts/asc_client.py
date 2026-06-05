#!/usr/bin/env python3
"""
asc_client.py — Minimal App Store Connect API client for Snuglo automation.

Provides JWT auth (ES256 from a .p8 key), a tiny request() wrapper, and a
stdlib .strings parser. Shared by setup_leaderboards.py / setup_achievements.py.

Reads credentials from `<repo>/secrets/.env.local`:
    APP_STORE_KEY_ID
    APP_STORE_ISSUER_ID
    APP_STORE_KEY_PATH     # .p8 path, relative to repo root or absolute
    APP_STORE_APP_ID       # the app's numeric ASC id

Requires PyJWT (crypto extra):  pip3 install --user "pyjwt[crypto]"
"""

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Optional

try:
    import jwt as pyjwt
except ImportError:
    sys.exit("✗ PyJWT yok. Çalıştır:\n    pip3 install --user 'pyjwt[crypto]'\n")

API_BASE = "https://api.appstoreconnect.apple.com"
REPO = Path(__file__).resolve().parent.parent


# ── .env loader (stdlib only) ────────────────────────────────────────────

def load_env() -> None:
    env_path = REPO / "secrets" / ".env.local"
    if not env_path.exists():
        return
    for raw in env_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key, value = key.strip(), value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


load_env()


# ── Errors / client ──────────────────────────────────────────────────────

class APIError(RuntimeError):
    def __init__(self, method: str, url: str, status: int, body: Any):
        super().__init__(f"{method} {url} → HTTP {status}: {body}")
        self.status = status
        self.body = body
        self.url = url


class ASCClient:
    def __init__(self, key_id: str, issuer_id: str, p8_path: Path):
        self.key_id = key_id
        self.issuer_id = issuer_id
        self.p8 = p8_path.read_text()
        self._token: Optional[str] = None
        self._token_exp: int = 0

    def _token_value(self) -> str:
        now = int(time.time())
        if self._token and self._token_exp - now > 60:
            return self._token
        self._token_exp = now + 1200  # 20-min token (Apple max)
        self._token = pyjwt.encode(
            {"iss": self.issuer_id, "iat": now,
             "exp": self._token_exp, "aud": "appstoreconnect-v1"},
            self.p8, algorithm="ES256",
            headers={"alg": "ES256", "kid": self.key_id, "typ": "JWT"},
        )
        return self._token

    def request(self, method: str, path: str, body: Optional[dict] = None,
                params: Optional[dict] = None) -> dict:
        url = API_BASE + path
        if params:
            from urllib.parse import urlencode
            url += "?" + urlencode(params, doseq=True)
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", f"Bearer {self._token_value()}")
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")
        try:
            with urllib.request.urlopen(req) as resp:
                raw = resp.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            err_body = e.read().decode(errors="replace")
            try:
                err_json = json.loads(err_body)
            except Exception:
                err_json = {"raw": err_body}
            raise APIError(method, url, e.code, err_json) from None


# ── Credentials + Game Center detail helpers ──────────────────────────────

def client_from_env() -> tuple["ASCClient", str]:
    """Build an ASCClient from env. Returns (client, app_id). Exits on missing."""
    key_id = os.environ.get("APP_STORE_KEY_ID")
    issuer = os.environ.get("APP_STORE_ISSUER_ID")
    app_id = os.environ.get("APP_STORE_APP_ID")
    key_path = os.environ.get("APP_STORE_KEY_PATH", "")
    p8 = (REPO / key_path) if key_path and not Path(key_path).is_absolute() else Path(key_path)
    if not all([key_id, issuer, app_id]) or not p8.exists():
        print("✗ Eksik kimlik veya .p8 bulunamadı. secrets/.env.local'i doldur.")
        print(f"  key_id={key_id!r} issuer={issuer!r} app_id={app_id!r} p8={p8}")
        sys.exit(1)
    return ASCClient(key_id, issuer, p8), app_id


def game_center_detail_id(client: "ASCClient", app_id: str) -> str:
    """Fetch (or create) the app's gameCenterDetail id."""
    res = client.request("GET", f"/v1/apps/{app_id}/gameCenterDetail")
    data = res.get("data")
    if data and data.get("id"):
        return data["id"]
    print("• gameCenterDetail yok, oluşturuluyor…")
    body = {"data": {"type": "gameCenterDetails",
                     "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}}
    return client.request("POST", "/v1/gameCenterDetails", body=body)["data"]["id"]


# ── Localizable.strings reader ─────────────────────────────────────────────

_STRINGS_RE = re.compile(r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')


def load_strings(locale_dir: str) -> dict:
    """Parse SnugloApp/Resources/<locale>.lproj/Localizable.strings → {key: value}."""
    p = REPO / "SnugloApp" / "Resources" / f"{locale_dir}.lproj" / "Localizable.strings"
    out: dict = {}
    if not p.exists():
        return out
    for k, v in _STRINGS_RE.findall(p.read_text(encoding="utf-8")):
        out[k.replace('\\"', '"')] = v.replace('\\"', '"').replace("\\n", "\n")
    return out
