<?php
/**
 * Lógica de enrolamiento e identificación facial (app de escritorio SGI).
 * Escritura/lectura vía funciones PostgreSQL
 * (prepare.php → $stmt_fun_guardar_enrolamiento_facial,
 * $stmt_fun_identificar_persona_por_rostro).
 *
 * El vector facial llega desde PHP como array de floats (JSON) y se
 * convierte al formato de texto que pgvector espera ('[v1,v2,...]')
 * antes de pasarlo al prepared statement — pgvector no tiene un tipo
 * nativo en PDO, pero acepta ese literal de texto con el cast ::VECTOR
 * ya puesto en el SQL preparado.
 */

/** Umbral de distancia coseno por defecto — ver REGLAS_APP_ESCRITORIO_SGI.md §10.5. */
const BIOMETRIA_UMBRAL_DISTANCIA_DEFAULT = 0.35;

/**
 * Dimensión esperada del vector facial (tab_personas.val_patron_facial /
 * tab_log_ingresos.facial_embedding). 128 = SFace (opencv_zoo).
 */
const BIOMETRIA_VECTOR_DIMENSION = 128;

/**
 * @param array<int, mixed> $embedding
 */
function biometriaValidarEmbedding(array $embedding): void
{
    if (count($embedding) !== BIOMETRIA_VECTOR_DIMENSION) {
        throw new InvalidArgumentException(
            'El vector facial debe tener ' . BIOMETRIA_VECTOR_DIMENSION . ' dimensiones.'
        );
    }
    foreach ($embedding as $v) {
        if (!is_numeric($v)) {
            throw new InvalidArgumentException('El vector facial contiene valores no numéricos.');
        }
    }
}

/**
 * @param array<int, mixed> $embedding
 */
function biometriaEmbeddingATexto(array $embedding): string
{
    biometriaValidarEmbedding($embedding);

    return '[' . implode(',', array_map(static fn($v): string => (string) (float) $v, $embedding)) . ']';
}

/**
 * Enrola un rostro para una persona ya registrada.
 *
 * @param array<int, mixed> $embedding
 * @param string|null $rutaFoto Ruta relativa a la foto de enrolamiento
 * @return int id_persona actualizado (compat: antes id_enrolamiento)
 */
function biometriaGuardarEnrolamiento(
    PDOStatement $stmtGuardar,
    int $idPersona,
    array $embedding,
    ?float $calidadFacial = null,
    ?string $rutaFoto = null
): int {
    $vectorTexto = biometriaEmbeddingATexto($embedding);

    $stmtGuardar->execute([$idPersona, $vectorTexto, $calidadFacial, $rutaFoto]);

    $id = $stmtGuardar->fetchColumn();

    return $id !== false ? (int) $id : $idPersona;
}

/**
 * Identifica a la persona dueña de un rostro capturado.
 *
 * @param array<int, mixed> $embedding
 * @return int|null id_persona si hay match dentro del umbral, NULL si no
 */
function biometriaIdentificarPersona(
    PDOStatement $stmtIdentificar,
    array $embedding,
    float $umbralDistancia = BIOMETRIA_UMBRAL_DISTANCIA_DEFAULT
): ?int {
    $vectorTexto = biometriaEmbeddingATexto($embedding);

    $stmtIdentificar->execute([$vectorTexto, $umbralDistancia]);
    $resultado = $stmtIdentificar->fetchColumn();

    return $resultado !== null && $resultado !== false ? (int) $resultado : null;
}
