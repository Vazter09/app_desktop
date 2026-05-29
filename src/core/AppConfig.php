<?php
declare(strict_types=1);

require_once __DIR__ . '/ConfigSistemaDefaults.php';

/**
 * Configuración global del sistema (tab_config_sistema, id_config = 1).
 */
class AppConfig
{
    private static ?array $row = null;
    private static bool $booted = false;

    public static function boot(PDO $pdo, bool $includePassRegistroHash = true): void
    {
        if (self::$booted) {
            return;
        }

        try {
            $stmt = $pdo->query(
                ConfigSistemaDefaults::sqlSelectConfig($includePassRegistroHash) . ' LIMIT 1'
            );
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            self::$row = $row ?: null;
        } catch (PDOException) {
            self::$row = null;
        }

        self::$booted = true;
    }

    public static function reset(): void
    {
        self::$row = null;
        self::$booted = false;
    }

    public static function hasDbConfig(): bool
    {
        return self::$row !== null;
    }

    private static function get(string $key, mixed $fallback): mixed
    {
        if (self::$row !== null && array_key_exists($key, self::$row) && self::$row[$key] !== null && self::$row[$key] !== '') {
            return self::$row[$key];
        }
        return $fallback;
    }

    public static function nomSistema(): string
    {
        return (string) self::get('nom_sistema', 'SmartCSET');
    }

    public static function pathLogo(): string
    {
        return (string) self::get('path_logo', defined('PATH_LOGO') ? PATH_LOGO : 'img/logo-sena.png');
    }

    public static function colorPrimario(): string
    {
        return (string) self::get('color_primario', defined('COLOR_VERDE_OSCURO') ? COLOR_VERDE_OSCURO : '#2E4731');
    }

    public static function colorSecundario(): string
    {
        return (string) self::get('color_secundario', defined('COLOR_VERDE_OLIVA') ? COLOR_VERDE_OLIVA : '#6B8E23');
    }

    public static function moduloRegistroHabilitado(): bool
    {
        $v = self::get('ind_modulo_registro', true);
        return $v === true || $v === 't' || $v === '1' || $v === 1;
    }

    public static function loginRegistroStandalone(): bool
    {
        $v = self::get('ind_login_registro_standalone', false);
        return $v === true || $v === 't' || $v === '1' || $v === 1;
    }

    public static function usrRegistro(): ?string
    {
        $u = self::get('usr_registro', null);
        return $u !== null && $u !== '' ? (string) $u : null;
    }

    public static function passRegistroHash(): ?string
    {
        $h = self::get('pass_registro_hash', null);
        return $h !== null && $h !== '' ? (string) $h : null;
    }

    /** Tokens CSS modo oscuro (:root). */
    public static function themeTokensDark(): array
    {
        return array_merge([
            '--v-oscuro'       => self::colorPrimario(),
            '--v-oliva'        => self::colorSecundario(),
            '--bg-deep'        => (string) self::get('theme_bg_deep', '#020917'),
            '--bg-card'        => (string) self::get('theme_bg_card', '#060f24'),
            '--bg-panel'       => (string) self::get('theme_bg_panel', 'rgba(6, 15, 36, 0.85)'),
            '--cyan'           => (string) self::get('theme_accent', '#00e5b0'),
            '--cyan-dim'       => (string) self::get('theme_accent_dim', 'rgba(0, 245, 255, 0.15)'),
            '--teal'           => (string) self::get('theme_accent', '#00e5b0'),
            '--blue'           => (string) self::get('theme_blue', '#4a9eff'),
            '--purple'         => (string) self::get('theme_purple', '#9b6dff'),
            '--orange'         => (string) self::get('theme_orange', '#ff7b2e'),
            '--text-primary'   => (string) self::get('theme_text_primary', '#e8f4ff'),
            '--text-muted'     => (string) self::get('theme_text_muted', 'rgba(150,180,220,0.7)'),
            '--border'         => (string) self::get('theme_border', 'rgba(0,245,255,0.2)'),
            '--error'          => (string) self::get('theme_error', '#ff3c6e'),
            '--success'        => (string) self::get('theme_success', '#00e5b0'),
            '--theme-accent'   => (string) self::get('theme_accent', '#00e5b0'),
        ], self::sidebarThemeTokens());
    }

    /**
     * Variables CSS del sidebar derivadas de colores corporativos (Config. sistema).
     *
     * @return array<string, string>
     */
    public static function sidebarThemeTokens(): array
    {
        $primary = self::colorPrimario();
        $secondary = self::colorSecundario();

        return [
            '--sidebar-bg'     => self::darkenHex($primary, 0.58),
            '--sidebar-hover'  => self::hexToRgba($secondary, 0.18),
            '--sidebar-active' => self::hexToRgba($secondary, 0.35),
            '--sidebar-border' => self::hexToRgba($secondary, 0.25),
        ];
    }

    public static function hexToRgba(string $hex, float $alpha): string
    {
        [$r, $g, $b] = self::hexToRgb($hex);
        $alpha = max(0.0, min(1.0, $alpha));

        return sprintf('rgba(%d, %d, %d, %.2f)', $r, $g, $b, $alpha);
    }

    public static function darkenHex(string $hex, float $amount = 0.45): string
    {
        [$r, $g, $b] = self::hexToRgb($hex);
        $factor = 1.0 - max(0.0, min(1.0, $amount));

        return sprintf(
            '#%02x%02x%02x',
            (int) round($r * $factor),
            (int) round($g * $factor),
            (int) round($b * $factor)
        );
    }

    /** @return array{0: int, 1: int, 2: int} */
    private static function hexToRgb(string $hex): array
    {
        $normalized = self::normalizeHex($hex) ?? '#2e4731';

        return [
            hexdec(substr($normalized, 1, 2)),
            hexdec(substr($normalized, 3, 2)),
            hexdec(substr($normalized, 5, 2)),
        ];
    }

    private static function normalizeHex(string $hex): ?string
    {
        $hex = trim($hex);
        if ($hex === '') {
            return null;
        }
        if ($hex[0] !== '#') {
            $hex = '#' . $hex;
        }
        if (!preg_match('/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/', $hex, $m)) {
            return null;
        }
        if (strlen($m[1]) === 3) {
            $hex = '#' . $m[1][0] . $m[1][0] . $m[1][1] . $m[1][1] . $m[1][2] . $m[1][2];
        }

        return strtolower($hex);
    }

    /** Tokens para .light-theme. */
    public static function themeTokensLight(): array
    {
        return [
            '--bg-deep'      => (string) self::get('theme_light_bg_deep', '#f5f7fb'),
            '--bg-card'      => (string) self::get('theme_light_bg_card', '#ffffff'),
            '--cyan'         => (string) self::get('theme_light_accent', '#0b74c7'),
            '--text-primary' => (string) self::get('theme_light_text_primary', '#111827'),
            '--text-muted'   => (string) self::get('theme_light_text_muted', 'rgba(55,65,81,0.8)'),
        ];
    }

    public static function fontDisplay(): string
    {
        return (string) self::get('theme_font_display', 'Orbitron');
    }

    public static function fontBody(): string
    {
        return (string) self::get('theme_font_body', 'Rajdhani');
    }

    /** Fila completa para formulario admin. */
    public static function raw(): array
    {
        return self::$row ?? [];
    }
}
