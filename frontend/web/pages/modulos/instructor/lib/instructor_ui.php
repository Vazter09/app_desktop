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
