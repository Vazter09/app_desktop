<?php
declare(strict_types=1);

/**
 * Valores por defecto de tab_pmtros_grales (parámetros generales del centro).
 */
class PmtrosGralesDefaults
{
    public static function sqlSelect(): string
    {
        return 'SELECT p.id_centro,
                       p.dir_centro,
                       p.tel_centro,
                       p.ano_academico,
                       p.mes_academico,
                       p.val_nota_minima_rap,
                       p.num_horas_instructor,
                       p.val_porcent_icfes_raps,
                       p.val_tiempo_gracia_aprendiz,
                       p.val_tiempo_gracia_instru,
                       p.val_max_llamados_aprendiz,
                       p.nom_administrador,
                       p.tel_administrador,
                       c.nom_centro
                  FROM tab_pmtros_grales p
            INNER JOIN tab_centros c ON c.id_centro = p.id_centro
              ORDER BY p.id_centro
                 LIMIT 1';
    }

    /** @return array<string, mixed> */
    public static function values(): array
    {
        return [
            'dir_centro'                 => 'Sin dirección',
            'tel_centro'                 => 6010000000,
            'ano_academico'              => (int) date('Y'),
            'mes_academico'              => (int) date('n'),
            'val_nota_minima_rap'        => 71,
            'num_horas_instructor'       => 160,
            'val_porcent_icfes_raps'     => 75,
            'val_tiempo_gracia_aprendiz' => 0,
            'val_tiempo_gracia_instru'   => 0,
            'val_max_llamados_aprendiz'  => 3,
            'nom_administrador'          => 'Sin Administrador',
            'tel_administrador'          => 6010000000,
        ];
    }

    /**
     * @param array<string, mixed> $row
     * @return list<mixed>
     */
    public static function toUpdateParamsFromRow(array $row, string $usrUpdate): array
    {
        $defaults = self::values();

        return [
            $row['id_centro'] ?? null,
            (string) ($row['dir_centro'] ?? $defaults['dir_centro']),
            (int) ($row['tel_centro'] ?? $defaults['tel_centro']),
            (int) ($row['ano_academico'] ?? $defaults['ano_academico']),
            (int) ($row['mes_academico'] ?? $defaults['mes_academico']),
            (int) ($row['val_nota_minima_rap'] ?? $defaults['val_nota_minima_rap']),
            (int) ($row['num_horas_instructor'] ?? $defaults['num_horas_instructor']),
            (int) ($row['val_porcent_icfes_raps'] ?? $defaults['val_porcent_icfes_raps']),
            (int) ($row['val_tiempo_gracia_aprendiz'] ?? $defaults['val_tiempo_gracia_aprendiz']),
            (int) ($row['val_tiempo_gracia_instru'] ?? $defaults['val_tiempo_gracia_instru']),
            (int) ($row['val_max_llamados_aprendiz'] ?? $defaults['val_max_llamados_aprendiz']),
            (string) ($row['nom_administrador'] ?? $defaults['nom_administrador']),
            (int) ($row['tel_administrador'] ?? $defaults['tel_administrador']),
            $usrUpdate,
        ];
    }

    /**
     * @param array<string, mixed> $current
     * @return array<string, mixed>
     */
    public static function applyDefaults(array $current): array
    {
        $merged = $current;
        foreach (self::values() as $key => $value) {
            $merged[$key] = $value;
        }

        return $merged;
    }

    /**
     * @param array<string, string> $post
     * @param array<string, mixed> $current
     * @return array<string, mixed>
     */
    public static function rowFromPost(array $post, array $current): array
    {
        $row = $current;
        $row['id_centro'] = (int) ($post['txt_id_centro'] ?? $current['id_centro'] ?? 0);
        $row['dir_centro'] = trim((string) ($post['txt_dir_centro'] ?? ''));
        $row['tel_centro'] = (int) ($post['txt_tel_centro'] ?? 0);
        $row['ano_academico'] = (int) ($post['num_ano_academico'] ?? 0);
        $row['mes_academico'] = (int) ($post['num_mes_academico'] ?? 0);
        $row['val_nota_minima_rap'] = (int) ($post['num_nota_minima_rap'] ?? 0);
        $row['num_horas_instructor'] = (int) ($post['num_horas_instructor'] ?? 0);
        $row['val_porcent_icfes_raps'] = (int) ($post['num_porcent_icfes_raps'] ?? 0);
        $row['val_tiempo_gracia_aprendiz'] = (int) ($post['num_tiempo_gracia_aprendiz'] ?? 0);
        $row['val_tiempo_gracia_instru'] = (int) ($post['num_tiempo_gracia_instru'] ?? 0);
        $row['val_max_llamados_aprendiz'] = (int) ($post['num_max_llamados_aprendiz'] ?? 0);
        $row['nom_administrador'] = trim((string) ($post['txt_nom_administrador'] ?? ''));
        $row['tel_administrador'] = (int) ($post['txt_tel_administrador'] ?? 0);

        return $row;
    }
}
