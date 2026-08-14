#!/usr/bin/env python3
"""Despliega metodo+puerta de salida al arbol LIVE src/ de 10.5.213.111.

Causa: BD tenia fun_update_log_salida(bigint, varchar) que NO escribe
id_metodo_salida / id_entrada_salida (quedaban en 1 del INSERT).
PHP live llamaba fun_registrar_salida_manual con 3 args.

No toca login ni fun_insert_log_ingreso.
"""
from __future__ import annotations

import os
import subprocess
import sys
import time
from pathlib import Path

try:
    import paramiko
except ImportError:
    print("FAIL: falta paramiko")
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[2]
LIVE = "/var/www/html/smartcset/src/backend"
JS_LIVE = (
    "/var/www/html/smartcset/src/frontend/js/modules/porteria/salidas.js"
)
DEFAULT_HOST = "10.5.213.111"
SQL_FILES = [
    "database/functions/porteria/fun_update_log_salida.sql",
    "database/functions/porteria/fun_registrar_salida_manual.sql",
]


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


def deploy_sql(env: dict[str, str]) -> int:
    psql = os.environ.get(
        "PSQL",
        r"C:\Program Files\PostgreSQL\17\bin\psql.exe",
    )
    if not Path(psql).is_file():
        print(f"FAIL: no psql en {psql}")
        return 1
    os.environ["PGPASSWORD"] = env.get("DB_PASS", "")
    if env.get("DB_SSLMODE"):
        os.environ["PGSSLMODE"] = env["DB_SSLMODE"]
    host = env.get("DB_HOST", DEFAULT_HOST)
    port = env.get("DB_PORT", "5432")
    user = env.get("DB_USER", "postgres")
    db = env.get("DB_NAME", "db_smartcset2")
    for rel in SQL_FILES:
        path = ROOT / rel
        print(f"SQL {rel}")
        proc = subprocess.run(
            [
                psql, "-h", host, "-p", port, "-U", user, "-d", db,
                "-v", "ON_ERROR_STOP=1", "-f", str(path),
            ],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if proc.returncode != 0:
            print(proc.stdout)
            print(proc.stderr)
            print(f"FAIL SQL {rel}")
            return proc.returncode
    check = subprocess.run(
        [
            psql, "-h", host, "-p", port, "-U", user, "-d", db,
            "-t", "-A", "-c",
            "SELECT oid::regprocedure::text FROM pg_proc "
            "WHERE proname IN ("
            "'fun_update_log_salida','fun_registrar_salida_manual'"
            ") ORDER BY 1; "
            "SELECT CASE WHEN prosrc LIKE '%id_metodo_salida = wid_metodo_eff%' "
            "THEN 'WRITES_METODO' ELSE 'NO_METODO' END "
            "FROM pg_proc WHERE proname='fun_update_log_salida'; "
            "SELECT CASE WHEN prosrc LIKE '%id_entrada_salida = wid_entrada_eff%' "
            "THEN 'WRITES_PUERTA' ELSE 'NO_PUERTA' END "
            "FROM pg_proc WHERE proname='fun_update_log_salida';",
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    print("VERIFY_SQL:")
    print(check.stdout)
    if check.returncode != 0:
        print(check.stderr)
        return check.returncode
    out = check.stdout
    if "WRITES_METODO" not in out or "WRITES_PUERTA" not in out:
        print("FAIL: fun_update_log_salida no escribe metodo/puerta")
        return 1
    if "fun_registrar_salida_manual(" not in out:
        print("FAIL: falta fun_registrar_salida_manual")
        return 1
    if ",numeric,numeric)" not in out.replace(" ", "").lower() and \
            "numeric,numeric)" not in out.lower():
        # firma 5-arg termina en numeric, numeric
        if "id_entrada_salida" not in out and "numeric" not in out.lower():
            print("FAIL: no se ve firma 5-arg de registrar_salida")
            return 1
    return 0


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
    if "?::NUMERIC, ?::VARCHAR, ?::TEXT, ?::NUMERIC, ?::NUMERIC" in text:
        return text
    if old not in text:
        raise SystemExit("FAIL: prepare.php live sin SQL de 3 args")
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
    if "function salidaToPost" not in text:
        raise SystemExit("FAIL: Payload live sin salidaToPost")
    idx = text.find("function salidaToPost")
    tail = text[idx:]
    if "'sel_entrada'" in tail and "id_entrada" in tail:
        return text
    if old not in tail:
        raise SystemExit("FAIL: bloque salidaToPost live no coincide")
    return text[:idx] + tail.replace(old, new, 1)


def patch_salida_service(text: str) -> str:
    out = text
    if "$metodoSalida" not in out:
        needle = "$obs = trim($datos['txt_observaciones'] ?? '');"
        if needle not in out:
            raise SystemExit("FAIL: salida_service live sin txt_observaciones")
        inject = (
            needle + "\n"
            "    $metodoSalida = (int) ($captura['id_metodo_aut'] ?? 1);\n"
            "    if ($metodoSalida < 1) {\n"
            "        $metodoSalida = 1;\n"
            "    }\n"
            "    $entradaSalida = (int) ($datos['sel_entrada'] ?? 0);\n"
            "    if ($entradaSalida < 1) {\n"
            "        throw new Exception('Seleccione la puerta de salida.');\n"
            "    }"
        )
        out = out.replace(needle, inject, 1)
    elif "Seleccione la puerta de salida" not in out:
        assign = "$entradaSalida = (int) ($datos['sel_entrada'] ?? 0);"
        if assign not in out:
            raise SystemExit("FAIL: salida_service live sin sel_entrada")
        inject = (
            assign
            + "\n    if ($entradaSalida < 1) {\n"
            + "        throw new Exception('Seleccione la puerta de salida.');\n"
            + "    }"
        )
        out = out.replace(assign, inject, 1)
        out = out.replace("$entradaParam", "$entradaSalida")

    old3 = """    $stmtFunRegistrar->execute([
        $doc,
        $tipo,
        // Solo texto del formulario Observación/Novedad (≥5 chars crea fila).
        $obs !== '' ? $obs : null,
    ]);"""
    old3b = """    $stmtFunRegistrar->execute([
        $doc,
        $tipo,
        $obs !== '' ? $obs : null,
    ]);"""
    new5 = """    $stmtFunRegistrar->execute([
        $doc,
        $tipo,
        $obs !== '' ? $obs : null,
        $metodoSalida,
        $entradaSalida,
    ]);"""
    if "$metodoSalida" in out and "$entradaSalida" in out \
            and out.count("$stmtFunRegistrar->execute") >= 1:
        if old3 in out:
            out = out.replace(old3, new5, 1)
        elif old3b in out:
            out = out.replace(old3b, new5, 1)
        elif "$entradaSalida," in out or "$entradaParam," in out:
            out = out.replace("$entradaParam", "$entradaSalida")
        else:
            # execute de 3 args en una linea
            compact = (
                "$stmtFunRegistrar->execute([$doc, $tipo, "
                "$obs !== '' ? $obs : null]);"
            )
            if compact in out:
                out = out.replace(
                    compact,
                    "$stmtFunRegistrar->execute(["
                    "$doc, $tipo, $obs !== '' ? $obs : null, "
                    "$metodoSalida, $entradaSalida]);",
                    1,
                )
    if "$metodoSalida" not in out or "$entradaSalida" not in out:
        raise SystemExit("FAIL: no pude inyectar metodo/puerta en execute")
    return out


def patch_salidas_js(text: str) -> str:
    if "id_entrada: Number(inputPuerta" in text:
        return text
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
    if old not in text:
        raise SystemExit("FAIL: salidas.js live no coincide")
    return text.replace(old, new, 1)


def deploy_php(env: dict[str, str]) -> int:
    host = env.get("SERVER_HOST") or DEFAULT_HOST
    user = env.get("SERVER_USER", "")
    password = env.get("SERVER_PASS", "")
    if not user or not password:
        print("FAIL: SERVER_USER/SERVER_PASS")
        return 1
    files = {
        f"{LIVE}/includes/prepare.php": patch_prepare,
        f"{LIVE}/_lib_porteria/Payload.php": patch_payload,
        f"{LIVE}/services/porteria/salida_service.php": patch_salida_service,
        JS_LIVE: patch_salidas_js,
    }
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
    sftp = client.open_sftp()
    remote_tmp = f"/tmp/smartcset_salida_mp_{int(time.time())}"
    code_m, out_m = sudo_bash(
        client, password, f"mkdir -p {remote_tmp} && chmod 777 {remote_tmp}"
    )
    if code_m != 0:
        print("FAIL mkdir", out_m)
        client.close()
        return 1
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
        bak = remote + ".bak_salida_mp_20260814"
        copies.append(f"cp -n {remote} {bak}")
        copies.append(f"cp -f {tmp_path} {remote}")
        print(f"OK patched {remote}")
    sftp.close()
    if not copies:
        print("WARN: nada que copiar (ya estaba parcheado)")
        client.close()
        return 0
    copies.append(
        "grep -A2 -n 'fun_registrar_salida_manual' "
        f"{LIVE}/includes/prepare.php"
    )
    copies.append(
        "grep -n 'sel_entrada' "
        f"{LIVE}/_lib_porteria/Payload.php"
    )
    copies.append(
        "grep -nE 'metodoSalida|entradaSalida|Seleccione la puerta' "
        f"{LIVE}/services/porteria/salida_service.php"
    )
    copies.append(f"grep -n 'id_entrada' {JS_LIVE}")
    copies.append(f"rm -rf {remote_tmp}")
    copies.append("echo DEPLOY_SALIDA_MP_OK")
    code2, out2 = sudo_bash(client, password, " && ".join(copies))
    safe = out2.encode("ascii", "replace").decode("ascii")
    print(safe)
    client.close()
    if code2 != 0 or "DEPLOY_SALIDA_MP_OK" not in out2:
        print("FAIL PHP deploy")
        return 1
    if "?::NUMERIC, ?::VARCHAR, ?::TEXT, ?::NUMERIC, ?::NUMERIC" not in out2:
        print("FAIL: prepare.php live sigue sin 5 args")
        return 1
    return 0


def main() -> int:
    env = load_env()
    rc = deploy_sql(env)
    if rc != 0:
        return rc
    rc = deploy_php(env)
    if rc != 0:
        return rc
    print("OK deploy salida metodo+puerta -> 10.5.213.111 src/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
