<?php
require_once __DIR__ . '/../init.php';
registroRequireAccess();

$success = false;
$error   = '';
try {
    $tiposDoc    = registroGetTiposDocumento($pdo);
    $nivelesEst  = registroGetNivelesEstudio($pdo);
    $profesiones = registroGetProfesiones($pdo);
    $dptos       = registroGetDepartamentos($pdo);
    $centros     = registroGetCentros($pdo);
    $areas       = registroGetAreas($pdo);
    $cargos      = registroGetCargos($pdo);
} catch (Exception $e) {
    $error = 'Error al cargar catálogos: ' . $e->getMessage();
    $tiposDoc = $nivelesEst = $profesiones = $dptos = $centros = $areas = $cargos = [];
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $idCentro = isset($_POST['id_centro']) && $_POST['id_centro'] !== ''
            ? $_POST['id_centro']
            : null;

        $stmt_fun_registrar_funcionario->execute([
            $_POST['id_persona'] ?? null,
            $_POST['id_tipo_docum'] ?? null,
            $_POST['nom_persona'] ?? null,
            $_POST['ape_persona'] ?? null,
            $_POST['mail_persona'] ?? null,
            $_POST['fec_nacimiento'] ?? null,
            $_POST['ind_genero'] ?? null,
            $_POST['id_nivel_estudio'] ?? null,
            $_POST['id_profesion'] ?? null,
            $_POST['id_dpto_reside'] ?? null,
            $_POST['id_ciudad_reside'] ?? null,
            $_POST['dir_ciudad_reside'] ?? null,
            $_POST['tel_persona_fijo'] ?? null,
            $_POST['tel_persona_movil'] ?? null,
            $_POST['nom_contacto_emergencias'] ?? null,
            $_POST['tel_contacto_emergencias'] ?? null,
            isset($_POST['ind_envio_correo']) ? 'true' : 'false',
            $_POST['id_area'] ?? null,
            $_POST['id_cargo'] ?? null,
            $_POST['val_grado'] ?? null,
            $_POST['fec_ingreso_planta'] ?? null,
            $idCentro,
            registroDisplayUsername(),
        ]);

        $resultado = $stmt_fun_registrar_funcionario->fetchColumn();
        if ($resultado !== 'OK') {
            throw new RuntimeException('No se pudo registrar el funcionario.');
        }

        $success = true;
    } catch (Throwable $e) {
        $error = ErrorHandler::userMessageFromException($e);
    }
}
?>
<?php registroIncludeHead('Registro Funcionario', '#9b6dff'); registroIncludeHeader(); ?>
    <main class="main-wrapper">
        <div class="breadcrumb animate-in">
            <a href="../index.php">INICIO</a>
            <span class="sep">//</span>
            <span class="current">REGISTRO FUNCIONARIO</span>
        </div>

        <div class="form-container">
            <p class="section-title" style="color:#9b6dff;text-shadow:0 0 20px rgba(155,109,255,0.5)">Módulo 03</p>
            <h1 class="section-heading" style="margin-bottom:0.3rem">
                Registro de <em style="color:#9b6dff;text-shadow:0 0 20px rgba(155,109,255,0.5)">Funcionario</em>
            </h1>
            <p class="section-sub">Ingrese los datos del funcionario administrativo o de apoyo.</p>

            <?php if ($success): ?>
            <div class="alert alert-success">✔ Funcionario registrado exitosamente en el sistema.</div>
            <?php endif; ?>
            <?php if ($error): ?>
            <div class="alert alert-error">⚠ <?= htmlspecialchars($error) ?></div>
            <?php endif; ?>

            <form method="POST" class="form-panel animate-in"
                  style="animation-delay:0.1s">

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
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10" name="id_persona" placeholder="1234567890" required>
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
                            <option value="3">No Binario</option>
                            <option value="4">Trans</option>
                            <option value="99">No Definido</option>
                        </select>
                    </div>
                </div>

                <div class="form-section-title">Información de Contacto</div>
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
                        <label>Contacto de Emergencias <span class="required">*</span></label>
                        <input type="text" name="nom_contacto_emergencias" placeholder="Nombre completo" required>
                    </div>
                    <div class="field-group">
                        <label>Tel. Emergencias <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10" name="tel_contacto_emergencias" placeholder="3001234567" required>
                    </div>
                </div>

                <div class="form-section-title">Ubicación de Residencia</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label>Departamento <span class="required">*</span></label>
                        <select name="id_dpto_reside" required onchange="cargarCiudades(this.value)">
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

                <div class="form-section-title">Perfil Académico y Vinculación</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label>Centro de Adscripción</label>
                        <select id="id_centro" name="id_centro" onchange="filtrarAreasPorCentro()">
                            <option value="">— Todos los centros —</option>
                            <?php foreach ($centros as $c): ?>
                            <option value="<?= htmlspecialchars((string) $c['id_centro']) ?>"><?= htmlspecialchars($c['nom_centro']) ?></option>
                            <?php endforeach; ?>
                        </select>
                        <span class="field-hint">Opcional: filtra las áreas del centro</span>
                    </div>
                    <div class="field-group">
                        <label>Área de Trabajo <span class="required">*</span></label>
                        <select id="id_area" name="id_area" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($areas as $a): ?>
                            <option value="<?= htmlspecialchars((string) $a['id_area']) ?>"
                                    data-centro="<?= htmlspecialchars((string) $a['id_centro']) ?>">
                                <?= htmlspecialchars($a['nom_area']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label>Cargo <span class="required">*</span></label>
                        <select name="id_cargo" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($cargos as $cg): ?>
                            <option value="<?= htmlspecialchars((string) $cg['id_cargo']) ?>">
                                <?= htmlspecialchars($cg['nom_cargo']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label>Grado <span class="required">*</span></label>
                        <input type="text" name="val_grado" placeholder="Ej: 11, 12, Técnico" maxlength="50" required>
                    </div>
                    <div class="field-group">
                        <label>Fecha ingreso a planta <span class="required">*</span></label>
                        <input type="date" name="fec_ingreso_planta" required>
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
                </div>

                <div class="form-section-title">Preferencias</div>
                <div class="toggle-group">
                    <label class="toggle">
                        <input type="checkbox" name="ind_envio_correo" value="1" checked>
                        <span class="toggle-slider"></span>
                    </label>
                    <span class="toggle-label">Autoriza recibir correos electrónicos del sistema</span>
                </div>

                <div class="btn-row">
                    <button type="submit" class="btn-primary" style="background:#9b6dff">
                        ✔ Registrar Funcionario
                    </button>
                    <a href="../index.php" class="btn-secondary">← Volver</a>
                    <button type="reset" class="btn-secondary">↺ Limpiar</button>
                </div>
            </form>
        </div>
    </main>

    <script>
    function cargarCiudades(idDpto) {
        const sel = document.getElementById('id_ciudad_reside');
        sel.innerHTML = '<option value="">Cargando...</option>';
        if (!idDpto) { sel.innerHTML = '<option value="">— Seleccione departamento —</option>'; return; }
        fetch('../ajax_ciudades.php?id_dpto=' + encodeURIComponent(idDpto))
            .then(r => r.json())  
            .then(data => {
                sel.innerHTML = '<option value="">— Seleccione ciudad —</option>';
                data.forEach(c => { sel.innerHTML += `<option value="${c.id_ciudad}">${c.nom_ciudad}</option>`; });
            })
            .catch(() => { sel.innerHTML = '<option value="">Error al cargar</option>'; });
    }

    function filtrarAreasPorCentro() {
        const centro = document.getElementById('id_centro').value;
        const sel = document.getElementById('id_area');
        const prev = sel.value;
        Array.from(sel.options).forEach((opt, idx) => {
            if (idx === 0) {
                opt.hidden = false;
                return;
            }
            const optCentro = opt.getAttribute('data-centro') || '';
            opt.hidden = centro !== '' && optCentro !== centro;
        });
        if (prev && sel.querySelector(`option[value="${prev}"]:not([hidden])`)) {
            sel.value = prev;
        } else {
            sel.value = '';
        }
    }
    </script>
    <?php registroIncludeFooterScripts(); ?>
</body>
</html>
