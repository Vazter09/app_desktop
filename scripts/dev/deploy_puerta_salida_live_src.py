#!/usr/bin/env python3
"""Despliega el fix de puerta al arbol LIVE de .111 (src/) y repara login."""
from __future__ import annotations

import re
import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
LIVE = "/var/www/html/smartcset/src/backend"
DEFAULT_HOST = "10.5.213.111"


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
    idle = 0
    while True:
        got = False
        if channel.recv_ready():
            out_buf += channel.recv(8192)
            got = True
            idle = 0
        if channel.recv_stderr_ready():
            out_buf += channel.recv_stderr(8192)
            got = True
            idle = 0
        if channel.exit_status_ready():
            while channel.recv_ready():
                out_buf += channel.recv(8192)
            while channel.recv_stderr_ready():
                out_buf += channel.recv_stderr(8192)
            break
        if not got:
            idle += 1
            if idle > 500:
                break
            time.sleep(0.05)
    code = channel.recv_exit_status() if channel.exit_status_ready() else 1
    text = out_buf.decode("utf-8", errors="replace")
    filtered = [
        ln
        for ln in text.splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    ]
    return code, "\n".join(filtered)


def patch_prepare(text: str) -> str:
    old = (
        '$sql_fun_registrar_salida = "SELECT fun_registrar_salida_manual(\n'
        "        ?::NUMERIC, ?::VARCHAR, ?::TEXT\n"
        '    )";'
    )
    new = (
        '$sql_fun_registrar_salida = "SELECT fun_registrar_salida_manual(\n'
        "        ?::NUMERIC, ?::VARCHAR, ?::TEXT, ?::NUMERIC, ?::NUMERIC\n"
        '    )";'
    )
    if old not in text:
        raise SystemExit("FAIL: no encontre el SQL de 3 args en prepare.php live")
    return text.replace(old, new, 1)


def patch_payload(text: str) -> str:
    old = (
        "            'hid_metodo_aut' => (int) ($json['metodo_aut'] ?? 1),\n"
        "            'hid_foto_data' => trim((string) ($json['foto_base64'] ?? '')),\n"
    )
    new = (
        "            'hid_metodo_aut' => (int) ($json['metodo_aut'] ?? 1),\n"
        "            'sel_entrada' => (int) (\n"
        "                $json['id_entrada'] ?? $json['sel_entrada'] ?? 0\n"
        "            ),\n"
        "            'hid_foto_data' => trim((string) ($json['foto_base64'] ?? '')),\n"
    )
    if "salidaToPost" not in text:
        raise SystemExit("FAIL: Payload live sin salidaToPost")
    if "'sel_entrada' => (int) (" in text and "id_entrada" in text:
        return text
    if old not in text:
        raise SystemExit("FAIL: no encontre el bloque salidaToPost en Payload live")
    # Solo el de salida: el de ingreso ya tiene sel_entrada mas arriba.
    idx = text.find("function salidaToPost")
    if idx < 0:
        raise SystemExit("FAIL: no esta salidaToPost")
    head, tail = text[:idx], text[idx:]
    if old not in tail:
        raise SystemExit("FAIL: bloque hid_metodo_aut de salida no coincide")
    return head + tail.replace(old, new, 1)


def patch_salida_service(text: str) -> str:
    if "Seleccione la puerta de salida" in text and "$entradaSalida" in text:
        return text
    pattern = re.compile(
        r"\$entradaSalida\s*=\s*\(int\)\s*\(\$datos\['sel_entrada'\]\s*\?\?\s*0\);.*?"
        r"\$entradaParam\s*=\s*\$entradaSalida\s*>=\s*1\s*\?\s*\$entradaSalida\s*:\s*0;",
        re.S,
    )
    repl = (
        "$entradaSalida = (int) ($datos['sel_entrada'] ?? 0);\n"
        "    if ($entradaSalida < 1) {\n"
        "        throw new Exception('Seleccione la puerta de salida.');\n"
        "    }"
    )
    new, n = pattern.subn(repl, text, count=1)
    if n:
        new = new.replace("$entradaParam", "$entradaSalida")
        return new
    # Variante sin fallback local: anadir validacion tras asignar sel_entrada.
    assign = "$entradaSalida = (int) ($datos['sel_entrada'] ?? 0);"
    if assign not in text:
        raise SystemExit("FAIL: salida_service live sin sel_entrada")
    inject = (
        assign
        + "\n    if ($entradaSalida < 1) {\n"
        + "        throw new Exception('Seleccione la puerta de salida.');\n"
        + "    }"
    )
    return text.replace(assign, inject, 1)


