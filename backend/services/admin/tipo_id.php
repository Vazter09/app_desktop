<?php
declare(strict_types=1);

function personasResolveTipoId(PDO $pdo, string $tipoName): int
{
    $tipoName = trim($tipoName);
    if ($tipoName === '') {
        return 0;
    }

    try {
        $stmt = $pdo->prepare(
            'SELECT id_tipo_persona FROM tab_tipos_persona WHERE lower(nom_tipo_persona) = lower(:n) LIMIT 1'
        );
        $stmt->execute([':n' => $tipoName]);

        return (int) ($stmt->fetchColumn() ?: 0);
    } catch (PDOException) {
        return 0;
    }
}
