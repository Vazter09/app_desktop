<?php
require_once __DIR__ . '/../init.php';
registroRequireAccess();

$success = false;
$error   = '';
// Cargar catálogos para los select
try {
    $tiposDoc    = registroGetTiposDocumento($pdo);
    $nivelesEst  = registroGetNivelesEstudio($pdo);
    $profesiones = registroGetProfesiones($pdo);
    $dptos       = registroGetDepartamentos($pdo);
    $fichas      = registroGetFichas($pdo);
} catch (Exception $e) {
    $error = 'Error al cargar catálogos: ' . $e->getMessage();
    $tiposDoc = $nivelesEst = $profesiones = $dptos = $fichas = [];
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $postOrNull = static function (string $key): ?string {
            $v = $_POST[$key] ?? '';
            $v = is_string($v) ? trim($v) : '';
            return $v === '' ? null : $v;
        };

        $stmt_fun_registrar_aprendiz->execute([
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
            $postOrNull('tel_alterno'),
            $postOrNull('tel_sede'),
            $postOrNull('ext_sede'),
            $postOrNull('tel_padre_fijo'),
            $postOrNull('tel_padre_movil'),
            $postOrNull('val_mail_institucional'),
            $_POST['ind_etdo_formacion'],
            registroDisplayUsername(),
            $postOrNull('id_ficha'),
        ]);

        $idRegistrado = $stmt_fun_registrar_aprendiz->fetchColumn();
        if ($idRegistrado === false || trim((string) $idRegistrado) === '') {
            throw new RuntimeException('No se pudo registrar el aprendiz.');
        }

        $success = true;
    } catch (Throwable $e) {
        $error = ErrorHandler::userMessageFromException($e);
    }
}
?>
<?php registroIncludeHead('Registro Aprendiz', '#00e5b0'); registroIncludeHeader(); ?>
    <main class="main-wrapper">
        <div class="breadcrumb animate-in">
            <a href="../index.php">INICIO</a>
            <span class="sep">//</span>
            <span class="current">REGISTRO APRENDIZ</span>
        </div>

        <div class="form-container">
            <p class="section-title">Módulo 01</p>
            <h1 class="section-heading" style="margin-bottom:0.3rem">Registro de <em>Aprendiz</em></h1>
            <p class="section-sub">Complete todos los campos obligatorios para registrar un nuevo aprendiz en el sistema.</p>

            <?php if ($success): ?>
            <div class="alert alert-success">✔ Aprendiz registrado exitosamente en el sistema.</div>
            <?php endif; ?>
            <?php if ($error): ?>
            <div class="alert alert-error">⚠ <?= htmlspecialchars($error) ?></div>
            <?php endif; ?>

            <form method="POST" class="form-panel animate-in"
                  style="animation-delay:0.1s">

                <!-- IDENTIFICACIÓN -->
                <div class="form-section-title">Identificación Personal</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label for="id_tipo_docum">Tipo de Documento <span class="required">*</span></label>
                        <select id="id_tipo_docum" name="id_tipo_docum" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($tiposDoc as $td): ?>
                            <option value="<?= htmlspecialchars($td['id_tipo_docum']) ?>">
                                <?= htmlspecialchars($td['id_tipo_docum']) ?> — <?= htmlspecialchars($td['nom_tipo_docum']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label for="id_persona">Número de Documento <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10" id="id_persona" name="id_persona" placeholder="1234567890" required>
                    </div>
                    <div class="field-group">
                        <label for="nom_persona">Nombres <span class="required">*</span></label>
                        <input type="text" id="nom_persona" name="nom_persona" placeholder="Nombres completos" required>
                    </div>
                    <div class="field-group">
                        <label for="ape_persona">Apellidos <span class="required">*</span></label>
                        <input type="text" id="ape_persona" name="ape_persona" placeholder="Apellidos completos" required>
                    </div>
                    <div class="field-group">
                        <label for="fec_nacimiento">Fecha de Nacimiento <span class="required">*</span></label>
                        <input type="date" id="fec_nacimiento" name="fec_nacimiento" required>
                    </div>
                    <div class="field-group">
                        <label for="ind_genero">Género <span class="required">*</span></label>
                        <select id="ind_genero" name="ind_genero" required>
                            <option value="">— Seleccione —</option>
                            <option value="1">Femenino</option>
                            <option value="2">Masculino</option>
                            <option value="3">No Binario</option>
                            <option value="4">Trans</option>
                            <option value="99">No Definido</option>
                        </select>
                    </div>
                    <div class="field-group">
                        <label for="mail_persona">Correo Personal <span class="required">*</span></label>
                        <input type="email" id="mail_persona" name="mail_persona" placeholder="correo@ejemplo.com" required>
                    </div>
                    <div class="field-group">
                        <label for="tel_persona_fijo">Teléfono Fijo <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10"
                               id="tel_persona_fijo" name="tel_persona_fijo" placeholder="6011234567" required>
                    </div>
                    <div class="field-group">
                        <label for="val_mail_institucional">Correo Institucional</label>
                        <input type="email" id="val_mail_institucional" name="val_mail_institucional" placeholder="usuario@sena.edu.co">
                    </div>
                </div>

                <!-- CONTACTO -->
                <div class="form-section-title">Información de Contacto</div>
                <div class="form-grid">
                    
                    <div class="field-group">
                        <label for="tel_persona_movil">Teléfono Móvil <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10" id="tel_persona_movil" name="tel_persona_movil" placeholder="3001234567" required>
                    </div>
                    <div class="field-group">
                        <label for="tel_alterno">Teléfono Alterno</label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10" id="tel_alterno" name="tel_alterno" placeholder="3009876543">
                    </div>
                
                    <div class="field-group">
                        <label for="nom_contacto_emergencias">Contacto de Emergencias <span class="required">*</span></label>
                        <input type="text" id="nom_contacto_emergencias" name="nom_contacto_emergencias" placeholder="Nombre completo" required>
                    </div>

                    <div class="field-group">
                        <label for="tel_contacto_emergencias">Tel. Emergencias <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10" id="tel_contacto_emergencias" name="tel_contacto_emergencias" placeholder="3001234567" required>
                    </div>
                </div>

                <!-- UBICACIÓN -->
                <div class="form-section-title">Ubicación de Residencia</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label for="id_dpto_reside">Departamento <span class="required">*</span></label>
                        <select id="id_dpto_reside" name="id_dpto_reside" required onchange="cargarCiudades(this.value)">
                            <option value="">— Seleccione —</option>
                            <?php foreach ($dptos as $d): ?>
                            <option value="<?= htmlspecialchars($d['id_dpto']) ?>">
                                <?= htmlspecialchars($d['nom_dpto']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label for="id_ciudad_reside">Ciudad <span class="required">*</span></label>
                        <select id="id_ciudad_reside" name="id_ciudad_reside" required>
                            <option value="">— Seleccione departamento —</option>
                            <?php foreach ($ciudades as $c): ?>
                            <option value="<?= htmlspecialchars($c['id_ciudad']) ?>">
                                <?= htmlspecialchars($c['nom_ciudad']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group span-2">
                        <label for="dir_ciudad_reside">Dirección de Residencia <span class="required">*</span></label>
                        <input type="text" id="dir_ciudad_reside" name="dir_ciudad_reside" placeholder="Calle 12 # 34-56, Barrio..." required>
                    </div>
                </div>

                <!-- ACADÉMICO -->
                <div class="form-section-title">Información Académica</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label for="id_nivel_estudio">Nivel de Estudio <span class="required">*</span></label>
                        <select id="id_nivel_estudio" name="id_nivel_estudio" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($nivelesEst as $n): ?>
                            <option value="<?= htmlspecialchars($n['id_nivel_estudio']) ?>">
                                <?= htmlspecialchars($n['nom_nivel_estudio']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label for="id_profesion">Profesión / Oficio <span class="required">*</span></label>
                        <select id="id_profesion" name="id_profesion" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($profesiones as $p): ?>
                            <option value="<?= htmlspecialchars($p['id_profesion']) ?>">
                                <?= htmlspecialchars($p['nom_profesion']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label for="ind_etdo_formacion">Estado de Formación <span class="required">*</span></label>
                        <select id="ind_etdo_formacion" name="ind_etdo_formacion" required>
                            <option value="1">En Formación</option>
                            <option value="2">Aplazado</option>
                            <option value="3">Retiro Voluntario</option>
                            <option value="4">Cancelado</option>
                            <option value="5">Condicionado</option>
                            <option value="6">Suspendido</option>
                            <option value="7">Desertado</option>
                        </select>
                    </div>
                    <div class="field-group">
                        <label for="id_ficha">Ficha de Formación</label>
                        <select id="id_ficha" name="id_ficha">
                            <option value="">— Sin asignar —</option>
                            <?php foreach ($fichas as $f): ?>
                            <option value="<?= htmlspecialchars($f['id_ficha']) ?>">
                                Ficha <?= htmlspecialchars($f['id_ficha']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>

                <!-- PREFERENCIAS -->
                <div class="form-section-title">Preferencias de Comunicación</div>
                <div class="toggle-group">
                    <label class="toggle">
                        <input type="checkbox" name="ind_envio_correo" value="1" checked>
                        <span class="toggle-slider"></span>
                    </label>
                    <span class="toggle-label">Autoriza recibir correos electrónicos del sistema</span>
                </div>

                <div class="btn-row">
                    <button type="submit" class="btn-primary">
                        ✔ Registrar Aprendiz
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
        if (!idDpto) {
            sel.innerHTML = '<option value="">— Seleccione departamento —</option>';
            return;
        }
        fetch('../ajax_ciudades.php?id_dpto=' + encodeURIComponent(idDpto))
            .then(r => r.json())
            .then(data => {
                sel.innerHTML = '<option value="">— Seleccione ciudad —</option>';
                data.forEach(c => {
                    sel.innerHTML += `<option value="${c.id_ciudad}">${c.nom_ciudad}</option>`;
                });
            })
            .catch(() => {
                sel.innerHTML = '<option value="">Error al cargar</option>';
            });
    }
    </script>
    <?php registroIncludeFooterScripts(); ?>
</body>
</html>