def patch_auth_login(text: str) -> str:
    old = "require_once dirname(__DIR__) . '/includes/prepare_login.php';"
    new = "require_once dirname(__DIR__) . '/includes/prepare.php';"
    if old not in text:
        if "includes/prepare.php" in text:
            return text
        raise SystemExit("FAIL: auth_login.php no pide prepare_login.php")
    return text.replace(old, new, 1)


def patch_salidas_js(text: str) -> str:
    old = (
        "            const payload = {\n"
        "                documento: inputDoc.value.replace(/\\D/g, ''),\n"
        "                tipo_doc: selTipo?.value || 'CC',\n"
        "                metodo_aut: Number(hidMetodo?.value || 1),\n"
        "                observaciones: document.getElementById('txt_observaciones')?.value || '',\n"
        "                foto_base64: document.getElementById('hid_foto_data')?.value || '',\n"
        "            };"
    )
    new = (
        "            const payload = {\n"
        "                documento: inputDoc.value.replace(/\\D/g, ''),\n"
        "                tipo_doc: selTipo?.value || 'CC',\n"
        "                metodo_aut: Number(hidMetodo?.value || 1),\n"
        "                observaciones: document.getElementById('txt_observaciones')?.value || '',\n"
        "                foto_base64: document.getElementById('hid_foto_data')?.value || '',\n"
        "                id_entrada: Number(inputPuerta?.value || 0),\n"
        "            };"
    )
    if "id_entrada: Number(inputPuerta" in text:
        return text
    if old not in text:
        raise SystemExit("FAIL: salidas.js live no coincide")
    return text.replace(old, new, 1)


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST") or DEFAULT_HOST
    user = env.get("SERVER_USER", "")
    password = env.get("SERVER_PASS", "")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"SSH {user}@{host}")
    client.connect(
        hostname=host,
        username=user,
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    files = {
        f"{LIVE}/includes/prepare.php": patch_prepare,
        f"{LIVE}/_lib_porteria/Payload.php": patch_payload,
        f"{LIVE}/api/auth_login.php": patch_auth_login,
        "/var/www/html/smartcset/src/frontend/js/modules/porteria/salidas.js": (
            patch_salidas_js
        ),
    }
    code, out = sudo_bash(
        client,
        password,
        "find /var/www/html/smartcset/src/backend -name salida_service.php",
    )
    print("FIND_SALIDA", out)
    for line in out.splitlines():
        if line.endswith("salida_service.php"):
            files[line.strip()] = patch_salida_service

    sftp = client.open_sftp()
    remote_tmp = f"/tmp/smartcset_puerta_live_{int(time.time())}"
    sudo_bash(client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")
    copies = []
    for remote, patcher in files.items():
        print(f"GET {remote}")
        with sftp.open(remote, "r") as fh:
            original = fh.read().decode("utf-8")
        patched = patcher(original)
        if patched == original:
            print(f"SKIP unchanged {remote}")
            continue
        local_name = remote.replace("/", "_")
        tmp_path = f"{remote_tmp}/{local_name}"
        with sftp.open(tmp_path, "w") as fh:
            fh.write(patched.encode("utf-8"))
        bak = remote + ".bak_puerta_20260813"
        copies.append(f"cp -n {remote} {bak}")
        copies.append(f"cp -f {tmp_path} {remote}")
        print(f"OK patched {remote}")
    sftp.close()
    copies.append(
        "grep -n 'fun_registrar_salida_manual' "
        f"{LIVE}/includes/prepare.php | head -4"
    )
    copies.append(
        "grep -n sel_entrada "
        f"{LIVE}/_lib_porteria/Payload.php | head -8"
    )
    copies.append(
        "grep -n prepare.php "
        f"{LIVE}/api/auth_login.php | head -3"
    )
    copies.append(
        "ls /var/www/html/smartcset/src/backend/includes/PrepareAuthSql.php "
        "/var/www/html/smartcset/src/backend/includes/RouterResponse.php "
        "/var/www/html/smartcset/src/backend/includes/ErrorHandler.php "
        "2>&1 | cat"
    )
    copies.append("echo DEPLOY_LIVE_PUERTA_OK")
    code2, out2 = sudo_bash(client, password, " && ".join(copies))
    print(out2)
    client.close()
    if code2 != 0 or "DEPLOY_LIVE_PUERTA_OK" not in out2:
        print("FAIL live deploy")
        return 1
    if "?::NUMERIC, ?::VARCHAR, ?::TEXT, ?::NUMERIC, ?::NUMERIC" not in out2:
        print("FAIL: prepare.php live sigue en 3 args")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
