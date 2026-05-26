<?php
declare(strict_types=1);

/**
 * Valores por defecto de tab_config_sistema (ver database/migrations/add_tab_config_sistema.sql).
 */
class ConfigSistemaDefaults
{
    public const SECTION_GENERAL   = 'general';
    public const SECTION_THEME_DARK  = 'theme_dark';
    public const SECTION_THEME_LIGHT = 'theme_light';

    /** @return array<string, mixed> */
    public static function values(): array
    {
        return [
            'ind_modulo_registro'           => true,
            'ind_login_registro_standalone' => false,
            'nom_sistema'                   => 'SmartCSET',
            'path_logo'                     => 'img/logo_empresa.png',
            'color_primario'                => '#2E4731',
            'color_secundario'              => '#6B8E23',
            'theme_bg_deep'                 => '#020917',
            'theme_bg_card'                 => '#060f24',
            'theme_bg_panel'                => 'rgba(6, 15, 36, 0.85)',
            'theme_accent'                  => '#00e5b0',
            'theme_accent_dim'              => 'rgba(0, 245, 255, 0.15)',
            'theme_blue'                    => '#4a9eff',
            'theme_purple'                  => '#9b6dff',
            'theme_orange'                  => '#ff7b2e',
            'theme_text_primary'            => '#e8f4ff',
            'theme_text_muted'              => 'rgba(150,180,220,0.7)',
            'theme_border'                  => 'rgba(0,245,255,0.2)',
            'theme_error'                   => '#ff3c6e',
            'theme_success'                 => '#00e5b0',
            'theme_font_display'            => 'Orbitron',
            'theme_font_body'               => 'Rajdhani',
            'theme_light_bg_deep'           => '#f5f7fb',
            'theme_light_bg_card'           => '#ffffff',
            'theme_light_accent'            => '#0b74c7',
            'theme_light_text_primary'      => '#111827',
            'theme_light_text_muted'        => 'rgba(55,65,81,0.8)',
            'usr_registro'                  => 'usuariocset',
        ];
    }

    /** @return array<string, list<string>> */
    public static function sectionKeys(): array
    {
        return [
            self::SECTION_GENERAL => [
                'ind_modulo_registro',
                'ind_login_registro_standalone',
                'nom_sistema',
                'path_logo',
                'color_primario',
                'color_secundario',
                'usr_registro',
            ],
            self::SECTION_THEME_DARK => [
                'theme_bg_deep',
                'theme_bg_card',
                'theme_bg_panel',
                'theme_accent',
                'theme_accent_dim',
                'theme_blue',
                'theme_purple',
                'theme_orange',
                'theme_text_primary',
                'theme_text_muted',
                'theme_border',
                'theme_error',
                'theme_success',
                'theme_font_display',
                'theme_font_body',
            ],
            self::SECTION_THEME_LIGHT => [
                'theme_light_bg_deep',
                'theme_light_bg_card',
                'theme_light_accent',
                'theme_light_text_primary',
                'theme_light_text_muted',
            ],
        ];
    }

    /**
     * Fusiona defaults de una sección sobre la fila actual.
     *
     * @param array<string, mixed> $current
     * @return array<string, mixed>
     */
    public static function applySection(array $current, string $section): array
    {
        $sections = self::sectionKeys();
        if (!isset($sections[$section])) {
            throw new InvalidArgumentException('Sección de restauración no válida.');
        }

        $defaults = self::values();
        $merged = $current;
        foreach ($sections[$section] as $key) {
            if (array_key_exists($key, $defaults)) {
                $merged[$key] = $defaults[$key];
            }
        }

        return $merged;
    }

    public static function sectionLabel(string $section): string
    {
        return match ($section) {
            self::SECTION_GENERAL   => 'sección general',
            self::SECTION_THEME_DARK  => 'tema oscuro',
            self::SECTION_THEME_LIGHT => 'tema claro',
            default => 'sección',
        };
    }

    /**
     * @param array<string, mixed> $row
     * @return list<mixed>
     */
    public static function toUpdateParamsFromRow(array $row, string $usrUpdate, ?string $passRegistroHash = null): array
    {
        $bool = static function ($v): string {
            return ($v === true || $v === 't' || $v === '1' || $v === 1) ? 'true' : 'false';
        };

        return [
            $bool($row['ind_modulo_registro'] ?? true),
            $bool($row['ind_login_registro_standalone'] ?? false),
            (string) ($row['nom_sistema'] ?? 'SmartCSET'),
            (string) ($row['path_logo'] ?? 'img/logo_empresa.png'),
            (string) ($row['color_primario'] ?? '#2E4731'),
            (string) ($row['color_secundario'] ?? '#6B8E23'),
            (string) ($row['theme_bg_deep'] ?? '#020917'),
            (string) ($row['theme_bg_card'] ?? '#060f24'),
            (string) ($row['theme_bg_panel'] ?? 'rgba(6, 15, 36, 0.85)'),
            (string) ($row['theme_accent'] ?? '#00e5b0'),
            (string) ($row['theme_accent_dim'] ?? 'rgba(0, 245, 255, 0.15)'),
            (string) ($row['theme_blue'] ?? '#4a9eff'),
            (string) ($row['theme_purple'] ?? '#9b6dff'),
            (string) ($row['theme_orange'] ?? '#ff7b2e'),
            (string) ($row['theme_text_primary'] ?? '#e8f4ff'),
            (string) ($row['theme_text_muted'] ?? 'rgba(150,180,220,0.7)'),
            (string) ($row['theme_border'] ?? 'rgba(0,245,255,0.2)'),
            (string) ($row['theme_error'] ?? '#ff3c6e'),
            (string) ($row['theme_success'] ?? '#00e5b0'),
            (string) ($row['theme_font_display'] ?? 'Orbitron'),
            (string) ($row['theme_font_body'] ?? 'Rajdhani'),
            (string) ($row['theme_light_bg_deep'] ?? '#f5f7fb'),
            (string) ($row['theme_light_bg_card'] ?? '#ffffff'),
            (string) ($row['theme_light_accent'] ?? '#0b74c7'),
            (string) ($row['theme_light_text_primary'] ?? '#111827'),
            (string) ($row['theme_light_text_muted'] ?? 'rgba(55,65,81,0.8)'),
            (string) ($row['usr_registro'] ?? 'usuariocset'),
            $passRegistroHash,
            $usrUpdate,
        ];
    }

    /**
     * @return list<mixed>
     */
    public static function toUpdateParams(string $usrUpdate, ?string $passRegistroHash = null): array
    {
        return self::toUpdateParamsFromRow(self::values(), $usrUpdate, $passRegistroHash);
    }
}
