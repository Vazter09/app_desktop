# test_seguridad — Tests de la Fase 1 (MSPI)

> **Última ejecución (2026-06-14):** `python3 -m unittest discover -v`
> → **23/23 PASS**. Ver `handoff.txt` (sección "test_seguridad/ — SUITE
> DE TESTS AUTOMATIZADOS") para el detalle de los fixes de entorno
> necesarios (sesiones activas residuales, credencial de `porteria`).

Cada archivo `test_eN_*.py` o `test_e1_aXX_*.py` corresponde a **un**
informe de la carpeta:

```
Documentacion para implementacion de MSPI/FASE 01_Blindaje Técnico Inmediato/REPORTE_E1-*.md
```

y verifica las premisas principales que ese informe afirma haber
corregido. Si en el futuro alguien rompe una de esas correcciones por
accidente (al refactorizar código relacionado), estos tests deben
fallar.

## Cobertura actual

| Archivo de test | Informe que verifica |
|---|---|
| `test_e1_a01_broken_access_control.py` | REPORTE_E1-A01 — CRUD de menús/usuarios exclusivo de administradores |
| `test_e1_a02_cryptographic_failures.py` | REPORTE_E1-A02 — infraestructura `DB_SSLMODE` (TLS hacia BD, parcial) |
| `test_e4_hardening_sesiones.py` | REPORTE_E1-E04 — headers de seguridad, cookies, CSP, session fixation |
| `test_e6_verificacion_uploads.py` | REPORTE_E1-E06 — `.htaccess` de uploads, validación MIME, recompresión |
| `test_e7_correccion_setup.py` | REPORTE_E1-E07 — `setup_smartcset.sh` despliega las funciones correctas |

## Requisitos

- **Python 3** (solo librería estándar `unittest` + `requests`, que ya
  está disponible en este entorno).
- Para los tests HTTP (`E1-A01`, `E4`): el servidor de desarrollo PHP
  corriendo:
  ```bash
  cd /home/anderson/smartcset
  php -S localhost:8080
  ```
  Si el servidor no responde, esos tests se SALTAN (`SKIP`) con un
  mensaje indicando cómo levantarlo — no fallan con un error de
  conexión confuso.
- Para el test de BD (`E7`, último caso): `psql` en PATH y la base de
  datos configurada en `.env` (mismas credenciales que usa la app). Si
  `psql` no está disponible, ese caso se salta.

## Cómo ejecutar

Todos los tests:

```bash
cd /home/anderson/smartcset/test_seguridad
python3 -m unittest discover -v
```

Un solo informe:

```bash
cd /home/anderson/smartcset/test_seguridad
python3 -m unittest test_e4_hardening_sesiones -v
```

Un solo caso dentro de un archivo:

```bash
python3 -m unittest test_e1_a01_broken_access_control.TestE1A01BrokenAccessControl.test_usuario_admin_no_recibe_403
```

## Convenciones

- Cada archivo de test es independiente y puede ejecutarse solo.
- `common.py` NO contiene tests; solo helpers compartidos (login HTTP,
  lectura de `.env`, ejecución de `psql`).
- Los tests son de **caja negra** (HTTP) o de **lectura estática del
  código fuente** (para premisas que no se pueden verificar fácilmente
  por HTTP, como el contenido de `.htaccess` o de `setup_smartcset.sh`).
  No modifican datos en la base de datos ni el sistema de archivos.
- Las credenciales usadas (`admin.smart` / `porteria`) son las
  credenciales de **desarrollo** documentadas en `CLAUDE.md`. No usar
  esta suite contra un entorno de producción.
