#!/bin/bash
set -euo pipefail

# Configuración
readonly DIR1="/home/adsocset/carga_planos/PE04"
readonly DIR2="/home/adsocset/carga_planos/PE04_old"
readonly DB_HOST="localhost"
readonly DB_USER="postgres"
readonly DB_NAME="db_smartcset2"
readonly DB_TABLE="tab_temp_pe04"
readonly LOG_ERRORES="$DIR1/errores_pe04.log"
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

for archivo_excel in "${archivos[@]}"; do
    nombre_base=$(basename "$archivo_excel")
    nombre_base="${nombre_base%.*}"
    archivo_csv="$DIR1/$nombre_base.csv"
    archivo_limpio="$DIR1/${nombre_base}_limpio.csv"

    echo "Procesando: $nombre_base"

    # Convertir a CSV
    if ! ssconvert --export-type=Gnumeric_stf:stf_assistant -O 'separator=;' "$archivo_excel" "$archivo_csv" 2>/dev/null; then
        echo "Error en conversión: $archivo_excel" >&2
        echo "[$(date)] Error en conversión: $archivo_excel" >> "$LOG_ERRORES"
        continue
    fi

    fecha_reporte=$(date +%Y-%m-%d)

    # Procesar con AWK (función para intervalos)
    awk -F';' -v fecha_reporte="$fecha_reporte" '
    function fmt_interval(h) {
        if (h ~ /^[0-9]{1,2}:[0-9]{2}$/) return h ":00"
        if (h ~ /^[0-9]{1,2}:[0-9]{2}:[0-9]{2}$/) return h
        return "0:00:00"
    }
    BEGIN { OFS = ";" }
    NR <= 4 { next }
    {
        for (i=1; i<=NF; i++) {
            gsub(/^"|"$/, "", $i)
            gsub(/^[ \t]+|[ \t]+$/, "", $i)
        }
        if (NF < 2 || $1 == "" || $1 !~ /^[0-9]+$/) next

        # Fechas
        fec_inicio = ($13 ~ /^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}$/) ? sprintf("%04d-%02d-%02d", substr($13,7,4), substr($13,4,2), substr($13,1,2)) : ""
        fec_fin    = ($14 ~ /^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}$/) ? sprintf("%04d-%02d-%02d", substr($14,7,4), substr($14,4,2), substr($14,1,2)) : ""

        # Intervalos
        hrs_planta  = fmt_interval($44)
        hrs_contrat = fmt_interval($45)
        hrs_context = fmt_interval($46)
        hrs_monitor = fmt_interval($47)
        hrs_instemp = fmt_interval($48)
        total_hrs   = fmt_interval($49)

        print fecha_reporte, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12,
              fec_inicio, fec_fin, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24,
              $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38,
              $39, $40, $41, $42, $43, hrs_planta, hrs_contrat, hrs_context, hrs_monitor,
              hrs_instemp, total_hrs, $50, $51, $52
    }
    ' "$archivo_csv" > "$archivo_limpio"

    if [ ! -s "$archivo_limpio" ]; then
        echo "Archivo limpio vacío: $archivo_limpio" >&2
        echo "[$(date)] Archivo vacío: $nombre_base" >> "$LOG_ERRORES"
        continue
    fi

    # Cargar a PostgreSQL
    if psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "\copy $DB_TABLE (fecha_reporte, cod_regional, nom_regional, cod_centro, nom_centro, id_ficha, id_unico_ficha, ind_estado_curso, id_nivel_forma, nom_nivel_forma, id_jornada, nom_jornada, ind_tipo_forma, fec_inicio_ficha, fec_fin_ficha, val_etapa_ficha, val_modalidad, nom_responsable, id_empresa, id_tipodoc_emp, nom_empresa, id_sector_prog, nom_sector_prog, id_ocupacion, nom_ocupacion, id_programa, id_version, nom_programa, id_pais, nom_pais, id_depto, nom_depto, id_municipio, nom_municipio, id_convenio, nom_convenio, ind_cobertura, id_prog_especial, nom_prog_especial, num_cursos, num_aprend_masc, num_aprend_fem, num_aprend_nobin, num_tot_aprend, val_hrs_planta, val_hrs_contrat, val_hrs_context, val_hrs_monitor, val_hrs_instemp, val_total_hrs, val_total_apr_act, val_duracion_prog, nom_nuevo_sector) FROM '$archivo_limpio' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');" 2>&1; then
        echo "Carga exitosa: $nombre_base"
        mv "$archivo_excel" "$DIR2/"
        rm -f "$archivo_csv" "$archivo_limpio"
    else
        echo "[$(date)] Error en DB al cargar: $archivo_limpio" >> "$LOG_ERRORES"
        echo "Error en la carga. Revisa $LOG_ERRORES" >&2
    fi
done

unset PGPASSWORD