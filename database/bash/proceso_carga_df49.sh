#!/bin/bash
set -euo pipefail

# Configuración
readonly DIR1="/home/adsocset/carga_planos/DF49"
readonly DIR2="/home/adsocset/carga_planos/DF49_old"
readonly DB_HOST="localhost"
readonly DB_USER="postgres"
readonly DB_NAME="db_smartcset2"
readonly DB_TABLE="tab_temp_df49"
readonly LOG_ERRORES="$DIR1/errores_df49.log"
export PGPASSWORD="postgresdev2026*"

# Verificar comandos necesarios
for cmd in ssconvert psql; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd no está instalado." >&2
        exit 1
    fi
done

# Crear directorios si no existen
mkdir -p "$DIR1" "$DIR2"

# Limpiar archivos temporales al salir
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

    # Convertir a CSV con separador ;
    if ! ssconvert --export-type=Gnumeric_stf:stf_assistant -O 'separator=;' "$archivo_excel" "$archivo_csv" 2>/dev/null; then
        echo "Error en conversión: $archivo_excel" >&2
        echo "[$(date)] Error en conversión: $archivo_excel" >> "$LOG_ERRORES"
        continue
    fi

    fecha_reporte=$(date +%Y-%m-%d)

    # Procesar con AWK (sin conversión de fechas)
    awk -F';' -v fecha_reporte="$fecha_reporte" '
    BEGIN { OFS = ";" }
    NR <= 4 { next }
    {
        # Limpiar comillas y espacios
        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", $i)
            gsub(/^[ \t]+|[ \t]+$/, "", $i)
        }
        # Validar primera columna numérica y no vacía
        if (NF < 2 || $1 == "" || $1 !~ /^[0-9]+$/) next

        # Asignar fechas directamente (valores originales, con o sin hora)
        fec_inicial = $6
        fec_final   = $7

        # Imprimir 23 columnas: fecha_reporte + 22 campos del Excel
        print fecha_reporte, $1, $2, $3, $4, $5, fec_inicial, fec_final,
              $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22
    }
    ' "$archivo_csv" > "$archivo_limpio"

    if [ ! -s "$archivo_limpio" ]; then
        echo "Archivo limpio vacío: $archivo_limpio" >&2
        echo "[$(date)] Archivo vacío: $nombre_base" >> "$LOG_ERRORES"
        continue
    fi

    # Cargar a PostgreSQL
    if psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "\copy $DB_TABLE FROM '$archivo_limpio' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');" 2>&1; then
        echo "Carga exitosa: $nombre_base"
        mv "$archivo_excel" "$DIR2/"
        rm -f "$archivo_csv" "$archivo_limpio"
    else
        echo "[$(date)] Error en DB al cargar: $archivo_limpio" >> "$LOG_ERRORES"
        echo "Error en la carga. Revisa $LOG_ERRORES" >&2
    fi
done

unset PGPASSWORD