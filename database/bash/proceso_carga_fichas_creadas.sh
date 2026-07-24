#!/bin/bash
set -euo pipefail

# ==========================================
# Configuración
# ==========================================
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

readonly DIR1="/home/adsocset/carga_planos/fichas_creadas"
readonly DIR2="/home/adsocset/carga_planos/fichas_creadas_old"
readonly DB_HOST="localhost"
readonly DB_USER="postgres"
readonly DB_NAME="db_smartcset2"
readonly DB_TABLE="tab_temp_fichas_creadas"
readonly LOG_ERRORES="$DIR1/errores_fichas_creadas.log"
export PGPASSWORD="postgresdev2026*"

# Verificar comandos necesarios
for cmd in ssconvert psql; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd no está instalado." >&2
        exit 1
    fi
done

mkdir -p "$DIR1" "$DIR2"

# Limpieza al salir
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

# ==========================================
# Procesamiento principal
# ==========================================
for archivo_excel in "${archivos[@]}"; do
    nombre_base=$(basename "$archivo_excel")
    nombre_base="${nombre_base%.*}"
    archivo_csv="$DIR1/$nombre_base.csv"
    archivo_limpio="$DIR1/${nombre_base}_limpio.csv"

    echo "Procesando: $nombre_base"

    # 1. Convertir a CSV con separador ';'
    if ! ssconvert --export-type=Gnumeric_stf:stf_assistant -O 'separator=;' "$archivo_excel" "$archivo_csv" 2>/dev/null; then
        echo "Error en conversión: $archivo_excel" >&2
        echo "[$(date)] Error en conversión: $archivo_excel" >> "$LOG_ERRORES"
        continue
    fi

    # 2. Procesar con AWK: omitir encabezado, limpiar comillas, convertir fechas
    awk -F';' '
    BEGIN { OFS = ";" }
    
    function convertir_fecha(f) {
        # Espera formato dd/mm/yyyy (sin hora)
        if (f ~ /^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}$/) {
            split(f, a, "/")
            return sprintf("%04d-%02d-%02d", a[3], a[2], a[1])
        }
        # Si ya viene en yyyy-mm-dd (caso borde)
        if (f ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) return f
        # Vacío o no reconocido
        return ""
    }
    
    # Saltar la primera línea (encabezados)
    NR == 1 { next }
    
    {
        # Limpiar comillas dobles y espacios de cada campo
        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", $i)
            gsub(/^[ \t]+|[ \t]+$/, "", $i)
        }
        
        # Convertir fechas (columnas 4 y 5)
        $4 = convertir_fecha($4)   # fec_inicio
        $5 = convertir_fecha($5)   # fec_fin
        
        # Columna 6 (fec_ejecucion) se deja como VARCHAR (sin cambio)
        # Las columnas numéricas (1,2,8,11) se imprimen tal cual.
        # Si contienen coma decimal, PostgreSQL fallará.
        # Ver recomendación al final.
        
        # Imprimir las 13 columnas en el orden original
        print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13
    }
    ' "$archivo_csv" > "$archivo_limpio"

    # Verificar que el archivo limpio tenga datos
    if [ ! -s "$archivo_limpio" ]; then
        echo "Archivo limpio vacío: $archivo_limpio" >&2
        echo "[$(date)] Archivo vacío: $nombre_base" >> "$LOG_ERRORES"
        rm -f "$archivo_csv" "$archivo_limpio"
        continue
    fi

    # 3. Cargar a PostgreSQL
    echo "Cargando datos a la base de datos..."
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