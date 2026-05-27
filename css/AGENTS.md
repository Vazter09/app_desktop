# AGENTS.md — css/

## Propósito

11 archivos CSS que estilizan la aplicación. Bootstrap 5.3 via CDN + CSS personalizado. No hay build step, preprocesador ni minificación.

---

## Archivos

| Archivo | Propósito |
|---|---|
| `style.css` | Estilos base globales |
| `components.css` | Componentes reutilizables (badges, alertas, botones) |
| `layout.css` | Estructura principal (sidebar, topbar, contenido) |
| `style_crud.css` | Tablas, formularios CRUD, modales |
| `style_menu_principal.css` | Dashboard de bienvenida y tarjetas |
| `registro.css` | Tema oscuro sci-fi del módulo registro |
| `registro-listado-admin.css` | Tabla de listado administrativo |
| `menu_usuarios.css` | Interfaz de asignación de menús |
| `modulos_ingresos.css` | Formulario de ingreso |
| `modulos_salidas.css` | Formulario de salida |
| `porteria_modos.css` | Barra de modos escáner/foto |

---

## Convenciones

- **Variables CSS nunca hardcodeadas:** usar `var(--v-oscuro)`, `var(--v-oliva)` inyectadas por `theme_vars.php`
- **Bootstrap 5.3 clases:** reutilizar clases Bootstrap en lugar de CSS custom
- **Ningún preprocesador:** solo CSS vanilla, sin Sass/Less
- **Sin minificación:** los archivos se incluyen como-están

---

## Variables CSS disponibles

Inyectadas por `theme_vars.php` en `<head>`:
```css
--v-oscuro       /* Color verde oscuro corporativo */
--v-oliva        /* Color verde oliva corporativo */
--cyan           /* Color cyan para acentos */
/* Y más según tema */
```

---

## Dependencias

- Bootstrap 5.3 via CDN en `layout/head.php`
- Bootstrap Icons via CDN en `layout/head.php`
- `theme_vars.php` inyecta variables CSS

---

## Qué NO tocar sin entender primero

- No codear colores corporativos directamente — usar variables CSS
- No crear estilos inline en HTML — todo va en CSS
- No usar preprocesadores — la infraestructura no lo soporta
- Los nombres de archivos siguen patrón `modulo_seccion.css` — mantener consistencia
