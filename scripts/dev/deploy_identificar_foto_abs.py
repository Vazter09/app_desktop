#!/usr/bin/env python3
"""Parche minimo: identificar live lee JPG de frontend/img/biometria."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
LIVE = (
    "/var/www/html/smartcset/src/backend/api/"
    "porteria_biometria_identificar.php"
)
OLD = """    // Foto de enrolamiento: tab_personas.ruta_foto_facial
    $fotoBase64 = null;
    if ($persona !== false && !empty($persona['ruta_foto_facial'])) {
        $fotoBase64 = BiometriaPhotoService::leerFoto((string) $persona['ruta_foto_facial']);
    }"""
NEW = """    // Foto: ruta en BD o carpeta /src/frontend/img/biometria/{id}/
    $fotoBase64 = null;
    $idPersonaInt = (int) $idPersona;
    $ruta = ($persona !== false) ? (string) ($persona['ruta_foto_facial'] ?? '') : '';
    if ($persona !== false) {
        $fotoBase64 = BiometriaPhotoService::resolverFotoBase64($ruta, $idPersonaInt);
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
    time.sleep(0.4)
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
            if idle > 600:
                break
            time.sleep(0.05)
    code = channel.recv_exit_status() if channel.exit_status_ready() else 1
    text = "\n".join(
        ln
        for ln in out_buf.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )
    return code, text


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST") or "10.5.213.111"
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    stamp = int(time.time())
    sftp = client.open_sftp()
    with sftp.file(LIVE, "r") as fh:
        src = fh.read().decode("utf-8")
    if OLD not in src:
        print("BLOQUE NO ENCONTRADO")
        print(src[src.find("Foto") : src.find("Foto") + 400] if "Foto" in src else src[:400])
        client.close()
        return 1
    patched = src.replace(OLD, NEW, 1)
    tmp = f"/tmp/porteria_biometria_identificar_{stamp}.php"
    with sftp.file(tmp, "w") as fh:
        fh.write(patched)
    sftp.close()
    code, out = sudo_bash(
        client,
        env["SERVER_PASS"],
        f"cp -f {LIVE} {LIVE}.bak_{stamp} ; "
        f"cp -f {tmp} {LIVE} ; "
        f"chown www-data:www-data {LIVE} ; chmod a+r {LIVE} ; "
        f"grep -n 'resolverFotoBase64\\|img/biometria' {LIVE} ; "
        f"rm -f {tmp} ; echo OK_IDENT_FOTO",
    )
    print(out)
    print("exit", code)
    client.close()
    return 0 if code == 0 and "OK_IDENT_FOTO" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
