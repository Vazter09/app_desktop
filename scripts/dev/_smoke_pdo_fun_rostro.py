#!/usr/bin/env python3
"""Smoke PDO: misma firma que prepare.php contra BD del .env de Apache."""
from __future__ import annotations

import time
from pathlib import Path

import paramiko

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
            if idle > 600:
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


PHP_SMOKE = r"""<?php
declare(strict_types=1);
$envf = '/var/www/html/smartcset/.env';
$vals = [];
foreach (file($envf, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    $line = trim($line);
    if ($line === '' || $line[0] === '#' || !str_contains($line, '=')) {
        continue;
    }
    [$k, $v] = explode('=', $line, 2);
    $vals[trim($k)] = trim($v, " \t\"'");
}
$host = $vals['DB_HOST'] ?? '';
$port = $vals['DB_PORT'] ?? '5432';
$name = $vals['DB_NAME'] ?? '';
$user = $vals['DB_USER'] ?? '';
$pass = $vals['DB_PASS'] ?? '';
$ssl  = $vals['DB_SSLMODE'] ?? 'require';
$dsn = "pgsql:host={$host};port={$port};dbname={$name};sslmode={$ssl}";
echo "DSN_HOST={$host} DB={$name}\n";
$pdo = new PDO($dsn, $user, $pass, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$path = $pdo->query('SHOW search_path')->fetchColumn();
echo "search_path={$path}\n";
$firmas = $pdo->query(
    "SELECT oid::regprocedure::text FROM pg_proc WHERE proname = 'fun_identificar_persona_por_rostro' ORDER BY 1"
)->fetchAll(PDO::FETCH_COLUMN);
echo 'firmas=' . implode(' | ', $firmas) . "\n";
$vec = '[' . implode(',', array_fill(0, 128, '0.01')) . ']';
$stmt = $pdo->prepare('SELECT fun_identificar_persona_por_rostro(?::VECTOR, ?::NUMERIC)');
$stmt->execute([$vec, 0.35]);
$id = $stmt->fetchColumn();
echo 'result=' . var_export($id, true) . "\n";
echo "PDO_SMOKE_OK\n";
"""


def main() -> int:
    env = load_env()
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=env.get("SERVER_HOST", "10.5.213.103"),
        username=env["SERVER_USER"],
        password=env["SERVER_PASS"],
        timeout=25,
        allow_agent=False,
        look_for_keys=False,
    )
    remote = f"/tmp/smoke_pdo_rostro_{int(time.time())}.php"
    sftp = client.open_sftp()
    with sftp.file(remote, "w") as fh:
        fh.write(PHP_SMOKE)
    sftp.close()
    code, out = sudo_bash(client, env["SERVER_PASS"], f"php {remote}; rm -f {remote}")
    print(out)
    print("exit", code)
    client.close()
    return 0 if "PDO_SMOKE_OK" in out else 1


if __name__ == "__main__":
    raise SystemExit(main())
