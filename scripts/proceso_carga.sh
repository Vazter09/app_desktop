#!/bin/bash

# ==========================================
# Configuración de Entorno y Codificación
# ==========================================
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

DIR1="/home/cperez/planos/Matriculados"
DIR2="/home/cperez/planos/old"

DB_HOST="localhost"
DB_USER="postgres"
DB_NAME="db_smartcset"
DB_TABLE="tab_temp_aprendices"
export PGPASSWORD="cperez123"

# ==========================================
# Verificación de existencia de archivos
# ==========================================
shopt -s nullglob
archivos=("$DIR1"/*.xls)

if [ ${#archivos[@]} -eq 0 ]; then
    echo "No se encontraron archivos .xls para procesar."
    exit 0
fi

# ==========================================
# Procesamiento secuencial
# ==========================================
for archivo_excel in "${archivos[@]}"; do

    nombre_base=$(basename "$archivo_excel" .xls)
    archivo_csv="$DIR1/$nombre_base.csv"
    archivo_limpio="$DIR1/${nombre_base}_limpio.csv"

    echo "Procesando archivo: $nombre_base.xls"

    # 1. Convertir a CSV
    ssconvert --export-type=Gnumeric_stf:stf_assistant -O 'separator=;' "$archivo_excel" "$archivo_csv"
    if [ $? -ne 0 ]; then
        echo "Error al convertir: $archivo_excel"
        continue
    fi

    # Ajuste temporal de permisos
    chown cperez:cperez "$archivo_csv"
    chmod 777 "$archivo_csv"

    # 2. Extraer atributos, limpiar archivo y mostrar variables en pantalla
    awk -F';' '
    BEGIN {
        OFS=";" 
    }
    
    # Quitamos el símbolo ^ para ignorar las comillas iniciales
    /Ficha de Caracterización:/ {
        gsub(/"/, "", $3) # Limpiamos las comillas del valor
        split($3, partes, " - ")
        atr1 = partes[1]
        atr2 = partes[2]
    }
    
    /Estado:/ {
        gsub(/"/, "", $3)
        atr3 = $3
    }
    
    /Fecha del Reporte:/ {
        gsub(/"/, "", $3)
        split($3, fecha_partes, "/")
        # El orden correcto para YYYY-MM-DD según tu CSV
        atr4 = fecha_partes[1] "-" fecha_partes[2] "-" fecha_partes[3]
    }
    
    # Detectamos la cabecera de datos e imprimimos el debug en pantalla
    /Tipo de Documento/ {
        print "\n--- DEBUG: ATRIBUTOS EXTRAÍDOS ---" > "/dev/stderr"
        print "Ficha (atr1):  " atr1 > "/dev/stderr"
        print "Nombre (atr2): " atr2 > "/dev/stderr"
        print "Estado (atr3): " atr3 > "/dev/stderr"
        print "Fecha (atr4):  " atr4 > "/dev/stderr"
        print "----------------------------------\n" > "/dev/stderr"
        
        imprimir_datos = 1
        next
    }
    
    # Solo imprimimos los datos al archivo CSV, sin texto extra
    imprimir_datos == 1 && $1 != "" {
        print atr1, atr2, atr3, atr4, $1, $2, $3, $4, $5, $6, $7
    }
    ' "$archivo_csv" > "$archivo_limpio"

    # 3. Carga directa a PostgreSQL
    echo "Cargando datos a la base de datos..."
    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "\copy $DB_TABLE FROM '$archivo_limpio' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');"
    ESTADO_CARGA=$?

    # 4. Limpieza final
    if [ $ESTADO_CARGA -eq 0 ]; then
        echo "¡Carga exitosa!"
        mv "$archivo_excel" "$DIR2/"
        rm "$archivo_csv"
        rm "$archivo_limpio"
    else
        echo "[$(date)] Error en DB al cargar: $archivo_limpio" >> /var/log/procesar_excel_errores.log
        echo "Error en la carga. Revisa el log de errores."
    fi

done

unset PGPASSWORD
