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
} catch (Exception $e) {
    $error = 'Error al cargar catálogos: ' . $e->getMessage();
    $tiposDoc = $nivelesEst = $profesiones = $dptos = $centros = [];
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $stmt_fun_registrar_contratista->execute([
            $_POST['id_persona'],
            $_POST['id_tipo_docum'],
            $_POST['nom_persona'],
            $_POST['ape_persona'],
            $_POST['mail_persona'],
            $_POST['fec_nacimiento'],
            $_POST['ind_genero'],
            $_POST['id_nivel_estudio'],
            $_POST['id_profesion'],
            $_POST['id_dpto_reside'],
            $_POST['id_ciudad_reside'],
            $_POST['dir_ciudad_reside'],
            $_POST['tel_persona_fijo'],
            $_POST['tel_persona_movil'],
            $_POST['nom_contacto_emergencias'],
            $_POST['tel_contacto_emergencias'],
            isset($_POST['ind_envio_correo']) ? 'true' : 'false',
            registroDisplayUsername(),
        ]);
        $stmt_fun_registrar_contratista->fetchColumn();

        $success = true;
    } catch (Throwable $e) {
        $error = ErrorHandler::userMessageFromException($e);
    }
}
?>
<?php registroIncludeHead('Registro Contratista', '#ff7b2e'); registroIncludeHeader(); ?>
    <main class="main-wrapper">
        <div class="breadcrumb animate-in">
            <a href="../index.php">INICIO</a>
            <span class="sep">//</span>
            <span class="current">REGISTRO CONTRATISTA</span>
        </div>

        <div class="form-container">
            <p class="section-title" style="color:#ff7b2e;text-shadow:0 0 20px rgba(255,123,46,0.5)">Módulo 04</p>
            <h1 class="section-heading" style="margin-bottom:0.3rem">
                Registro de <em style="color:#ff7b2e;text-shadow:0 0 20px rgba(255,123,46,0.5)">Contratista</em>
            </h1>
            <p class="section-sub">Registre personal externo vinculado mediante contrato de prestación de servicios.</p>

            <?php if ($success): ?>
            <div class="alert alert-success">✔ Contratista registrado exitosamente en el sistema.</div>
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

                <div class="form-section-title">Perfil y referencia de contrato</div>
                <p class="field-hint" style="margin:0 0 1rem;max-width:52rem">
                    Por ahora solo se guardan los datos personales del contratista (tipo Contratista).
                    Centro, número de contrato y vigencias se registrarán cuando exista el módulo de contratos en base de datos.
                </p>
                <div class="form-grid">
                    <div class="field-group">
                        <label>Centro de Adscripción</label>
                        <select name="id_centro">
                            <option value="">— Seleccione —</option>
                            <?php foreach ($centros as $c): ?>
                            <option value="<?= htmlspecialchars($c['id_centro']) ?>"><?= htmlspecialchars($c['nom_centro']) ?></option>
                            <?php endforeach; ?>
                        </select>
                        <span class="field-hint">Referencia; no se almacena en este registro</span>
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
                        <label>Número de Contrato</label>
                        <input type="text" name="num_contrato" placeholder="Ej: 001-2025" autocomplete="off">
                        <span class="field-hint">Solo referencia; no se guarda aún</span>
                    </div>
                    <div class="field-group">
                        <label>Fecha Inicio Contrato</label>
                        <input type="date" name="fec_inicio_contrato" autocomplete="off">
                        <span class="field-hint">Solo referencia; no se guarda aún</span>
                    </div>
                    <div class="field-group">
                        <label>Fecha Fin Contrato</label>
                        <input type="date" name="fec_fin_contrato" autocomplete="off">
                        <span class="field-hint">Solo referencia; no se guarda aún</span>
                    </div>
                    <div class="field-group span-2">
                        <label>Objeto del Contrato</label>
                        <textarea name="objeto_contrato" placeholder="Descripción del objeto contractual..." autocomplete="off"></textarea>
                        <span class="field-hint">Solo referencia; no se guarda aún</span>
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
                    <button type="submit" class="btn-primary" style="background:#ff7b2e">
                        ✔ Registrar Contratista
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
