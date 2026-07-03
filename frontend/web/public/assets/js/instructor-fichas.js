(function () {
    'use strict';

    function initInstructorFichas() {
        const page = document.getElementById('inst-fichas-page');
        const detalle = document.getElementById('inst-fichas-detalle');
        if (!page || !detalle) {
            return;
        }

        const basePath = page.dataset.basePath || window.location.pathname;
        const idFicha = parseInt(page.dataset.idFicha || '0', 10);
        const nomPrograma = page.dataset.nomPrograma || '';
        const nomJornada = page.dataset.nomJornada || '';
        const puedeEscribir = page.dataset.puedeEscribir === '1';

    function escapeHtml(value) {
        return String(value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function badgeForEstado(estado) {
        switch (estado) {
            case 'Presente': return 'success';
            case 'Tarde': return 'warning';
            case 'Ausente': return 'danger';
            case 'Pendiente': return 'secondary';
            default: return 'light text-dark';
        }
    }

    function formatDateIso(iso) {
        if (!iso) {
            return '';
        }
        const parts = iso.split('-');
        if (parts.length !== 3) {
            return iso;
        }
        return parts[2] + '/' + parts[1] + '/' + parts[0];
    }

    function shiftDate(iso, days) {
        const d = new Date(iso + 'T12:00:00');
        d.setDate(d.getDate() + days);
        return d.toISOString().slice(0, 10);
    }

    function buildUrl(params) {
        const qs = new URLSearchParams(params);
        return basePath + '?' + qs.toString();
    }

    function paramsFromForm(form) {
        const fd = new FormData(form);
        const params = { id_ficha: String(idFicha) };
        fd.forEach(function (value, key) {
            if (String(value).trim() !== '') {
                params[key] = String(value);
            }
        });
        return params;
    }

    function isModoRango(params) {
        return Boolean(
            params.desde && params.hasta && params.desde !== params.hasta
        );
    }

    function renderAccionesRow(row, fecha, estado) {
        if (!puedeEscribir) {
            return '';
        }
        const idAprendiz = parseInt(row.id_aprendiz || '0', 10);
        const buttons = ['Presente', 'Tarde', 'Ausente'].map(function (opcion) {
            return '<button type="button" class="btn btn-outline-secondary inst-btn-marcar"'
                + ' data-aprendiz="' + idAprendiz + '"'
                + ' data-fecha="' + escapeHtml(fecha) + '"'
                + ' data-estado="' + escapeHtml(opcion) + '"'
                + ' data-estado-actual="' + escapeHtml(estado) + '">'
                + escapeHtml(opcion) + '</button>';
        }).join('');
        return '<td class="text-end inst-asistencia-acciones"><div class="btn-group btn-group-sm" role="group">'
            + buttons + '</div></td>';
    }

    function renderDetalle(data, queryParams) {
        const desde = data.desde || '';
        const hasta = data.hasta || desde;
        const rows = Array.isArray(data.rows) ? data.rows : [];
        const porFecha = data.por_fecha || {};
        const esUnDia = desde === hasta;
        const modoRango = isModoRango(queryParams);
        const mostrarAcciones = puedeEscribir && esUnDia && !modoRango;
        const resumenDia = porFecha[desde] || {
            Presente: 0, Tarde: 0, Ausente: 0, Pendiente: 0, Desconocido: 0, total: 0,
        };
        const diaAnterior = shiftDate(desde, -1);
        const diaSiguiente = shiftDate(desde, 1);
        const qBase = 'id_ficha=' + idFicha;

        let tbody = '';
        if (rows.length === 0) {
            const cols = (!esUnDia || modoRango) ? (mostrarAcciones ? 8 : 7) : (mostrarAcciones ? 7 : 6);
            tbody = '<tr><td colspan="' + cols + '" class="text-center text-muted py-4">'
                + 'Sin aprendices activos en esta ficha para el período consultado.</td></tr>';
        } else {
            tbody = rows.map(function (row) {
                const estado = String(row.ind_estado || '');
                const badge = badgeForEstado(estado);
                const hora = String(row.hora_asistencia || '');
                const horaFmt = (hora !== '' && hora !== '00:00:00' && estado !== 'Pendiente' && estado !== 'Ausente')
                    ? hora.substring(0, 5) : '—';
                const retardo = parseInt(row.minutos_retraso || '0', 10);
                let html = '<tr>';
                if (!esUnDia || modoRango) {
                    html += '<td>' + escapeHtml(formatDateIso(String(row.fec_asistencia || ''))) + '</td>';
                }
                html += '<td>' + escapeHtml(String(row.nom_completo || '')) + '</td>';
                html += '<td>' + escapeHtml(String(row.id_aprendiz || '')) + '</td>';
                html += '<td>' + escapeHtml(String(row.nom_jornada || '')) + '</td>';
                html += '<td>' + escapeHtml(horaFmt) + '</td>';
                html += '<td>' + (retardo > 0 ? retardo + ' min' : '—') + '</td>';
                html += '<td><span class="badge bg-' + badge + '">' + escapeHtml(estado) + '</span></td>';
                if (mostrarAcciones) {
                    html += renderAccionesRow(row, desde, estado);
                }
                html += '</tr>';
                return html;
            }).join('');
        }

        let resumenRango = '';
        const fechasResumen = Object.keys(porFecha);
        if (modoRango && fechasResumen.length > 0) {
            resumenRango = '<div class="mt-4"><h3 class="h6 text-muted mb-2">Resumen por día</h3>'
                + '<div class="table-responsive"><table class="table table-sm table-bordered mb-0">'
                + '<thead class="table-light"><tr><th>Fecha</th><th>Presente</th><th>Tarde</th>'
                + '<th>Ausente</th><th>Pendiente</th><th>Total</th></tr></thead><tbody>'
                + fechasResumen.map(function (fec) {
                    const tot = porFecha[fec];
                    return '<tr><td>' + escapeHtml(formatDateIso(fec)) + '</td>'
                        + '<td>' + (tot.Presente || 0) + '</td>'
                        + '<td>' + (tot.Tarde || 0) + '</td>'
                        + '<td>' + (tot.Ausente || 0) + '</td>'
                        + '<td>' + (tot.Pendiente || 0) + '</td>'
                        + '<td>' + (tot.total || 0) + '</td></tr>';
                }).join('')
                + '</tbody></table></div></div>';
        }

        let navDia = '';
        if (esUnDia && !modoRango) {
            navDia = '<div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">'
                + '<div class="btn-group btn-group-sm">'
                + '<a class="btn btn-outline-secondary" href="' + escapeHtml(buildUrl({ id_ficha: String(idFicha), fecha: diaAnterior })) + '">'
                + '<i class="bi bi-chevron-left"></i> Anterior</a>'
                + '<span class="btn btn-light disabled">' + escapeHtml(formatDateIso(desde)) + '</span>'
                + '<a class="btn btn-outline-secondary" href="' + escapeHtml(buildUrl({ id_ficha: String(idFicha), fecha: diaSiguiente })) + '">'
                + 'Siguiente <i class="bi bi-chevron-right"></i></a>'
                + '</div>'
                + '<div class="inst-resumen-chips d-flex flex-wrap gap-2">'
                + '<span class="badge bg-success">Presente ' + (resumenDia.Presente || 0) + '</span>'
                + '<span class="badge bg-warning text-dark">Tarde ' + (resumenDia.Tarde || 0) + '</span>'
                + '<span class="badge bg-danger">Ausente ' + (resumenDia.Ausente || 0) + '</span>'
                + '<span class="badge bg-secondary">Pendiente ' + (resumenDia.Pendiente || 0) + '</span>'
                + '</div></div>';
        }

        const fechaVal = esUnDia && !modoRango ? desde : '';
        const desdeVal = modoRango ? desde : '';
        const hastaVal = modoRango ? hasta : '';

        detalle.innerHTML = ''
            + '<nav class="inst-fichas-breadcrumb mb-3" aria-label="Navegación de fichas">'
            + '<ol class="breadcrumb mb-0">'
            + '<li class="breadcrumb-item"><a href="' + escapeHtml(basePath) + '">'
            + '<i class="bi bi-journal-bookmark-fill me-1"></i>Mis Fichas</a></li>'
            + '<li class="breadcrumb-item active">Ficha ' + idFicha + '</li>'
            + '</ol></nav>'
            + '<div class="card shadow-sm inst-detalle-card">'
            + '<div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">'
            + '<div><span class="fw-semibold">Aprendices</span>'
            + '<span class="text-muted ms-2 small">' + escapeHtml(nomPrograma) + '</span></div>'
            + '<span class="badge bg-primary">' + escapeHtml(nomJornada) + '</span></div>'
            + '<div class="card-body">'
            + '<form method="get" class="inst-filtros-form row g-2 align-items-end mb-3" id="inst-filtros-form">'
            + '<input type="hidden" name="id_ficha" value="' + idFicha + '">'
            + '<div class="col-md-3"><label class="form-label small mb-1" for="inst_fecha">Fecha</label>'
            + '<input type="date" class="form-control form-control-sm" id="inst_fecha" name="fecha" value="' + escapeHtml(fechaVal) + '"></div>'
            + '<div class="col-md-2"><label class="form-label small mb-1" for="inst_desde">Desde</label>'
            + '<input type="date" class="form-control form-control-sm" id="inst_desde" name="desde" value="' + escapeHtml(desdeVal) + '"></div>'
            + '<div class="col-md-2"><label class="form-label small mb-1" for="inst_hasta">Hasta</label>'
            + '<input type="date" class="form-control form-control-sm" id="inst_hasta" name="hasta" value="' + escapeHtml(hastaVal) + '"></div>'
            + '<div class="col-md-5"><div class="inst-filtros-actions">'
            + '<button type="submit" class="btn btn-sm btn-success flex-grow-1">Consultar</button>'
            + '<button type="button" class="btn btn-sm btn-outline-secondary flex-grow-1" id="inst-btn-exportar">'
            + '<i class="bi bi-download me-1"></i>Exportar</button>'
            + '</div></div>'
            + '</form>'
            + navDia
            + '<div class="table-responsive"><table class="table table-sm table-hover align-middle inst-asistencia-table mb-0">'
            + '<thead class="table-light"><tr>'
            + ((!esUnDia || modoRango) ? '<th>Fecha</th>' : '')
            + '<th>Aprendiz</th><th>Documento</th><th>Jornada</th><th>Hora</th><th>Retardo</th><th>Estado</th>'
            + (mostrarAcciones ? '<th class="text-end">Marcar</th>' : '')
            + '</tr></thead><tbody>' + tbody + '</tbody></table></div>'
            + resumenRango
            + '</div></div>';

        bindForm();
        bindExport();
        bindMarcar();
    }

    async function refreshDetalle(params) {
        if (!window.SmartcsetInstructorRouter) {
            return;
        }
        try {
            const data = await SmartcsetInstructorRouter.listarAsistencia(idFicha, params);
            renderDetalle(data, params);
        } catch (err) {
            if (typeof window.smartcsetToast === 'function') {
                window.smartcsetToast('danger', err.message || 'No se pudo cargar la asistencia.');
            }
        }
    }

    function buildExportUrl(params) {
        const qs = new URLSearchParams(params);
        return '/routers/instructor/v1/asistencia/exportar.php?' + qs.toString();
    }

    function bindExport() {
        const btn = document.getElementById('inst-btn-exportar');
        if (!btn || btn.dataset.bound === '1') {
            return;
        }
        btn.dataset.bound = '1';
        btn.addEventListener('click', function () {
            const f = document.getElementById('inst-filtros-form');
            const params = f ? paramsFromForm(f) : { id_ficha: String(idFicha) };
            window.location.href = buildExportUrl(params);
        });
    }

    function bindForm() {
        const f = document.getElementById('inst-filtros-form');
        if (!f || f.dataset.bound === '1') {
            return;
        }
        f.dataset.bound = '1';
        f.addEventListener('submit', function (ev) {
            ev.preventDefault();
            const params = paramsFromForm(f);
            const url = buildUrl(params);
            window.history.pushState({}, '', url);
            refreshDetalle(params);
        });
    }

    function bindMarcar() {
        detalle.querySelectorAll('.inst-btn-marcar').forEach(function (btn) {
            if (btn.dataset.bound === '1') {
                return;
            }
            btn.dataset.bound = '1';
            btn.addEventListener('click', async function () {
                if (!window.SmartcsetInstructorRouter) {
                    return;
                }
                const payload = {
                    id_ficha: idFicha,
                    id_aprendiz: parseInt(btn.dataset.aprendiz || '0', 10),
                    fec_asistencia: btn.dataset.fecha || '',
                    ind_estado: btn.dataset.estado || '',
                };
                const actual = btn.dataset.estadoActual || '';
                const pendiente = actual === 'Pendiente' || actual === 'Desconocido';
                try {
                    if (pendiente) {
                        await SmartcsetInstructorRouter.registrarAsistencia(payload);
                    } else {
                        await SmartcsetInstructorRouter.actualizarAsistencia(payload);
                    }
                    const f = document.getElementById('inst-filtros-form');
                    const params = f ? paramsFromForm(f) : { id_ficha: String(idFicha), fecha: payload.fec_asistencia };
                    await refreshDetalle(params);
                    if (typeof window.smartcsetToast === 'function') {
                        window.smartcsetToast('success', 'Asistencia guardada correctamente.');
                    }
                } catch (err) {
                    if (typeof window.smartcsetToast === 'function') {
                        window.smartcsetToast('danger', err.message || 'No se pudo guardar la asistencia.');
                    }
                }
            });
        });
    }

        bindForm();
        bindExport();
        bindMarcar();
    }

    initInstructorFichas();
    document.addEventListener('smartcset:content-loaded', initInstructorFichas);
})();
