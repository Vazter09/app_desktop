-- Índice para acelerar el listado de aprendices.
-- La PK de tab_aprendices_fichas es (id_ficha, id_aprendiz); con id_ficha primero
-- NO sirve para buscar por id_aprendiz. El listado de aprendices usa un LATERAL
-- (WHERE af.id_aprendiz = p.id_persona ORDER BY fec_insert DESC, id_ficha DESC LIMIT 1)
-- que sin este índice hace seq scan completo de la tabla una vez por aprendiz (O(n²)).
-- Con ~7.4k filas el COUNT del listado tardaba ~9.6 s (página completa ~1 min).
-- El orden de columnas coincide con el WHERE + ORDER BY del LATERAL para resolverlo
-- como una sola lectura indexada por aprendiz.

CREATE INDEX IF NOT EXISTS idx_aprendices_fichas_aprendiz
    ON tab_aprendices_fichas (id_aprendiz, fec_insert DESC NULLS LAST, id_ficha DESC);

COMMENT ON INDEX idx_aprendices_fichas_aprendiz IS
    'Ficha más reciente por aprendiz (listado admin de aprendices). Evita seq scan O(n²) en el LATERAL.';
