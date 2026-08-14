#!/usr/bin/env python3
"""Completa el deploy live: includes faltantes, Payload salida, execute 5 args."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
LIVE = "/var/www/html/smartcset/src/backend"
DEFAULT_HOST = "10.5.213.111"
PAYLOAD_SALIDA_OLD = """    public static function salidaToPost(array $json): array
    {
        return [
            'sel_tipo_doc' => trim((string) ($json['tipo_doc'] ?? 'CC')),
            'txt_documento' => trim((string) ($json['documento'] ?? '')),
            'hid_captura_raw' => trim((string) ($json['captura_raw'] ?? '')),
            'txt_observaciones' => trim((string) ($json['observaciones'] ?? '')),
            'hid_metodo_aut' => (int) ($json['metodo_aut'] ?? 1),
            'hid_foto_data' => trim((string) ($json['foto_base64'] ?? '')),
        ];
    }"""
PAYLOAD_SALIDA_NEW = """    public static function salidaToPost(array $json): array
    {
        return [
            'sel_tipo_doc' => trim((string) ($json['tipo_doc'] ?? 'CC')),
            'txt_documento' => trim((string) ($json['documento'] ?? '')),
            'hid_captura_raw' => trim((string) ($json['captura_raw'] ?? '')),
            'txt_observaciones' => trim((string) ($json['observaciones'] ?? '')),
            'hid_metodo_aut' => (int) ($json['metodo_aut'] ?? 1),
            'sel_entrada' => (int) (
                $json['id_entrada'] ?? $json['sel_entrada'] ?? 0
            ),
            'hid_foto_data' => trim((string) ($json['foto_base64'] ?? '')),
        ];
    }"""


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


def main() -> int:
    env = load_env()
    password = env.get("SERVER_PASS", "")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST") or DEFAULT_HOST,
        username=env.get("SERVER_USER", ""),
        password=password,
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    sftp = client.open_sftp()
    remote_tmp = f"/tmp/smartcset_puerta2_{int(time.time())}"
    sudo_bash(client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}")

    includes = {
        "backend/core/PrepareAuthSql.php": f"{LIVE}/includes/PrepareAuthSql.php",
        "backend/core/RouterResponse.php": f"{LIVE}/includes/RouterResponse.php",
        "backend/core/ErrorHandler.php": f"{LIVE}/includes/ErrorHandler.php",
    }
    copies = []
    for rel, dest in includes.items():
        local = ROOT / rel
        tmp = f"{remote_tmp}/{Path(rel).name}"
        sftp.put(str(local), tmp)
        copies.append(f"cp -f {tmp} {dest}")
        print(f"OK stage {rel}")

    payload_path = f"{LIVE}/_lib_porteria/Payload.php"
    with sftp.open(payload_path, "r") as fh:
        payload = fh.read().decode("utf-8")
    if PAYLOAD_SALIDA_OLD not in payload:
        print("FAIL Payload salidaToPost no coincide")
        print(payload[payload.find("function salidaToPost"):payload.find("function salidaToPost")+800])
        client.close()
        return 1
    patched = payload.replace(PAYLOAD_SALIDA_OLD, PAYLOAD_SALIDA_NEW, 1)
    tmp_payload = f"{remote_tmp}/Payload.php"
    with sftp.open(tmp_payload, "w") as fh:
        fh.write(patched.encode("utf-8"))
    copies.append(f"cp -f {tmp_payload} {payload_path}")

    # Localizar execute de salida y services.
    code, out = sudo_bash(
        client,
        password,
        "grep -n 'fun_registrar_salida\\|stmt_fun_registrar_salida\\|sel_entrada' "
        "-r /var/www/html/smartcset/src/backend --include='*.php' | head -40",
    )
    print("GREP_SALIDA")
    print(out)

    copies.append(f"sed -n '254,258p' {LIVE}/includes/prepare.php")
    copies.append(f"grep -n sel_entrada {payload_path} | head -10")
    copies.append(f"ls {LIVE}/includes/PrepareAuthSql.php {LIVE}/includes/RouterResponse.php")
    copies.append("echo DEPLOY2_OK")
    sftp.close()
    code2, out2 = sudo_bash(client, password, " && ".join(copies))
    print(out2)
    client.close()
    if code2 != 0 or "DEPLOY2_OK" not in out2:
        print("FAIL deploy2")
        return 1
    if "?::NUMERIC, ?::VARCHAR, ?::TEXT, ?::NUMERIC, ?::NUMERIC" not in out2:
        print("FAIL prepare sigue sin 5 placeholders")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
