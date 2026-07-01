-- Seed de desarrollo: fila única de parámetros generales para el primer centro disponible.
-- Idempotente. Requiere al menos un registro en tab_centros.

INSERT INTO tab_pmtros_grales (
    id_centro,
    dir_centro,
    tel_centro,
    ano_academico,
    mes_academico,
    nom_administrador,
    tel_administrador
)
SELECT c.id_centro,
       'Sin dirección',
       6010000000,
       EXTRACT(YEAR FROM CURRENT_DATE)::DECIMAL(4, 0),
       EXTRACT(MONTH FROM CURRENT_DATE)::DECIMAL(2, 0),
       'Sin Administrador',
       6010000000
  FROM tab_centros c
 ORDER BY c.id_centro
 LIMIT 1
ON CONFLICT (id_centro) DO NOTHING;
