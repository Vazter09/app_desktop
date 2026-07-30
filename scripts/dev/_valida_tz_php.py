#!/usr/bin/env python3
"""Diag: timezone de la conexion PHP/Apache vs peer postgres."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = "/var/www/html/smartcset"
RUN = f"""#!/bin/bash
set +e
echo '=== .env remoto TZ ==='
grep -E 'DB_TIMEZONE|APP_TIMEZONE|DB_HOST' {REMOTE}/.env 2>/dev/null || grep -E 'DB_TIMEZONE|APP_TIMEZONE|DB_HOST' /var/www/html/smartcset/.env 2>/dev/null || true
ls -la {REMOTE}/.env /var/www/html/smartcset/frontend/web/public/../../../../.env 2>/dev/null | head -5
find {REMOTE} -maxdepth 2 -name '.env' 2>/dev/null

echo '=== Db.php set timezone ==='
grep -n 'TIME ZONE\\|timezone\\|DB_TIMEZONE' {REMOTE}/backend/core/Db.php {REMOTE}/backend/core/prepare.php 2>/dev/null | head -30

echo '=== php probe timezone via PDO ==='
php <<'PHP'
<?php
$envFile = '{REMOTE}/.env';
if (!is_file($envFile)) {{ $envFile = '/var/www/html/smartcset/.env'; }}
$env = [];
foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {{
    $line = trim($line);
    if ($line === '' || $line[0] === '#' || strpos($line, '=') === false) continue;
    [$k,$v] = explode('=', $line, 2);
    $env[trim($k)] = trim($v, \" \\t\\\"'\");
}}
$dsn = sprintf('pgsql:host=%s;port=%s;dbname=%s', $env['DB_HOST'] ?? '127.0.0.1', $env['DB_PORT'] ?? '5432', $env['DB_NAME'] ?? 'db_smartcset2');
$opts = [];
if (!empty($env['DB_SSLMODE'])) {{ $dsn .= ';sslmode=' . $env['DB_SSLMODE']; }}
try {{
    $pdo = new PDO($dsn, $env['DB_USER'] ?? 'postgres', $env['DB_PASS'] ?? '', [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $tz = $env['DB_TIMEZONE'] ?? 'America/Bogota';
    $pdo->exec(\"SET TIME ZONE \" . $pdo->quote($tz));
    $row = $pdo->query(\"SHOW timezone; SELECT now()::text AS now_txt, CURRENT_TIMESTAMP::text AS cts\")->fetch(PDO::FETCH_ASSOC);
    // SHOW + SELECT in one query is awkward; do separately
    echo 'pdo_tz=' . $pdo->query('SHOW timezone')->fetchColumn() . PHP_EOL;
    echo 'pdo_now=' . $pdo->query('SELECT now()::text')->fetchColumn() . PHP_EOL;
    echo 'pdo_current_timestamp=' . $pdo->query('SELECT CURRENT_TIMESTAMP::text')->fetchColumn() . PHP_EOL;
    echo 'pdo_set_tz=' . $tz . PHP_EOL;
}} catch (Throwable $e) {{
    echo 'PDO_FAIL ' . $e->getMessage() . PHP_EOL;
}}
PHP

echo '=== fun_registrar_ingreso usa CURRENT_TIMESTAMP? ==='
sudo -u postgres psql -d db_smartcset2 -P pager=off -c "SELECT substring(prosrc from position('CURRENT_TIMESTAMP' in prosrc) for 200) FROM pg_proc WHERE proname='fun_registrar_ingreso_manual' LIMIT 1;"

echo DONE
"""


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        values[k.strip()] = v.strip().strip('"').strip("'")
    return values


def sudo_bash(client: paramiko.SSHClient, password: str, inner: str) -> str:
    transport = client.get_transport()
    assert transport is not None
    channel = transport.open_session()
    channel.get_pty()
    channel.exec_command("sudo -S bash -lc " + repr(inner))
    time.sleep(0.4)
    if channel.send_ready():
        channel.send(password + "\n")
    out = b""
    idle = 0
    while True:
        got = False
        if channel.recv_ready():
            out += channel.recv(8192)
            got = True
            idle = 0
        if channel.recv_stderr_ready():
            out += channel.recv_stderr(8192)
            got = True
            idle = 0
        if channel.exit_status_ready():
            while channel.recv_ready():
                out += channel.recv(8192)
            while channel.recv_stderr_ready():
                out += channel.recv_stderr(8192)
            break
        if not got:
            idle += 1
            if idle > 600:
                break
            time.sleep(0.05)
    return "\n".join(
        ln
        for ln in out.decode("utf-8", errors="replace").splitlines()
        if "password" not in ln.lower() and "[sudo]" not in ln.lower()
    )


def main() -> int:
    env = load_env()
    host = env.get("SERVER_HOST") or env.get("DB_HOST") or "10.5.213.103"
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
    remote = f"/tmp/valida_tz_php_{int(time.time())}.sh"
    sudo_bash(client, env["SERVER_PASS"], "chmod 777 /tmp")
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(RUN.replace("\r\n", "\n"))
    sftp.close()
    print(sudo_bash(client, env["SERVER_PASS"], f"bash {remote}; rm -f {remote}"))
    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
