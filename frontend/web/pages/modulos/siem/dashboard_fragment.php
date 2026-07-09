<?php
declare(strict_types=1);

/**
 * Fragmento reutilizable del panel de control SIEM: se incluye tanto en el
 * render completo (index.php) como en la respuesta parcial (?partial=1) que
 * consume el auto-refresh vía SmartcsetListado.loadIntoHost().
 * Requiere $kpis, $top_ips, $alertas, $w_mensaje, $w_tipo_alerta ya definidos.
 */
?>
<?php if ($w_mensaje !== ''): ?>
    <?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>
<?php endif; ?>

<div class="container-fluid py-3 px-3">

    <!-- KPIs -->
    <div class="row g-3 mb-3">

        <div class="col-6 col-md-3">
            <div class="siem-kpi-card p-3">
                <div class="d-flex align-items-center gap-2 mb-1">
                    <span class="siem-kpi-icon text-info"><i class="bi bi-shield-check"></i></span>
                    <span class="siem-kpi-label">Intentos hoy</span>
                </div>
                <div class="siem-kpi-value"><?= (int) $kpis['total_intentos_hoy'] ?></div>
            </div>
        </div>

        <div class="col-6 col-md-3">
            <div class="siem-kpi-card p-3">
                <div class="d-flex align-items-center gap-2 mb-1">
                    <span class="siem-kpi-icon text-danger"><i class="bi bi-x-circle"></i></span>
                    <span class="siem-kpi-label">Fallos hoy</span>
                </div>
                <div class="siem-kpi-value text-danger"><?= (int) $kpis['fallos_hoy'] ?></div>
            </div>
        </div>

        <div class="col-6 col-md-3">
            <div class="siem-kpi-card p-3">
                <div class="d-flex align-items-center gap-2 mb-1">
                    <span class="siem-kpi-icon text-warning"><i class="bi bi-shield-exclamation"></i></span>
                    <span class="siem-kpi-label">IPs bloqueadas</span>
                </div>
                <div class="siem-kpi-value text-warning"><?= (int) $kpis['ips_bloqueadas'] ?></div>
            </div>
        </div>

        <div class="col-6 col-md-3">
            <div class="siem-kpi-card p-3">
                <div class="d-flex align-items-center gap-2 mb-1">
                    <span class="siem-kpi-icon text-success"><i class="bi bi-people"></i></span>
                    <span class="siem-kpi-label">Sesiones activas</span>
                </div>
                <div class="siem-kpi-value text-success"><?= (int) $kpis['sesiones_activas'] ?></div>
            </div>
        </div>

    </div><!-- /KPIs -->

    <!-- Alertas recientes -->
    <div class="row g-3 mb-3">
        <div class="col-12">
            <div class="siem-kpi-card p-3">
                <div class="siem-section-header">
                    <i class="bi bi-exclamation-triangle text-warning"></i>
                    <span class="siem-section-title">Alertas recientes</span>
                </div>
                <?php if (empty($alertas)): ?>
                    <p class="text-muted small mb-0"><i class="bi bi-check-circle me-1 text-success"></i>Sin alertas activas.</p>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table table-hover table-siem mb-0" id="tbl-alertas-siem">
                            <thead>
                                <tr>
                                    <th>Fecha/Hora</th>
                                    <th>IP</th>
                                    <th>Usuario</th>
                                    <th>Tipo</th>
                                    <th>Motivo</th>
                                    <th>Cliente</th>
                                    <th class="text-center">Intentos</th>
                                    <th class="text-center">Estado</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($alertas as $al):
                                    $cliente  = smartcsetExtractClientFromUserAgent($al['user_agent']);
                                    $bloqueada = $al['tipo'] === 'IP_BLOQUEADA';
                                    $fila_bg  = $al['severidad'] === 'danger' ? 'table-danger' : ($al['severidad'] === 'warning' ? 'table-warning' : '');
                                    $intentos = (int) $al['intentos_ventana'];
                                    $badge_class = 'bg-info';
                                    if ($intentos >= 5 && $intentos < 8) $badge_class = 'bg-warning text-dark';
                                    if ($intentos >= 8) $badge_class = 'bg-danger';
                                ?>
                                    <tr class="<?= $fila_bg ?>">
                                        <td class="font-monospace small"><?= smartcsetFormatDbTimestamp($al['fec_evento'], 'd/m H:i:s') ?></td>
                                        <td class="font-monospace small"><?= htmlspecialchars($al['ip_cliente']) ?></td>
                                        <td class="small"><?= !empty($al['id_usuario']) ? htmlspecialchars($al['id_usuario']) : '—' ?></td>
                                        <td class="small"><?= $bloqueada ? 'IP bloqueada' : 'Fallo auth' ?></td>
                                        <td class="small"><?= htmlspecialchars(smartcsetMotivoFalloAbrev($al['motivo_fallo'])) ?></td>
                                        <td class="small font-monospace"><?= htmlspecialchars($cliente) ?></td>
                                        <td class="text-center">
                                            <?php if ($intentos > 0): ?>
                                                <span class="badge <?= $badge_class ?>"><?= $intentos ?></span>
                                            <?php else: ?>
                                                <span class="text-muted">—</span>
                                            <?php endif; ?>
                                        </td>
                                        <td class="text-center">
                                            <?php if ($bloqueada): ?>
                                                <span class="badge bg-danger">Bloqueada</span>
                                            <?php else: ?>
                                                <span class="badge bg-warning text-dark">Activa</span>
                                            <?php endif; ?>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div><!-- /Alertas recientes -->

    <!-- Top IPs -->
    <div class="row g-3">
        <div class="col-12">
            <div class="siem-kpi-card p-3">
                <div class="siem-section-header">
                    <i class="bi bi-diagram-3 text-danger"></i>
                    <span class="siem-section-title">Top IPs con más fallos hoy</span>
                </div>
                <?php if (empty($top_ips)): ?>
                    <p class="text-muted small mb-0"><i class="bi bi-check-circle me-1 text-success"></i>Sin actividad sospechosa registrada hoy.</p>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table table-hover table-siem mb-0">
                            <thead>
                                <tr>
                                    <th>IP</th>
                                    <th class="text-center">Fallos</th>
                                    <th>Último intento</th>
                                    <th class="text-center">Estado</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($top_ips as $ip): ?>
                                    <tr>
                                        <td class="font-monospace"><?= htmlspecialchars($ip['ip_cliente']) ?></td>
                                        <td class="text-center fw-bold text-danger"><?= (int) $ip['total_fallos'] ?></td>
                                        <td class="font-monospace"><?= smartcsetFormatDbTimestamp($ip['ultimo_fallo'], 'H:i:s') ?></td>
                                        <td class="text-center">
                                            <?php if ($ip['bloqueada']): ?>
                                                <span class="badge badge-bloqueada"><i class="bi bi-shield-x me-1"></i>Bloqueada</span>
                                            <?php else: ?>
                                                <span class="badge badge-activa-ip"><i class="bi bi-exclamation me-1"></i>Activa</span>
                                            <?php endif; ?>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>

</div><!-- /container -->
