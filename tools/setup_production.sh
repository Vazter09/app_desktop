#!/bin/bash
# setup_production.sh - Script de configuración para producción
# Ejecutar: bash setup_production.sh

set -e  # Salir si hay error

echo "🔧 Configurando PRONOM para producción..."

# 1. Crear archivo .env
if [ ! -f .env ]; then
    echo "📝 Creando .env desde template..."
    cp .env.example .env
    echo "⚠️  EDITA .env con tus credenciales reales:"
    echo "   nano .env"
else
    echo "✅ .env ya existe"
fi

# 2. Crear directorio de logs
if [ ! -d logs ]; then
    echo "📁 Creando directorio logs/..."
    mkdir -p logs
    chmod 777 logs
else
    echo "✅ Directorio logs/ existe"
fi

# 3. Establecer permisos
echo "🔒 Estableciendo permisos..."
chmod 600 .env
chmod 755 src/ js/ css/ img/ scripts/
chmod 640 src/*.php
chmod 640 index.php

# 4. Verificar conexión a BD
echo "🔌 Verificando conexión a BD..."
# Crear script temporal de prueba
cat > test_connection.php << 'EOF'
<?php
require_once('src/prepare.php');
try {
    $pdo->query("SELECT 1");
    echo "✅ Conexión a BD exitosa\n";
} catch (Exception $e) {
    echo "❌ Error de conexión: " . $e->getMessage() . "\n";
    exit(1);
}
?>
EOF

php test_connection.php
rm test_connection.php

# 5. Resumen
echo ""
echo "=========================================="
echo "✅ CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Editar .env con credenciales reales"
echo "2. Verificar HTTPS está habilitado"
echo "3. Revisar logs/ después de primeros accesos"
echo "4. Eliminar debug_auth.php (si existe)"
echo ""
echo "Documentación: ver SECURITY.md"
echo "=========================================="
