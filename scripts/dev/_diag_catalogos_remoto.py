#!/usr/bin/env python3
"""Diagnóstico: login + GET catalogos.php en servidor institucional."""
from __future__ import annotations

import json
import ssl
import sys
import urllib.error
import urllib.request
from http.cookiejar import CookieJar
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        values[key.strip()] = val.strip().strip('"').strip("'")
    return values


def main() -> int:
    env = load_env()
    base = "https://10.5.213.103/smartcset"
    user = env.get("TEST_USER") or "porteria"
    # Preferir claves de prueba documentadas si no hay TEST_*
    clave = env.get("TEST_PASS") or env.get("PORTERIA_PASS") or "Porteria2026!"

    jar = CookieJar()
    ctx = ssl._create_unverified_context()
    opener = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(jar),
        urllib.request.HTTPSHandler(context=ctx),
    )

    def req(method: str, path: str, payload: dict | None = None) -> tuple[int, dict]:
        data = json.dumps(payload).encode() if payload is not None else None
        r = urllib.request.Request(f"{base}{path}", data=data, method=method)
        r.add_header("Content-Type", "application/json")
        r.add_header("Accept", "application/json")
        try:
            with opener.open(r, timeout=20) as resp:
                body = resp.read().decode("utf-8", errors="replace")
                code = resp.status
        except urllib.error.HTTPError as exc:
            code = exc.code
            body = exc.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(body)
        except json.JSONDecodeError:
            parsed = {"_raw": body[:500]}
        return code, parsed

    # Login
    code, login = req(
        "POST",
        "/routers/auth/v1/login.php",
        {"usuario": user, "clave": clave, "origen": "desktop"},
    )
    print("LOGIN", code, json.dumps(login, ensure_ascii=False)[:300])
    if not login.get("ok"):
        return 1

    code, cats = req("GET", "/routers/porteria/v1/catalogos.php")
    print("CATALOGOS", code, json.dumps(cats, ensure_ascii=False)[:800])
    data = cats.get("data") or {}
    print(
        "counts",
        "tipos_doc=",
        len(data.get("tipos_doc") or []),
        "tipos_persona=",
        len(data.get("tipos_persona") or []),
        "entradas=",
        len(data.get("entradas") or []),
    )
    return 0 if cats.get("ok") else 2


if __name__ == "__main__":
    raise SystemExit(main())
