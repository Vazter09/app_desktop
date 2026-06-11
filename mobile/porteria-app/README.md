# SmartCSET Portería — App tablet (Expo)

App Android para registro de ingreso/salida en portería. Se conecta a la API central de SmartCSET y guarda operaciones en cola local cuando no hay red.

## Requisitos

- Node.js 18+
- Expo CLI / EAS CLI para build APK
- Servidor SmartCSET accesible en la LAN del centro

## Configuración inicial

1. Instalar dependencias:

```bash
cd mobile/porteria-app
npm install
```

2. En el servidor, crear dispositivo y token:

```bash
php tools/generate_device_token.php "Tablet Portería 1" porteria 1
```

3. Ejecutar migración si aún no está aplicada:

```bash
psql -h HOST -U postgres -d db_smartcset -f database/migrations/add_tab_dispositivos_porteria.sql
```

4. Levantar app:

```bash
npm start
```

5. En la tablet (primera vez): URL del servidor, ej. `http://192.168.1.50:8080` y pegar el token.

## Build APK

```bash
npm install -g eas-cli
eas build -p android --profile preview
```

Perfil `preview` genera APK instalable sin Play Store.

## API base

`{SERVER_URL}/src/api/porteria/v1/`

Endpoints: `health.php`, `device/validate.php`, `catalogos.php`, `ingreso/*`, `salida/*`, `sync/batch.php`

## Offline

- Operaciones se guardan en SQLite local
- Sync automático cada 30s cuando `health` responde
- Pantalla **Pendientes** para reintentar fallidos
