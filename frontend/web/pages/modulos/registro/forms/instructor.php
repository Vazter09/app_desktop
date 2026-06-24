<?php
require_once __DIR__ . '/../init.php';
registroRequireAccess();

$success = false;
$error   = '';
try {
    $tiposDoc    = registroGetTiposDocumento($pdo);
    $nivelesEst  = registroGetNivelesEstudio($pdo);
    $profesiones = registroGetProfesiones($pdo);
    $centros     = registroGetCentros($pdo);
    $redes       = registroGetRedes($pdo);
    $dptos       = registroGetDepartamentos($pdo);
} catch (Exception $e) {
    $error = 'Error al cargar catálogos: ' . $e->getMessage();
    $tiposDoc = $nivelesEst = $profesiones = $centros = $redes = $dptos = [];
}

?>
<?php registroIncludeHead('Registro Instructor', '#4a9eff'); registroIncludeHeader(); ?>
    <main class="main-wrapper">
        <div class="breadcrumb animate-in">
            <a href="../index.php">INICIO</a>
            <span class="sep">//</span>
            <span class="current">ACTUALIZACIÓN INSTRUCTOR</span>
        </div>

        <div class="form-container">
            <p class="section-title" style="color:#4a9eff;text-shadow:0 0 20px rgba(74,158,255,0.5)">Módulo 02</p>
            <h1 class="section-heading" style="margin-bottom:0.3rem">Actualización datos del <em style="color:#4a9eff;text-shadow:0 0 20px rgba(74,158,255,0.5)">Instructor</em></h1>
            <p class="section-sub">Diligencie la información del instructor de planta o contratista.</p>

            <?php if ($success): ?>
            <div class="alert alert-success">✔ Datos del instructor actualizados correctamente.</div>
            <?php endif; ?>
            <?php if ($error): ?>
            <div class="alert alert-error">⚠ <?= htmlspecialchars($error) ?></div>
            <?php endif; ?>

            <form method="POST" data-registro-tipo="instructor" class="form-panel animate-in"
                  style="animation-delay:0.1s" action="#">

                <div class="form-section-title">Identificación Personal</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label>Tipo de Documento <span class="required">*</span></label>
                        <select name="id_tipo_docum" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($tiposDoc as $td): ?>
                            <option value="<?= htmlspecialchars($td['id_tipo_docum']) ?>">
                                <?= htmlspecialchars($td['id_tipo_docum']) ?> — <?= htmlspecialchars($td['nom_tipo_docum']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label>Número de Documento <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10" name="id_persona" placeholder="20000001" min="20000001" required>
                        <span class="field-hint">Debe ser mayor a 20.000.000</span>
                    </div>
                    <div class="field-group">
                        <label>Nombres <span class="required">*</span></label>
                        <input type="text" name="nom_persona" placeholder="Nombres completos" required>
                    </div>
                    <div class="field-group">
                        <label>Apellidos <span class="required">*</span></label>
                        <input type="text" name="ape_persona" placeholder="Apellidos completos" required>
                    </div>
                    <div class="field-group">
                        <label>Fecha de Nacimiento <span class="required">*</span></label>
                        <input type="date" name="fec_nacimiento" required>
                    </div>
                    <div class="field-group">
                        <label>Género <span class="required">*</span></label>
                        <select name="ind_genero" required>
                            <option value="">— Seleccione —</option>
                            <option value="1">Femenino</option>
                            <option value="2">Masculino</option>
                            <option value="4">Trans</option>
                        </select>
                    </div>
                    <div class="field-group">
                        <label>Estado Civil <span class="required">*</span></label>
                        <select name="ind_est_civil" required>
                            <option value="">— Seleccione —</option>
                            <option value="1">Casado/a</option>
                            <option value="2">Soltero/a</option>
                            <option value="3">Unión Libre</option>
                            <option value="4">Viudo/a</option>
                            <option value="5">Divorciado/a</option>
                            <option value="9">Otro</option>
                        </select>
                    </div>
                </div>

                <div class="form-section-title">Contacto</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label>Correo Electrónico <span class="required">*</span></label>
                        <input type="email" name="mail_persona" placeholder="correo@ejemplo.com" required>
                    </div>
                    <div class="field-group">
                        <label>Teléfono Fijo <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10" name="tel_persona_fijo" placeholder="6011234567" required>
                    </div>
                    <div class="field-group">
                        <label>Teléfono Móvil <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10" name="tel_persona_movil" placeholder="3001234567" required>
                    </div>
                    <div class="field-group">
                        <label>Contacto Emergencias <span class="required">*</span></label>
                        <input type="text" name="nom_contacto_emergencias" placeholder="Nombre completo" required>
                    </div>
                    <div class="field-group">
                        <label>Tel. Emergencias <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10" name="tel_contacto_emergencias" placeholder="3001234567" required>
                    </div>
                </div>

                <div class="form-section-title">Ubicación</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label>Departamento <span class="required">*</span></label>
                        <select id="id_dpto_reside" name="id_dpto_reside" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($dptos as $d): ?>
                            <option value="<?= htmlspecialchars($d['id_dpto']) ?>"><?= htmlspecialchars($d['nom_dpto']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label>Ciudad <span class="required">*</span></label>
                        <select id="id_ciudad_reside" name="id_ciudad_reside" required>
                            <option value="">— Seleccione departamento —</option>
                        </select>
                    </div>
                    <div class="field-group span-2">
                        <label>Dirección <span class="required">*</span></label>
                        <input type="text" name="dir_ciudad_reside" placeholder="Calle 12 # 34-56, Barrio..." required>
                    </div>
                </div>

                <div class="form-section-title">Información Laboral e Institucional</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label>Centro de Formación <span class="required">*</span></label>
                        <select name="id_centro" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($centros as $c): ?>
                            <option value="<?= htmlspecialchars($c['id_centro']) ?>"><?= htmlspecialchars($c['nom_centro']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label>Red de Conocimiento <span class="required">*</span></label>
                        <select name="id_red" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($redes as $r): ?>
                            <option value="<?= htmlspecialchars($r['id_red']) ?>"><?= htmlspecialchars($r['nom_red']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label>Nivel de Estudio <span class="required">*</span></label>
                        <select name="id_nivel_estudio" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($nivelesEst as $n): ?>
                            <option value="<?= htmlspecialchars($n['id_nivel_estudio']) ?>"><?= htmlspecialchars($n['nom_nivel_estudio']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label>Profesión <span class="required">*</span></label>
                        <select name="id_profesion" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($profesiones as $p): ?>
                            <option value="<?= htmlspecialchars($p['id_profesion']) ?>"><?= htmlspecialchars($p['nom_profesion']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label>Estado del Instructor <span class="required">*</span></label>
                        <select name="ind_estado" required>
                            <option value="0">Activo</option>
                            <option value="2">Suspendido</option>
                            <option value="3">Bloqueado</option>
                            <option value="9">Inactivo</option>
                        </select>
                    </div>
                </div>

                <div class="form-section-title">Indicadores de Vinculación</div>
                <div class="form-grid">
                    <div class="field-group">
                        <div class="toggle-group">
                            <label class="toggle">
                                <input type="checkbox" name="ind_tipo_contrato" value="1" checked>
                                <span class="toggle-slider"></span>
                            </label>
                            <span class="toggle-label">Instructor de Planta (desmarcado = Contratista)</span>
                        </div>
                    </div>
                    <div class="field-group">
                        <div class="toggle-group">
                            <label class="toggle">
                                <input type="checkbox" name="ind_contratado_actual" value="1" checked>
                                <span class="toggle-slider"></span>
                            </label>
                            <span class="toggle-label">Contratado Actualmente</span>
                        </div>
                    </div>
                    <div class="field-group">
                        <div class="toggle-group">
                            <label class="toggle">
                                <input type="checkbox" name="ind_disponibilidad" value="1" checked>
                                <span class="toggle-slider"></span>
                            </label>
                            <span class="toggle-label">Disponible para asignaciones</span>
                        </div>
                    </div>
                    <div class="field-group">
                        <div class="toggle-group">
                            <label class="toggle">
                                <input type="checkbox" name="ind_envio_correo" value="1" checked>
                                <span class="toggle-slider"></span>
                            </label>
                            <span class="toggle-label">Autoriza recibir correos</span>
                        </div>
                    </div>
                </div>

                <div class="btn-row">
                    <button type="submit" class="btn-primary" style="background:#4a9eff;color:#fff">
                        ✔ ACTUALIZAR DATOS
                    </button>
                    <button type="reset" class="btn-secondary">↺ Limpiar</button>
                </div>
            </form>
        </div>
    </main>

    <?php $_ar = dirname(__DIR__, 3) . '/public/assets'; ?>
    <script src="<?= htmlspecialchars(smartcsetAsset('js/core/registro-cargar-ciudades.js')) ?>?v=<?= (int) (@filemtime($_ar . '/js/core/registro-cargar-ciudades.js') ?: time()) ?>"></script>
    <?php registroIncludeRouterScripts(); ?>
    <?php registroIncludeFooterScripts(); ?>
</body>
</html>
