<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/admin/personas/lib/tipo_id.php';

function registroResolveTipoPersonaId(PDO $pdo, string $nomTipo): int
{
    return personasResolveTipoId($pdo, $nomTipo);
}

function registroGetTiposDocumento(PDO $pdo): array
{
    $stmt = $pdo->query('SELECT id_tipo_docum, nom_tipo_docum FROM tab_tipos_docum ORDER BY nom_tipo_docum');
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function registroGetTiposPersona(PDO $pdo): array
{
    $stmt = $pdo->query('SELECT id_tipo_persona, nom_tipo_persona FROM tab_tipos_persona ORDER BY nom_tipo_persona');
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function registroGetNivelesEstudio(PDO $pdo): array
{
    $stmt = $pdo->query('SELECT id_nivel_estudio, nom_nivel_estudio FROM tab_niveles_estudio ORDER BY nom_nivel_estudio');
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function registroGetProfesiones(PDO $pdo): array
{
    $stmt = $pdo->query('SELECT id_profesion, nom_profesion FROM tab_profesiones ORDER BY nom_profesion');
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function registroGetDepartamentos(PDO $pdo): array
{
    $stmt = $pdo->query('SELECT id_dpto, nom_dpto FROM tab_dptos ORDER BY nom_dpto');
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function registroGetCiudadesByDpto(PDO $pdo, string $idDpto): array
{
    $stmt = $pdo->prepare(
        'SELECT id_ciudad, nom_ciudad FROM tab_ciudades WHERE id_dpto = :id_dpto ORDER BY nom_ciudad'
    );
    $stmt->execute([':id_dpto' => $idDpto]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function registroGetCentros(PDO $pdo): array
{
    $stmt = $pdo->query('SELECT id_centro, nom_centro FROM tab_centros ORDER BY nom_centro');
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function registroGetRedes(PDO $pdo): array
{
    $stmt = $pdo->query('SELECT id_red, nom_red FROM tab_redes ORDER BY nom_red');
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function registroGetAreas(PDO $pdo): array
{
    $stmt = $pdo->query(
        'SELECT a.id_area,
                a.nom_area,
                a.id_centro,
                c.nom_centro,
                a.id_area::TEXT || \' — \' || a.nom_area
                    || COALESCE(\' (\' || c.nom_centro || \')\', \'\') AS etiqueta
           FROM tab_areas a
           LEFT JOIN tab_centros c ON c.id_centro = a.id_centro
          ORDER BY a.nom_area, a.id_area'
    );
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function registroGetCargos(PDO $pdo): array
{
    $stmt = $pdo->query(
        'SELECT id_cargo,
                nom_cargo,
                id_cargo::TEXT || \' — \' || nom_cargo AS etiqueta
           FROM tab_cargos
          ORDER BY nom_cargo, id_cargo'
    );
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function registroGetFichas(PDO $pdo): array
{
    $stmt = $pdo->query(
        'SELECT f.id_ficha,
                f.id_programa,
                f.id_centro,
                p.nom_programa,
                c.nom_centro,
                f.id_ficha::TEXT
                    || COALESCE(\' — \' || p.nom_programa, \'\')
                    || COALESCE(\' (\' || c.nom_centro || \')\', \'\') AS etiqueta
           FROM tab_fichas f
           LEFT JOIN tab_programas p ON p.id_programa = f.id_programa
           LEFT JOIN tab_centros c ON c.id_centro = f.id_centro
          WHERE f.ind_abierta = TRUE
          ORDER BY f.id_ficha'
    );
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}
