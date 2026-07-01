<?php
declare(strict_types=1);

/**
 * Helpers de presentación HTML del módulo instructor (no lógica de negocio).
 */

function instructorEtiquetaOrigen(string $origen): string
{
    return match ($origen) {
        'lider' => 'Líder',
        'programacion' => 'Transversal',
        'admin' => 'Administración',
        default => $origen,
    };
}

function instructorBadgeEstado(string $estado): string
{
    return match ($estado) {
        'Presente' => 'success',
        'Tarde' => 'warning',
        'Ausente' => 'danger',
        'Pendiente' => 'secondary',
        default => 'light text-dark',
    };
}

function instructorEstadosAsistenciaPermitidos(): array
{
    return ['Presente', 'Tarde', 'Ausente', 'Desconocido'];
}

/** Etiquetas del menú lateral solo para administrador. */
function instructorMenuLabelAdminPadre(): string
{
    return 'Asistencia';
}

function instructorMenuLabelAdminHijo(): string
{
    return 'Por carrera';
}

function instructorEsModoAdmin(array $ctx): bool
{
    return ($ctx['modo'] ?? '') === 'admin_lectura';
}

function instructorTituloListado(array $ctx, string $programaSel = ''): string
{
    if (!instructorEsModoAdmin($ctx)) {
        return 'Las fichas del instructor';
    }
    if ($programaSel !== '') {
        return $programaSel;
    }

    return 'Programas en ejecución';
}

function instructorSubtituloListado(array $ctx, string $programaSel = ''): string
{
    if (!instructorEsModoAdmin($ctx)) {
        return 'Seleccione una ficha para consultar la asistencia de sus aprendices.';
    }
    if ($programaSel !== '') {
        return 'Seleccione una ficha de este programa para consultar la asistencia.';
    }

    return 'Seleccione un programa para ver las fichas en ejecución.';
}

function instructorEtiquetaNavListado(array $ctx): string
{
    return instructorEsModoAdmin($ctx) ? 'Por carrera' : 'Mis Fichas';
}
