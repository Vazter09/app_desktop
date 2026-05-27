# AGENTS.md — tools/

## Propósito

Scripts de deploy, instalación y diagnóstico. Herramientas operacionales para configurar y mantener el proyecto.

---

## Archivos

### diagnose_bd.php

Script PHP de diagnóstico de conectividad y estado de la BD. Accesible vía:
```
http://localhost:8080/tools/diagnose_bd.php
```

Valida:
- Conexión a PostgreSQL
- Existencia de tablas
- Existencia de funciones
- Usuarios en el sistema
- Versión de schema

**Útil:** ejecutar después de `setup_smartcset.sh` para verificar instalación correcta.

### start_dev.ps1

Script PowerShell para levantar servidor de desarrollo en Windows.

```powershell
.\tools\start_dev.ps1
```

- Asume PHP está en `C:\php\php.exe` — ajustar si es diferente
- Levanta servidor en `http://localhost:8080`
- Abre navegador automáticamente

### setup_db.ps1

Setup de BD desde PowerShell (alternativa a bash).

```powershell
.\tools\setup_db.ps1
```

- Lee `.env`
- Crea BD `db_smartcset`
- Aplica schema + funciones + seeds

### setup_production.sh

Script bash para instalación en servidor Linux/macOS de producción.

```bash
./tools/setup_production.sh
```

- Asume PostgreSQL en `/usr/lib/postgresql/` o similar
- Crea usuario de BD con permisos limitados
- Aplica schema con usuario específico

### deploy_funciones_acceso.ps1

Deploy de funciones PL/pgSQL de acceso (usuarios, menús, sesiones) via PowerShell.

```powershell
.\tools\deploy_funciones_acceso.ps1
```

Desplega solo las funciones de `database/functions/acceso/` sin tocar el resto.

### deploy_funciones_ingresos.ps1

Deploy de funciones de portería (ingreso/salida) via PowerShell.

```powershell
.\tools\deploy_funciones_ingresos.ps1
```

Desplega solo las funciones de `database/functions/porteria/`.

---

## Convenciones

- Scripts PowerShell (.ps1) para Windows
- Scripts bash (.sh) para Linux/macOS
- Todos leen `.env` de la raíz del proyecto
- Los deploy scripts son parciales (no todo el setup)

---

## Qué NO tocar sin entender primero

- El path de PHP en `start_dev.ps1` puede necesitar ajuste según la instalación local
- Los scripts bash requieren `psql` en PATH
- `setup_production.sh` debe adaptarse al entorno de producción (usuario, directorios, etc.)
- Los deploy scripts asumen que PostgreSQL ya existe y es accesible
