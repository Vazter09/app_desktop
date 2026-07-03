<?php
/** @var list<array<string, mixed>> $tipos_doc */
/** @var list<array<string, mixed>> $tipos_persona */
/** @var list<array<string, mixed>> $entradas_lista */
/** @var int $puerta_pref */
/** @var bool $pt_reset_escaner */
?>
<form method="POST" id="form_ingreso" action="#" autocomplete="off"
      data-pt-reset="<?= $pt_reset_escaner ? '1' : '0' ?>">
    <input type="hidden" name="hid_captura_raw" id="hid_captura_raw" value="">
    <input type="hidden" name="hid_metodo_aut" id="hid_metodo_aut" value="1">
    <div class="ing-panel-body">
        <?php $pt_contexto = 'ingreso'; include __DIR__ . '/porteria_modos_ui.php'; ?>
        <div class="ing-field">
            <label for="txt_documento">Documento de identidad</label>
            <div class="ing-doc-row">
                <select name="sel_tipo_doc" id="sel_tipo_doc" class="form-select form-select-sm tipo-doc" required><?php foreach ($tipos_doc as $t): ?><option value="<?= htmlspecialchars($t['id_tipo_docum']) ?>"><?= htmlspecialchars($t['id_tipo_docum']) ?></option><?php endforeach; ?></select>
                <input type="text" name="txt_documento" id="txt_documento"
                       class="form-control form-control-sm num-doc"
                       data-documento-captura="1" required
                       placeholder="Número de documento"
                       autocomplete="off">
            </div>
            <span id="badge_persona" class="badge rounded-pill d-none" role="status"></span>
            <div id="ingreso_bloqueado_msg" class="ing-bloqueo-msg d-none" role="alert"></div>
        </div>

        <div class="ing-field">
            <label for="sel_tipo_persona">Tipo de persona</label>
            <select name="sel_tipo_persona" id="sel_tipo_persona"
                    class="form-select form-select-sm" required>
                <option value="">Seleccione…</option>
                <?php foreach ($tipos_persona as $tp): ?>
                <option value="<?= (int) $tp['id_tipo_persona'] ?>">
                    <?= htmlspecialchars($tp['nom_tipo_persona']) ?>
                </option>
                <?php endforeach; ?>
            </select>
        </div>

        <div class="ing-field">
            <label>Datos de la persona</label>
            <div class="ing-nombres-row">
                <div>
                    <label class="small text-muted mb-1" for="txt_nombres">Nombres</label>
                    <input type="text" name="txt_nombres" id="txt_nombres"
                           class="form-control form-control-sm" required minlength="2"
                           placeholder="Nombres" autocomplete="off">
                </div>
                <div>
                    <label class="small text-muted mb-1" for="txt_apellidos">Apellidos</label>
                    <input type="text" name="txt_apellidos" id="txt_apellidos"
                           class="form-control form-control-sm" required minlength="2"
                           placeholder="Apellidos" autocomplete="off">
                </div>
            </div>
        </div>

        <div class="ing-field">
            <label>Puerta de ingreso</label>
            <input type="hidden" name="sel_entrada" id="sel_entrada"
                   value="<?= $puerta_pref > 0 ? $puerta_pref : '' ?>">
            <div class="ing-puertas" id="puertas_grid" role="group">
                <?php if (empty($entradas_lista)): ?>
                <p class="small text-danger mb-0">Sin puertas configuradas.</p>
                <?php else: ?>
                <?php foreach ($entradas_lista as $e): ?>
                <?php
                $idPuerta = (int) $e['id_entrada'];
                $sel = ($puerta_pref === $idPuerta) ? ' is-selected' : '';
                ?>
                <button type="button" class="ing-puerta<?= $sel ?>"
                        data-puerta="<?= $idPuerta ?>"
                        title="<?= htmlspecialchars($e['nom_entrada']) ?>">
                    <span class="p-num"><?= $idPuerta ?></span>
                    <span class="p-nom"><?= htmlspecialchars($e['nom_entrada']) ?></span>
                </button>
                <?php endforeach; ?>
                <?php endif; ?>
            </div>
            <div class="ing-puerta-error" id="puerta_error">Seleccione una puerta para continuar.</div>
        </div>

        <div class="ing-field">
            <label for="txt_observaciones">Observaciones <span class="text-muted fw-normal">(opcional)</span></label>
            <textarea name="txt_observaciones" id="txt_observaciones" rows="2"
                      class="form-control form-control-sm" placeholder="Ej. visita a coordinación"></textarea>
        </div>
    </div>

    <div class="ing-panel-foot ing-panel-foot-modal">
        <button type="submit" id="btn_registrar_ingreso" class="btn btn-corporativo btn-ingreso-submit w-100"
                <?= empty($entradas_lista) ? 'disabled' : '' ?>>
            <i class="bi bi-check2-circle me-1"></i>Registrar ingreso
        </button>
    </div>
</form>
