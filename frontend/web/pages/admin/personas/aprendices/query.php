<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/lib/query_shared.php';
require_once dirname(__DIR__) . '/lib/listado_config.php';
require_once dirname(__DIR__, 6) . '/backend/services/registro/catalogos.php';

/** @return list<array<string, mixed>> */
function personasListadoAprendicesFiltrosFields(PDO $pdo): array
{
    $fields = personasListadoFiltrosFields();
    $options = ['' => 'Todas'];

    foreach (registroGetFichasParaListadoAdmin($pdo) as $ficha) {
        $idFicha = trim((string) ($ficha['id_ficha'] ?? ''));
        if ($idFicha === '') {
            continue;
        }

        $nomPrograma = trim((string) ($ficha['nom_programa'] ?? ''));
        $options[$idFicha] = $nomPrograma !== ''
            ? $idFicha . ' — ' . $nomPrograma
            : $idFicha;
    }

    $fichaField = [
        'name' => 'id_ficha',
        'label' => 'Ficha',
        'type' => 'select',
        'col' => 'col-md-3',
        'options' => $options,
    ];

    array_splice($fields, 1, 0, [$fichaField]);

    return $fields;
}

/**
 * @param array<string, mixed> $filters
 * @return array{rows: list<array<string, mixed>>, total: int, page: int, per_page: int, total_pages: int, from: int, to: int}
 */
function personasListadoFetchAprendices(PDO $pdo, array $filters = []): array
{
    $extensions = [
        'join_sql' => "
            LEFT JOIN LATERAL (
                SELECT af.id_ficha
                  FROM tab_aprendices_fichas af
                 WHERE af.id_aprendiz = p.id_persona
                 ORDER BY af.fec_insert DESC NULLS LAST, af.id_ficha DESC
                 LIMIT 1
            ) af ON TRUE
            LEFT JOIN tab_fichas fi ON fi.id_ficha = af.id_ficha
            LEFT JOIN tab_programas pr ON pr.id_programa = fi.id_programa",
        'select_extra' => ",
            af.id_ficha,
            COALESCE(pr.nom_programa, '') AS nom_programa",
        'search_extra' => 'OR CAST(af.id_ficha AS TEXT) ILIKE :q',
        'map_row' => 'personasMapAprendizListadoRow',
    ];

    $idFicha = personasListadoResolveIdFicha($filters);
    if ($idFicha !== null) {
        $extensions['where_extra'] = 'EXISTS (
            SELECT 1
              FROM tab_aprendices_fichas af_filt
             WHERE af_filt.id_aprendiz = p.id_persona
               AND af_filt.id_ficha = :id_ficha
        )';
        $extensions['where_params'] = [':id_ficha' => $idFicha];
    }

    return personasListadoFetchPorTipo($pdo, 'Aprendiz', $filters, $extensions);
}

/** @return list<array<string, mixed>> */
function personasListadoAprendicesColumnas(): array
{
    $columns = personasListadoTablaColumnas();
    array_splice($columns, 2, 0, [[
        'key' => 'ficha',
        'label' => 'Ficha',
        'td_class' => 'py-2 text-truncate',
        'truncate' => 260,
        'title_from' => 'ficha',
    ]]);

    return $columns;
}

/**
 * @param array<string, mixed> $r
 * @return array<string, mixed>
 */
function personasMapAprendizListadoRow(array $r): array
{
    $row = registroMapPersonaRow($r);

    $idFicha = trim((string) ($r['id_ficha'] ?? ''));
    $nomPrograma = trim((string) ($r['nom_programa'] ?? ''));

    $row['id_ficha'] = $idFicha;
    $row['ficha'] = $idFicha !== ''
        ? ($idFicha . ($nomPrograma !== '' ? ' — ' . $nomPrograma : ''))
        : '—';

    return $row;
}
