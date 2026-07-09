#!/bin/bash
set -euo pipefail

# ==========================================
# Configuración
# ==========================================
readonly DIR1="/home/adsocset/carga_planos/DF14A"
readonly DIR2="/home/adsocset/carga_planos/DF14A_old"
readonly DB_HOST="localhost"
readonly DB_USER="postgres"
readonly DB_NAME="db_smartcset3"
readonly DB_TABLE="tab_temp_df14A"
readonly LOG_ERRORES="$DIR1/errores_df14A.log"
export PGPASSWORD="postgresdev2026*"

# Verificar comandos
for cmd in ssconvert psql; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd no está instalado." >&2
        exit 1
    fi
done

mkdir -p "$DIR1" "$DIR2"

cleanup() {
    rm -f "$archivo_csv" "$archivo_limpio" 2>/dev/null
}
trap cleanup EXIT

shopt -s nullglob
archivos=("$DIR1"/*.xls "$DIR1"/*.xlsx)

if [ ${#archivos[@]} -eq 0 ]; then
    echo "No se encontraron archivos .xls o .xlsx para procesar."
    exit 0
fi

for archivo_excel in "${archivos[@]}"; do
    nombre_base=$(basename "$archivo_excel")
    nombre_base="${nombre_base%.*}"
    archivo_csv="$DIR1/$nombre_base.csv"
    archivo_limpio="$DIR1/${nombre_base}_limpio.csv"

    echo "Procesando: $nombre_base"

    # Convertir a CSV
    if ! ssconvert --export-type=Gnumeric_stf:stf_assistant -O 'separator=;' "$archivo_excel" "$archivo_csv" 2>/dev/null; then
        echo "Error en conversión: $archivo_excel" >&2
        echo "[$(date)] Error conversión: $archivo_excel" >> "$LOG_ERRORES"
        continue
    fi

    fecha_reporte=$(date +%Y-%m-%d)

    # Procesar con AWK (versión mejorada con logging de fechas no convertibles)
    awk -F';' -v fecha_reporte="$fecha_reporte" -v logfile="$LOG_ERRORES" -v archivo="$nombre_base" '
    function convertir_fecha(f,    fecha_limpia, partes, i) {
        # Eliminar espacios
        gsub(/^[ \t]+|[ \t]+$/, "", f)
        # Si contiene espacio, tomar la parte anterior (la fecha)
        i = index(f, " ")
        if (i > 0) {
            f = substr(f, 1, i - 1)
        }
        # Ahora f debería ser "yyyy-mm-dd" o "dd/mm/yyyy"
        if (f ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) {
            return f
        }
        if (f ~ /^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}$/) {
            split(f, partes, "/")
            return sprintf("%04d-%02d-%02d", partes[3], partes[2], partes[1])
        }
        # Si no se puede convertir, registrar en log (solo la primera vez)
        if (f != "") {
            print "[$(date)] Fecha no convertible: \"" f "\" en archivo " archivo >> logfile
        }
        return ""
    }

    BEGIN { OFS = ";" }
    NR <= 4 { next }
    {
        # Limpiar comillas y espacios
        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", $i)
            gsub(/^[ \t]+|[ \t]+$/, "", $i)
        }
        # Validar primera columna numérica (omitir encabezados)
        if (NF < 2 || $1 == "" || $1 !~ /^[0-9]+$/) next

        # Convertir fechas (col13 y col14)
        fec_ini = convertir_fecha($13)
        fec_fin = convertir_fecha($14)

        # Salida: 38 campos (fecha_reporte + 37 del Excel)
        print fecha_reporte,
              $1,  $2,  $3,  $4,  $5,  $6,  $7,  $8,  $9,  $10,
              $11, $12, fec_ini, fec_fin,
              $15, $16, $17, $18, $19, $20, $21, $22, $23, $24,
              $25, $26, $27, $28, $29, $30, $31, $32, $33, $34,
              $35, $36, $37
    }
    ' "$archivo_csv" > "$archivo_limpio"

    if [ ! -s "$archivo_limpio" ]; then
        echo "Archivo limpio vacío: $archivo_limpio" >&2
        echo "[$(date)] Archivo limpio vacío: $nombre_base" >> "$LOG_ERRORES"
        continue
    fi

    # Cargar a PostgreSQL
    if psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "\copy $DB_TABLE FROM '$archivo_limpio' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');" 2>&1; then
        echo "Carga exitosa: $nombre_base ($(wc -l < "$archivo_limpio") líneas)"
        mv "$archivo_excel" "$DIR2/"
        rm -f "$archivo_csv" "$archivo_limpio"
    else
        echo "[$(date)] Error en DB al cargar: $archivo_limpio" >> "$LOG_ERRORES"
        echo "Error en la carga. Revisa $LOG_ERRORES" >&2
    fi
done

unset PGPASSWORD