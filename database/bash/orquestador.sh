#!/bin/bash
set -euo pipefail

# ==========================================
# ORQUESTADOR DE CARGAS - VERSIÓN CORREGIDA
# ==========================================

BASE_DIR="/home/adsocset/carga_planos"
CONFIG_DIR="$BASE_DIR/config"
LOG_DIR="$BASE_DIR/logs"
ORDEN_FILE="$CONFIG_DIR/orden.conf"
GLOBAL_LOG="$LOG_DIR/orquestador_$(date +%Y%m%d).log"
LOCK_FILE="/tmp/orquestador_carga.lock"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ==========================================
# FUNCIONES
# ==========================================

log() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $msg" | tee -a "$GLOBAL_LOG"
}

log_info() { log "INFO" "$1"; }
log_error() { log "ERROR" "$1" >&2; }
log_success() { log "SUCCESS" "$1"; }

check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_error "Ya hay un proceso en ejecución (PID $pid). Abortando."
            exit 1
        else
            log_info "Lock file antiguo encontrado. Eliminando."
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
    log_info "Lock file creado (PID $$)."
}

release_lock() {
    rm -f "$LOCK_FILE"
    log_info "Lock file eliminado."
}

mostrar_ayuda() {
    cat << EOF
Uso: $0 [OPCIONES]

Opciones:
  -h, --help      Muestra esta ayuda
  -l, --list      Muestra el orden actual de ejecución
  -f, --file FILE Usa un archivo de orden alternativo

El orden de ejecución se define en: $ORDEN_FILE
Cada línea debe contener la RUTA ABSOLUTA al script.
EOF
}

mostrar_orden() {
    echo "Orden actual de ejecución (rutas absolutas):"
    local i=1
    while IFS= read -r script || [ -n "$script" ]; do
        [[ -z "$script" || "$script" =~ ^[[:space:]]*# ]] && continue
        echo "  $i. $script"
        ((i++))
    done < "$ORDEN_FILE"
}

cargar_orden() {
    local orden_file="${1:-$ORDEN_FILE}"
    if [ ! -f "$orden_file" ]; then
        log_error "Archivo de orden no encontrado: $orden_file"
        exit 1
    fi
    SCRIPTS=()
    while IFS= read -r script || [ -n "$script" ]; do
        script="$(echo "$script" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -z "$script" || "$script" =~ ^# ]] && continue
        SCRIPTS+=("$script")
    done < "$orden_file"
    if [ ${#SCRIPTS[@]} -eq 0 ]; then
        log_error "El archivo de orden está vacío o solo contiene comentarios."
        exit 1
    fi
    log_info "Cargados ${#SCRIPTS[@]} scripts desde $orden_file"
}

# ==========================================
# MAIN
# ==========================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) mostrar_ayuda; exit 0 ;;
        -l|--list) mostrar_orden; exit 0 ;;
        -f|--file) ORDEN_FILE="$2"; shift 2 ;;
        *) echo "Opción desconocida: $1"; mostrar_ayuda; exit 1 ;;
    esac
done

mkdir -p "$CONFIG_DIR" "$LOG_DIR"

if [ ! -f "$ORDEN_FILE" ]; then
    log_info "Creando archivo de orden por defecto..."
    cat > "$ORDEN_FILE" << 'EOF'
# Orden de ejecución (rutas absolutas)
/home/adsocset/carga_planos/PE04/proceso_carga_pe04.sh
/home/adsocset/carga_planos/matriculados/proceso_carga_aprendiz.sh
/home/adsocset/carga_planos/fichas_creadas/proceso_carga_fichas_creadas.sh
/home/adsocset/carga_planos/DF49/proceso_carga_df49.sh
/home/adsocset/carga_planos/DF14A/proceso_carga_df14a.sh
/home/adsocset/carga_planos/DF53/proceso_carga_df53.sh
/home/adsocset/carga_planos/DF51/proceso_carga_df51.sh
/home/adsocset/carga_planos/juicios/proceso_carga_juicios.sh
EOF
fi

cargar_orden "$ORDEN_FILE"

for script_path in "${SCRIPTS[@]}"; do
    if [ ! -x "$script_path" ]; then
        log_error "Script no encontrado o no ejecutable: $script_path"
        log_error "Asegúrate de que exista y tenga permisos de ejecución (chmod +x)"
        exit 1
    fi
done

check_lock

declare -A RESULTADOS
FAILED=0
SUCCESS=0

log_info "=== INICIO ORQUESTADOR ==="
log_info "Ejecutando ${#SCRIPTS[@]} scripts en el orden definido en $ORDEN_FILE"

for script_path in "${SCRIPTS[@]}"; do
    script_name=$(basename "$script_path")
    script_dir=$(dirname "$script_path")
    
    log_info "--- Ejecutando $script_name (desde $script_dir) ---"
    start_time=$(date +%s)
    
    set +e
    (cd "$script_dir" && ./"$script_name") 2>&1 | tee -a "$GLOBAL_LOG"
    exit_code=${PIPESTATUS[0]}
    set -e
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    if [ $exit_code -eq 0 ]; then
        log_success "$script_name finalizado correctamente (${duration}s)"
        RESULTADOS["$script_name"]="OK"
        SUCCESS=$((SUCCESS + 1))
    else
        log_error "$script_name falló con código $exit_code después de ${duration}s"
        RESULTADOS["$script_name"]="FAIL"
        FAILED=$((FAILED + 1))
        # Si quieres abortar en el primer fallo, descomenta:
        # log_error "Abortando por fallo en $script_name"
        # release_lock
        # exit 1
    fi
done

log_info "=== RESUMEN FINAL ==="
log_info "Total scripts: ${#SCRIPTS[@]}"
log_info "Exitosos: $SUCCESS"
log_info "Fallidos: $FAILED"

for script_name in "${!RESULTADOS[@]}"; do
    if [ "${RESULTADOS[$script_name]}" = "OK" ]; then
        echo -e "${GREEN}✅ $script_name${NC}" | tee -a "$GLOBAL_LOG"
    else
        echo -e "${RED}❌ $script_name${NC}" | tee -a "$GLOBAL_LOG"
    fi
done

log_info "=== FIN ORQUESTADOR ==="
release_lock

if [ $FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi