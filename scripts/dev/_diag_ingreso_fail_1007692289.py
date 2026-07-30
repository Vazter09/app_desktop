"""Diagnóstico remoto: ingresos de 1007692289 + smoke registrar."""
from __future__ import annotations

import json
import ssl
import time
import urllib.error
import urllib.request
from http.cookiejar import CookieJar
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
DOC = "1007692289"


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        values[key.strip()] = val.strip().strip('"').strip("'")
    return values


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> tuple[int, str]:
    transport = client.get_transport()
    assert transport is not None
    channel = transport.open_session()
    channel.get_pty()
    channel.exec_command("sudo -S bash -lc " + repr(inner))
    time.sleep(0.3)
    if channel.send_ready():
        channel.send(password + "\n")
    out_buf = b""
    while True:
        if channel.recv_ready():
            out_buf += channel.recv(4096)
        if channel.recv_stderr_ready():
            out_buf += channel.recv_stderr(4096)
        if channel.exit_status_ready():
            while channel.recv_ready():
                out_buf += channel.recv(4096)
            while channel.recv_stderr_ready():
                out_buf += channel.recv_stderr(4096)
            break
        time.sleep(0.05)
    code = channel.recv_exit_status()
    text = out_buf.decode("utf-8", errors="replace")
    lines = []
    for line in text.splitlines():
        low = line.lower()
        if "password" in low or "[sudo]" in low:
            continue
        lines.append(line)
    return code, "\n".join(lines)


def http_json(
    opener: urllib.request.OpenerDirector,
    method: str,
    url: str,
    payload: dict | None = None,
) -> tuple[int, dict]:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json")
    try:
        with opener.open(req, timeout=30) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8") if exc.fp else "{}"
        try:
            parsed = json.loads(body)
        except json.JSONDecodeError:
            parsed = {"raw": body}
        return exc.code, parsed


def main() -> int:
    env = load_env()
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST") or env.get("DB_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=20,
        allow_agent=False,
        look_for_keys=False,
    )

    sql = f"""
SELECT id_persona, nom_persona, ape_persona, id_tipo_persona, id_tipo_docum,
       fec_ultima_entrada, fec_ultima_salida
FROM tab_personas WHERE id_persona = {DOC};

SELECT id_ingreso, id_visitante, fec_ingreso, fec_salida, id_metodo_aut,
       usr_insert, id_entrada_centro
FROM tab_log_ingresos
WHERE id_visitante = {DOC}
ORDER BY fec_ingreso DESC LIMIT 15;

SELECT id_ingreso, id_visitante, fec_ingreso, id_metodo_aut, usr_insert
FROM tab_log_ingresos
WHERE fec_ingreso >= CURRENT_DATE
ORDER BY fec_ingreso DESC LIMIT 20;

SELECT to_regclass('public.tab_novedades_ingreso');
"""
    cmd = f"sudo -u postgres psql -d db_smartcset2 -v ON_ERROR_STOP=1 -c {sql!r}"
    code, out = sudo_bash(client, env["SERVER_PASS"], cmd)
    print("=== DB ===")
    print(out)
    print("exit", code)

    # Smoke API: login + consultar + (no registrar destructive unless needed)
    base = "https://10.5.213.103/smartcset"
    ctx = ssl._create_unverified_context()
    jar = CookieJar()
    opener = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(jar),
        urllib.request.HTTPSHandler(context=ctx),
    )
    st, login = http_json(
        opener,
        "POST",
        f"{base}/routers/auth/v1/login.php",
        {"usuario": "porteria", "password": "Porteria2026!"},
    )
    print("=== LOGIN ===", st, json.dumps(login, ensure_ascii=False)[:300])

    st, consulta = http_json(
        opener,
        "GET",
        f"{base}/routers/porteria/v1/ingreso/consultar.php?documento={DOC}&tipo_doc=CC",
    )
    print("=== CONSULTAR ===", st, json.dumps(consulta, ensure_ascii=False)[:800])

    st, cats = http_json(
        opener, "GET", f"{base}/routers/porteria/v1/catalogos.php"
    )
    print("=== CATALOGOS ok ===", st, "entradas" in (cats.get("data") or cats))

    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
