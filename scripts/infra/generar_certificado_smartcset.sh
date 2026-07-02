#!/bin/bash
#
# generar_certificado_smartcset.sh
#
# Genera un certificado TLS autofirmado (ECDSA P-256, 365 días) para
# SmartCSET y lo instala en el directorio de certificados de Apache.
#
# Reproduce exactamente los pasos ejecutados manualmente en el servidor de
# producción (10.5.213.103) el 2026-06-17 para cerrar E1-A02 (HTTPS forzado).
# Ver: "Documentacion para implementacion de MSPI/FASE 01_Blindaje Técnico
# Inmediato/REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES_SMARTCSET.md" v3.0
#
# Uso: sudo ./generar_certificado_smartcset.sh
#
# Requiere: openssl, permisos sudo, módulo Apache mod_ssl habilitado
# (sudo a2enmod ssl) y el VirtualHost smartcset-ssl.conf ya configurado.

set -e

CERT_DIR="/etc/apache2/certs"
CERT_FILE="$CERT_DIR/smartcset.crt"
KEY_FILE="$CERT_DIR/smartcset.key"
DAYS_VALID=365
SUBJECT="/C=CO/ST=Cundinamarca/L=Bogota/O=SENA/CN=smartcset.local"

if [ "$EUID" -ne 0 ]; then
    echo "[!] Este script debe ejecutarse con sudo: sudo $0"
    exit 1
fi

echo "[*] Creando directorio de certificados (si no existe)..."
mkdir -p "$CERT_DIR"
chmod 755 "$CERT_DIR"

if [ -f "$CERT_FILE" ] || [ -f "$KEY_FILE" ]; then
    echo "[!] Ya existe un certificado en $CERT_DIR."
    read -p "    ¿Sobrescribir? (s/N): " confirm
    if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
        echo "[*] Cancelado por el usuario."
        exit 0
    fi
fi

echo "[*] Generando clave privada ECDSA P-256..."
openssl ecparam -name prime256v1 -genkey -noout -out "$KEY_FILE"

echo "[*] Generando certificado X.509 autofirmado (válido $DAYS_VALID días)..."
openssl req -new -x509 \
    -key "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days "$DAYS_VALID" \
    -subj "$SUBJECT"

echo "[*] Fijando permisos..."
chmod 644 "$CERT_FILE"
chmod 600 "$KEY_FILE"

echo ""
echo "[✓] Certificado generado correctamente:"
echo "    Certificado: $CERT_FILE"
echo "    Clave privada: $KEY_FILE"
echo "    Válido por: $DAYS_VALID días"
echo ""
openssl x509 -in "$CERT_FILE" -noout -dates -subject

echo ""
echo "[!] PRÓXIMOS PASOS (si es la primera instalación):"
echo "    1. sudo a2enmod ssl"
echo "    2. Verificar/crear el VirtualHost en"
echo "       /etc/apache2/sites-available/smartcset-ssl.conf"
echo "       apuntando a $CERT_FILE y $KEY_FILE"
echo "    3. sudo a2ensite smartcset-ssl"
echo "    4. sudo systemctl restart apache2"
echo ""
echo "[!] RECORDATORIO: este certificado vence en $DAYS_VALID días."
echo "    Vuelve a ejecutar este script antes de esa fecha para renovarlo."
