#!/bin/bash
set -euo pipefail

# Configuración
DIR1="/home/adsocset/carga_planos/juicios"
DIR2="/home/adsocset/carga_planos/juicios_old"
DB_HOST="localhost"
DB_USER="postgres"
DB_NAME="db_smartcset2"
DB_TABLE="tab_temp_juicios"
LOG_ERRORES="$DIR1/errores_juicios.log"
export PGPASSWORD="cset2026*"

# Verificar herramientas
for cmd in ssconvert psql; do
    command -v "$cmd" >/dev/null || { echo "Error: $cmd no instalado." >&2; exit 1; }
done

mkdir -p "$DIR1" "$DIR2"

# Limpiar archivos temporales al salir
cleanup() { rm -f "$archivo_csv" "$archivo_limpio" 2>/dev/null; }
trap cleanup EXIT

# Buscar archivos Excel
shopt -s nullglob
archivos=("$DIR1"/*.xls "$DIR1"/*.xlsx)
[ ${#archivos[@]} -eq 0 ] && { echo "No hay archivos .xls/.xlsx para procesar."; exit 0; }

for archivo_excel in "${archivos[@]}"; do
    nombre_base=$(basename "$archivo_excel" .xls)
    nombre_base="${nombre_base%.*}"
    archivo_csv="$DIR1/$nombre_base.csv"
    archivo_limpio="$DIR1/${nombre_base}_limpio.csv"

    echo "Procesando: $nombre_base"

    # 1. Convertir a CSV con separador ;
    if ! ssconvert --export-type=Gnumeric_stf:stf_assistant -O 'separator=;' "$archivo_excel" "$archivo_csv" 2>/dev/null; then
        echo "Error en conversión: $archivo_excel" >&2
        continue
    fi

    # 2. Procesar con AWK (usando FPAT)
    awk -v fecha_reporte="$(date +%Y-%m-%d)" '
    BEGIN { FPAT = "([^;]*)|(\"[^\"]*\")"; OFS = ";" }

    function clean_num(s) { gsub(/[^0-9]/, "", s); return s }
    function split_code(s,    arr, pos) {
        pos = index(s, " - ")
        if (pos) {
            arr[1] = substr(s, 1, pos-1); arr[2] = substr(s, pos+3)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", arr[1]); gsub(/^[[:space:]]+|[[:space:]]+$/, "", arr[2])
            gsub(/[[:space:]]/, "", arr[1])
        } else {
            arr[1] = ""; arr[2] = s
        }
        return arr[1] "|" arr[2]
    }

    {
        gsub(/\r$/, "")
        for (i=1; i<=NF; i++) { gsub(/^"|"$/, "", $i); gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i) }

        # Valores fijos (filas 3-12)
        if (NR >= 3 && NR <= 12) {
            pos = NR - 2
            valor = $3
            if (pos == 1)       id_ficha = clean_num(valor)
            else if (pos == 2)  id_programa = clean_num(valor)
            else if (pos == 3)  id_version = clean_num(valor)
            else if (pos == 4)  nom_ficha = valor
            else if (pos == 5)  ind_estado = valor
            else if (pos == 6)  fec_inicio = valor
            else if (pos == 7)  fec_fin = valor
            else if (pos == 8)  id_modalidad = valor
            else if (pos == 9) { split(split_code(valor), a, "|"); cod_regional = clean_num(a[1]); nom_regional = a[2] }
            else if (pos == 10) { split(split_code(valor), a, "|"); cod_centro = clean_num(a[1]); nom_centro = a[2] }
            next
        }
        if (NR == 13) next
        if (NR >= 14) {
            if (NF < 10) { for (i=NF+1; i<=10; i++) $i = ""; NF = 10 }

            # Columnas 1-8
            id_tipodoc = $1
            num_docume = clean_num($2)
            nom_aprendiz = $3
            ape_aprendiz = $4
            ind_est_aprendiz = $5
            split(split_code($6), a, "|"); cod_competencia = clean_num(a[1]); nom_competencia = a[2]
            split(split_code($7), a, "|"); cod_rap = clean_num(a[1]); nom_rap = a[2]
            val_juicio = $8

            # Columna 9: fec_juicio (todo el dato)
            fec_juicio = $9

            # Columna 10: instructor
            instr = $10
            tip_doc_instructor = ""; num_doc_instructor = ""; nom_instructor = ""
            if (instr != "" && instr != "-") {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", instr)
                pos1 = index(instr, " ")
                if (pos1) {
                    tip_doc_instructor = substr(instr, 1, pos1-1)
                    resto = substr(instr, pos1+1)
                    pos2 = index(resto, " - ")
                    if (pos2) {
                        num_doc_instructor = substr(resto, 1, pos2-1)
                        nom_instructor = substr(resto, pos2+3)
                    } else {
                        num_doc_instructor = resto
                    }
                    gsub(/[^0-9]/, "", num_doc_instructor)
                } else {
                    tip_doc_instructor = instr
                }
            }

            print fecha_reporte,
                  id_ficha, id_programa, id_version, nom_ficha, ind_estado,
                  fec_inicio, fec_fin, id_modalidad,
                  cod_regional, nom_regional, cod_centro, nom_centro,
                  id_tipodoc, num_docume, nom_aprendiz, ape_aprendiz, ind_est_aprendiz,
                  cod_competencia, nom_competencia, cod_rap, nom_rap,
                  val_juicio, fec_juicio,
                  tip_doc_instructor, num_doc_instructor, nom_instructor
        }
    }' "$archivo_csv" > "$archivo_limpio"

    # 3. Verificar que el archivo limpio no esté vacío
    if [ ! -s "$archivo_limpio" ]; then
        echo "Archivo limpio vacío: $archivo_limpio" >&2
        echo "[$(date)] Archivo vacío: $nombre_base" >> "$LOG_ERRORES"
        continue
    fi

    # 4. Cargar a PostgreSQL
    if psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "\copy $DB_TABLE (fecha_reporte, id_ficha, id_programa, id_version, nom_ficha, ind_estado, fec_inicio, fec_fin, id_modalidad, cod_regional, nom_regional, cod_centro, nom_centro, id_tipodoc, num_docume, nom_aprendiz, ape_aprendiz, ind_est_aprendiz, cod_competencia, nom_competencia, cod_rap, nom_rap, val_juicio, fec_juicio, tip_doc_instructor, num_doc_instructor, nom_instructor) FROM '$archivo_limpio' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');" 2>&1; then
        echo "Carga exitosa: $nombre_base ($(wc -l < "$archivo_limpio") líneas)"
        mv "$archivo_excel" "$DIR2/"
        rm -f "$archivo_csv" "$archivo_limpio"   # Eliminar CSVs temporales
    else
        echo "[$(date)] Error al cargar: $archivo_limpio" >> "$LOG_ERRORES"
        echo "Error en la carga. Revisa $LOG_ERRORES" >&2
    fi
done

unset PGPASSWORD