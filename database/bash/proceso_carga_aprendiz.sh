#!/bin/bash
set -euo pipefail

# ==========================================
# Configuración
# ==========================================
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

readonly DIR1="/home/adsocset/carga_planos/matriculados"
readonly DIR2="/home/adsocset/carga_planos/matriculados_old"
readonly DB_HOST="localhost"
readonly DB_USER="postgres"
readonly DB_NAME="db_smartcset2"
readonly DB_TABLE="tab_temp_aprendices"
readonly LOG_ERRORES="$DIR1/errores_matriculados.log"
export PGPASSWORD="cset2026*"

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

# ==========================================
# Procesamiento
# ==========================================
for archivo_excel in "${archivos[@]}"; do
    nombre_base=$(basename "$archivo_excel")
    nombre_base="${nombre_base%.*}"          # elimina extensión
    archivo_csv="$DIR1/$nombre_base.csv"
    archivo_limpio="$DIR1/${nombre_base}_limpio.csv"

    echo "Procesando: $nombre_base"

    # 1. Convertir a CSV (separador ;)
    if ! ssconvert --export-type=Gnumeric_stf:stf_assistant -O 'separator=;' "$archivo_excel" "$archivo_csv" 2>/dev/null; then
        echo "Error en conversión: $archivo_excel" >&2
        echo "[$(date)] Error en conversión: $archivo_excel" >> "$LOG_ERRORES"
        continue
    fi

    # 2. Procesar con AWK
    awk -F';' '
    BEGIN { OFS = ";" }
    
    function convertir_fecha(f) {
        if (f ~ /^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}$/) {
            split(f, a, "/")
            return sprintf("%04d-%02d-%02d", a[3], a[2], a[1])
        }
        return ""
    }
    
    # Extraer atributos del encabezado
    /Ficha de Caracterización:/ {
        gsub(/"/, "", $3)
        split($3, partes, " - ")
        atr1 = partes[1]   # id_ficha
        atr2 = partes[2]   # nom_ficha
    }
    /Estado:/ {
        gsub(/"/, "", $3)
        atr3 = $3          # ind_estado_ficha
    }
    /Fecha del Reporte:/ {
        gsub(/"/, "", $3)
        atr4 = convertir_fecha($3)   # fecha_reporte
    }
    
    # Inicio de los datos
    /Tipo de Documento/ {
        imprimir_datos = 1
        next
    }
    
    # Procesar líneas de datos
    imprimir_datos == 1 && $1 != "" {
        # Limpiar comillas y espacios de cada campo
        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", $i)
            gsub(/^[ \t]+|[ \t]+$/, "", $i)
        }
        # Saltar si el primer campo (tipo doc) está vacío
        if ($1 == "") next
        
        # Imprimir las 7 columnas en el orden de la tabla
        print atr1, atr2, atr3, atr4, $1, $2, $3, $4, $5, $6, $7
    }
    ' "$archivo_csv" > "$archivo_limpio"

    # Verificar que el archivo limpio tenga contenido
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