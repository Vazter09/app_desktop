<?php
require_once __DIR__ . '/../init.php';
registroRequireAccess($pdo);

$success = false;
$error   = '';

try {
    $tiposDoc    = registroGetTiposDocumento($pdo);
    $tiposPersona = registroGetTiposPersona($pdo);
    $nivelesEst  = registroGetNivelesEstudio($pdo);
    $profesiones = registroGetProfesiones($pdo);
    $dptos       = registroGetDepartamentos($pdo);
} catch (Exception $e) {
    $error = 'Error al cargar catálogos: ' . $e->getMessage();
    $tiposDoc = $tiposPersona = $nivelesEst = $profesiones = $dptos = [];
}

?>
<?php registroIncludeHead('Registro Persona', '#00e5b0'); registroIncludeHeader(); ?>

    <main class="main-wrapper">
        <div class="breadcrumb animate-in">
            <a href="../index.php">INICIO</a>
            <span class="sep">//</span>
            <span class="current">REGISTRO DE PERSONA</span>
        </div>

        <div class="form-container">
            <p class="section-title">Módulo Base</p>
            <h1 class="section-heading" style="margin-bottom:0.3rem">Registro de <em>Persona</em></h1>
            <p class="section-sub">Formulario base para capturar los mismos atributos de todos los tipos de personas desde <code>tab_personas</code>.</p>

            <?php if ($success): ?>
            <div class="alert alert-success">✔ Persona registrada correctamente.</div>
            <?php endif; ?>
            <?php if ($error): ?>
            <div class="alert alert-error">⚠ <?= htmlspecialchars($error) ?></div>
            <?php endif; ?>

            <form method="POST" data-registro-tipo="persona" class="form-panel animate-in" style="animation-delay:0.1s" action="#">

                <div class="form-section-title">Tipo de Persona</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label for="id_tipo_persona">Tipo de Persona <span class="required">*</span></label>
                        <select id="id_tipo_persona" name="id_tipo_persona" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($tiposPersona as $tipo): ?>
                            <option value="<?= htmlspecialchars($tipo['id_tipo_persona']) ?>">
                                <?= htmlspecialchars($tipo['id_tipo_persona']) ?> — <?= htmlspecialchars($tipo['nom_tipo_persona']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>

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
                        <input type="number" id="id_persona" name="id_persona" placeholder="1234567890" min="1" required>
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
                </div>

                <div class="form-section-title">Datos de Contacto</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label for="mail_persona">Correo Personal <span class="required">*</span></label>
                        <input type="email" id="mail_persona" name="mail_persona" placeholder="correo@ejemplo.com" required>
                    </div>
                    <div class="field-group">
                        <label for="tel_persona_fijo">Teléfono Fijo <span class="required">*</span></label>
                        <input type="number" id="tel_persona_fijo" name="tel_persona_fijo" placeholder="6011234567" required>
                    </div>
                    <div class="field-group">
                        <label for="tel_persona_movil">Teléfono Móvil <span class="required">*</span></label>
                        <input type="number" id="tel_persona_movil" name="tel_persona_movil" placeholder="3001234567" required>
                    </div>
                    <div class="field-group">
                        <label for="nom_contacto_emergencias">Contacto Emergencias <span class="required">*</span></label>
                        <input type="text" id="nom_contacto_emergencias" name="nom_contacto_emergencias" placeholder="Nombre completo" required>
                    </div>
                    <div class="field-group">
                        <label for="tel_contacto_emergencias">Tel. Emergencias <span class="required">*</span></label>
                        <input type="number" id="tel_contacto_emergencias" name="tel_contacto_emergencias" placeholder="3001234567" required>
                    </div>
                    <div class="field-group field-checkbox">
                        <label>&nbsp;</label>
                        <div class="checkbox-row">
                            <label><input type="checkbox" name="ind_envio_correo" checked> Recibir correos</label>
                        </div>
                    </div>
                </div>

                <div class="form-section-title">Ubicación</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label for="id_dpto_reside">Departamento <span class="required">*</span></label>
                        <select id="id_dpto_reside" name="id_dpto_reside" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($dptos as $d): ?>
                            <option value="<?= htmlspecialchars($d['id_dpto']) ?>"><?= htmlspecialchars($d['nom_dpto']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label for="id_ciudad_reside">Ciudad <span class="required">*</span></label>
                        <select id="id_ciudad_reside" name="id_ciudad_reside" required>
                            <option value="">— Seleccione departamento —</option>
                        </select>
                    </div>
                    <div class="field-group span-2">
                        <label for="dir_ciudad_reside">Dirección <span class="required">*</span></label>
                        <input type="text" id="dir_ciudad_reside" name="dir_ciudad_reside" placeholder="Calle 12 # 34-56, Barrio..." required>
                    </div>
                </div>

                <div class="form-section-title">Formación</div>
                <div class="form-grid">
                    <div class="field-group">
                        <label for="id_nivel_estudio">Nivel de Estudio <span class="required">*</span></label>
                        <select id="id_nivel_estudio" name="id_nivel_estudio" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($nivelesEst as $nivel): ?>
                            <option value="<?= htmlspecialchars($nivel['id_nivel_estudio']) ?>"><?= htmlspecialchars($nivel['nom_nivel_estudio']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group">
                        <label for="id_profesion">Profesión <span class="required">*</span></label>
                        <select id="id_profesion" name="id_profesion" required>
                            <option value="">— Seleccione —</option>
                            <?php foreach ($profesiones as $prof): ?>
                            <option value="<?= htmlspecialchars($prof['id_profesion']) ?>"><?= htmlspecialchars($prof['nom_profesion']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="field-group field-checkbox">
                        <label>&nbsp;</label>
                        <div class="checkbox-row">
                            <label><input type="checkbox" name="ind_estado" checked> Activar persona</label>
                        </div>
                    </div>
                </div>

                <div class="form-actions">
                    <button type="submit" class="btn-primary">Guardar persona</button>
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
