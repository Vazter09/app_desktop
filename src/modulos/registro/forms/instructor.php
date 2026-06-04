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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $stmt_fun_registrar_instructor->execute([
            $_POST['id_persona'] ?? null,
            $_POST['id_tipo_docum'] ?? null,
            $_POST['nom_persona'] ?? null,
            $_POST['ape_persona'] ?? null,
            $_POST['mail_persona'] ?? null,
            $_POST['fec_nacimiento'] ?? null,
            $_POST['ind_genero'] ?? null,
            $_POST['ind_est_civil'] ?? null,
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
            $_POST['id_centro'] ?? null,
            $_POST['id_red'] ?? null,
            isset($_POST['ind_tipo_contrato']) ? 'true' : 'false',
            isset($_POST['ind_contratado_actual']) ? 'true' : 'false',
            isset($_POST['ind_disponibilidad']) ? 'true' : 'false',
            $_POST['ind_estado'] ?? null,
            registroDisplayUsername(),
        ]);

        $resultado = $stmt_fun_registrar_instructor->fetchColumn();
        if ($resultado !== 'OK') {
            throw new RuntimeException('No se pudo registrar el instructor.');
        }

        $success = true;
    } catch (PDOException $e) {
        $error = ErrorHandler::userMessageFromException($e);
    } catch (Throwable $e) {
        $error = ErrorHandler::userMessageFromException($e);
    }
}
?>
<?php registroIncludeHead('Registro Instructor', '#4a9eff'); registroIncludeHeader(); ?>
    <main class="main-wrapper">
        <div class="breadcrumb animate-in">
            <a href="../index.php">INICIO</a>
            <span class="sep">//</span>
            <span class="current">REGISTRO INSTRUCTOR</span>
        </div>

        <div class="form-container">
            <p class="section-title" style="color:#4a9eff;text-shadow:0 0 20px rgba(74,158,255,0.5)">Módulo 02</p>
            <h1 class="section-heading" style="margin-bottom:0.3rem">Registro de <em style="color:#4a9eff;text-shadow:0 0 20px rgba(74,158,255,0.5)">Instructor</em></h1>
            <p class="section-sub">Diligencie la información del instructor de planta o contratista.</p>

            <?php if ($success): ?>
            <div class="alert alert-success">✔ Instructor registrado exitosamente en el sistema.</div>
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
                        ✔ Registrar Instructor
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
    </script>
    <?php registroIncludeFooterScripts(); ?>
</body>
</html>
