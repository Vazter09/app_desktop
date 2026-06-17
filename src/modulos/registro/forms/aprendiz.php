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

        $params = [
            $_POST['id_persona'],                                    
            $_POST['id_tipo_docum'],                                 
            $_POST['nom_persona'],                                  
            $_POST['ape_persona'],                                  
            $_POST['mail_persona'],                                 
            $_POST['fec_nacimiento'],                               
            (int)$_POST['ind_genero'],                              
            $_POST['id_nivel_estudio'],                             
            $_POST['id_profesion'],                                 
            $_POST['id_dpto_reside'],                               
            $_POST['id_ciudad_reside'],                             
            $_POST['dir_ciudad_reside'],                            
            (int)$_POST['tel_persona_fijo'],                        
            (int)$_POST['tel_persona_movil'],                       
            $_POST['nom_contacto_emergencias'],                     
            (int)$_POST['tel_contacto_emergencias'],                
            isset($_POST['ind_envio_correo']) ? 'true' : 'false',       
            $postOrNull('tel_alterno') !== null ? (int)$postOrNull('tel_alterno') : null,     
            $postOrNull('tel_sede') !== null ? (int)$postOrNull('tel_sede') : null,           
            $postOrNull('ext_sede') !== null ? (int)$postOrNull('ext_sede') : null,           
            $postOrNull('tel_padre_fijo') !== null ? (int)$postOrNull('tel_padre_fijo') : null,   
            $postOrNull('tel_padre_movil') !== null ? (int)$postOrNull('tel_padre_movil') : null, 
            $postOrNull('val_mail_institucional'),                   
            (int)$_POST['ind_etdo_formacion'],                       
            registroDisplayUsername(),                               // 25: varchar
            $_POST['id_ficha'],                                      // 26: numeric
        ];

        $stmt_fun_actualizar_aprendiz->execute($params);

        $idRegistrado = $stmt_fun_actualizar_aprendiz->fetchColumn();
        if ($idRegistrado === false || trim((string) $idRegistrado) === '') {
            throw new RuntimeException('No se pudo actualizar los datos del aprendiz.');
        }

        $success = true;
    } catch (Throwable $e) {
        $handled = registroHandlePostException($e);
        $error   = $handled['msg'];
    }
}
?>
<?php registroIncludeHead('Actualización Aprendiz', '#00e5b0'); registroIncludeHeader(); ?>
    <main class="main-wrapper">
        <div class="breadcrumb animate-in">
            <a href="../index.php">INICIO</a>
            <span class="sep">//</span>
            <span class="current">ACTUALIZACIÓN APRENDIZ</span>
        </div>

        <div class="form-container">
            <p class="section-title">Módulo 01</p>
            <h1 class="section-heading" style="margin-bottom:0.3rem">Actualización datos del <em>Aprendiz</em></h1>
            <p class="section-sub">Busque al aprendiz por documento, revise la información cargada y actualice los campos obligatorios en persona, aprendiz y ficha de formación.</p>

            <?php if ($success): ?>
            <div class="alert alert-success">✔ Datos del aprendiz actualizados correctamente.</div>
            <?php endif; ?>
            <?php if ($error): ?>
            <div class="alert alert-error">⚠ <?= htmlspecialchars($error) ?></div>
            <?php endif; ?>

            <form method="POST" id="registro-form-aprendiz" class="form-panel animate-in" style="animation-delay:0.1s">

                <div class="registro-accordion" id="registro-accordion-aprendiz">

                <!-- PERSONA (tab_personas) -->
                <div class="form-section-title form-section-title--plain">Persona</div>
                <div class="registro-accordion" id="registro-accordion-persona">

                <div class="registro-accordion-item is-open" id="acc-persona-ident">
                    <button type="button" class="registro-accordion-trigger form-section-title"
                            id="trigger-persona-ident" aria-expanded="true" aria-controls="panel-persona-ident">
                        Identificación
                    </button>
                    <div class="registro-accordion-panel" id="panel-persona-ident" role="region" aria-labelledby="trigger-persona-ident">
                <div class="form-grid cols-2">
                    <div class="field-group">
                        <label for="id_persona">Número de Documento <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="6" maxlength="10"
                               id="id_persona" name="id_persona" placeholder="1234567890" required autofocus>
                    </div>
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
                        <label for="nom_persona">Nombres <span class="required">*</span></label>
                        <input type="text" id="nom_persona" name="nom_persona" placeholder="Nombres completos" required maxlength="40">
                    </div>
                    <div class="field-group">
                        <label for="ape_persona">Apellidos <span class="required">*</span></label>
                        <input type="text" id="ape_persona" name="ape_persona" placeholder="Apellidos completos" required maxlength="30">
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
                        </select>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="registro-accordion-item" id="acc-persona-tel">
            <button type="button" class="registro-accordion-trigger form-section-title"
            id="trigger-persona-tel" aria-expanded="false" aria-controls="panel-persona-tel">
            Contactos Personales
        </button>
        <div class="registro-accordion-panel" id="panel-persona-tel" role="region" aria-labelledby="trigger-persona-tel">
            <div class="form-grid cols-2">
                <div class="field-group">
                    <label for="tel_persona_fijo">Teléfono Fijo <span class="required">*</span></label>
                    <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10"
                    id="tel_persona_fijo" name="tel_persona_fijo" placeholder="6011234567" required>
                </div>
                <div class="field-group">
                    <label for="tel_persona_movil">Teléfono Móvil <span class="required">*</span></label>
                    <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10"
                    id="tel_persona_movil" name="tel_persona_movil" placeholder="3001234567" required>
                </div>
                <div class="field-group span-2">
                    <label for="mail_persona">Correo Personal <span class="required">*</span></label>
                    <input type="email" id="mail_persona" name="mail_persona" placeholder="correo@ejemplo.com" required>
                </div>
            </div>
        </div>
    </div>
    
                <div class="registro-accordion-item" id="acc-persona-ubic">
                    <button type="button" class="registro-accordion-trigger form-section-title"
                            id="trigger-persona-ubic" aria-expanded="false" aria-controls="panel-persona-ubic">
                        Ubicación de Residencia
                    </button>
                    <div class="registro-accordion-panel" id="panel-persona-ubic" role="region" aria-labelledby="trigger-persona-ubic">
                <div class="form-grid cols-2">
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
                        </select>
                    </div>
                    <div class="field-group span-2">
                        <label for="dir_ciudad_reside">Dirección de Residencia <span class="required">*</span></label>
                        <input type="text" id="dir_ciudad_reside" name="dir_ciudad_reside"
                               placeholder="Calle 12 # 34-56, Barrio..." required minlength="10" maxlength="100">
                    </div>
                </div>
                    </div>
                </div>

                <div class="registro-accordion-item" id="acc-persona-formacion">
                    <button type="button" class="registro-accordion-trigger form-section-title"
                            id="trigger-persona-formacion" aria-expanded="false" aria-controls="panel-persona-formacion">
                        Formación
                    </button>
                    <div class="registro-accordion-panel" id="panel-persona-formacion" role="region" aria-labelledby="trigger-persona-formacion">
                <div class="form-grid cols-2">
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
                </div>
                    </div>
                </div>

                <div class="registro-accordion-item" id="acc-persona-emergencias">
                    <button type="button" class="registro-accordion-trigger form-section-title"
                            id="trigger-persona-emergencias" aria-expanded="false" aria-controls="panel-persona-emergencias">
                        Contacto de Emergencias
                    </button>
                    <div class="registro-accordion-panel" id="panel-persona-emergencias" role="region" aria-labelledby="trigger-persona-emergencias">
                <div class="form-grid cols-2">
                    <div class="field-group">
                        <label for="nom_contacto_emergencias">Nombre <span class="required">*</span></label>
                        <input type="text" id="nom_contacto_emergencias" name="nom_contacto_emergencias"
                               placeholder="Nombre completo" required minlength="5" maxlength="60">
                    </div>
                    <div class="field-group">
                        <label for="tel_contacto_emergencias">Teléfono <span class="required">*</span></label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10"
                               id="tel_contacto_emergencias" name="tel_contacto_emergencias" placeholder="3001234567" required>
                    </div>
                </div>
                    </div>
                </div>

                <div class="registro-accordion-item" id="acc-persona-preferencias">
                    <button type="button" class="registro-accordion-trigger form-section-title"
                            id="trigger-persona-preferencias" aria-expanded="false" aria-controls="panel-persona-preferencias">
                        Preferencias de Comunicación
                    </button>
                    <div class="registro-accordion-panel" id="panel-persona-preferencias" role="region" aria-labelledby="trigger-persona-preferencias">
                <div class="toggle-group">
                    <label class="toggle">
                        <input type="checkbox" name="ind_envio_correo" value="1" checked>
                        <span class="toggle-slider"></span>
                    </label>
                    <span class="toggle-label">Autoriza recibir correos electrónicos del sistema</span>
                </div>
                    </div>
                </div>

                </div>

                <!-- APRENDIZ (tab_aprendices + datos_personales_aprendiz) -->
                <div class="registro-accordion-item" id="acc-aprendiz">
                    <button type="button" class="registro-accordion-trigger form-section-title" id="trigger-aprendiz"
                            aria-expanded="false" aria-controls="panel-aprendiz">
                        Aprendiz
                    </button>
                    <div class="registro-accordion-panel" id="panel-aprendiz" role="region" aria-labelledby="trigger-aprendiz">
                        <div class="registro-accordion">

                <div class="registro-accordion-item" id="acc-aprendiz-estado">
                    <button type="button" class="registro-accordion-trigger form-section-title"
                            id="trigger-aprendiz-estado" aria-expanded="false" aria-controls="panel-aprendiz-estado">
                        Estado de Formación
                    </button>
                    <div class="registro-accordion-panel" id="panel-aprendiz-estado" role="region" aria-labelledby="trigger-aprendiz-estado">
                <div class="form-grid cols-2">
                    <div class="field-group">
                        <label for="ind_etdo_formacion">Estado <span class="required">*</span></label>
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
                </div>
                    </div>
                </div>

                <div class="registro-accordion-item" id="acc-aprendiz-contacto">
                    <button type="button" class="registro-accordion-trigger form-section-title"
                            id="trigger-aprendiz-contacto" aria-expanded="false" aria-controls="panel-aprendiz-contacto">
                        Contacto Institucional y Familiar
                    </button>
                    <div class="registro-accordion-panel" id="panel-aprendiz-contacto" role="region" aria-labelledby="trigger-aprendiz-contacto">
                <div class="form-grid cols-2">
                    <div class="field-group span-2">
                        <label for="val_mail_institucional">Correo Institucional</label>
                        <input type="email" id="val_mail_institucional" name="val_mail_institucional"
                               placeholder="usuario@sena.edu.co">
                    </div>
                    <div class="field-group">
                        <label for="tel_alterno">Teléfono Alterno</label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10"
                               id="tel_alterno" name="tel_alterno" placeholder="3009876543">
                    </div>
                    <div class="field-group">
                        <label for="tel_sede">Teléfono Sede</label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10"
                               id="tel_sede" name="tel_sede" placeholder="6011234567">
                    </div>
                    <div class="field-group">
                        <label for="ext_sede">Extensión Sede</label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" min="0" max="99999999"
                               id="ext_sede" name="ext_sede" placeholder="1234">
                    </div>
                    <div class="field-group">
                        <label for="tel_padre_fijo">Tel. Acudiente Fijo</label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10"
                               id="tel_padre_fijo" name="tel_padre_fijo" placeholder="6011234567">
                    </div>
                    <div class="field-group">
                        <label for="tel_padre_movil">Tel. Acudiente Móvil</label>
                        <input type="text" inputmode="numeric" pattern="[0-9]*" minlength="10" maxlength="10"
                               id="tel_padre_movil" name="tel_padre_movil" placeholder="3001234567">
                    </div>
                </div>
                    </div>
                </div>

                        </div>
                    </div>
                </div>

                <!-- FICHA (tab_aprendices_fichas) -->
                <div class="registro-accordion-item" id="acc-ficha">
                    <button type="button" class="registro-accordion-trigger form-section-title" id="trigger-ficha"
                            aria-expanded="false" aria-controls="panel-ficha">
                        Ficha de Formación
                    </button>
                    <div class="registro-accordion-panel" id="panel-ficha" role="region" aria-labelledby="trigger-ficha">
                <div class="form-grid cols-2">
                    <div class="field-group span-2">
                        <label for="id_ficha">Ficha <span class="required">*</span></label>
                        <select id="id_ficha" name="id_ficha" required>
                            <option value="">— Seleccione ficha —</option>
                            <?php foreach ($fichas as $f): ?>
                            <option value="<?= htmlspecialchars((string) $f['id_ficha']) ?>">
                                <?= htmlspecialchars($f['etiqueta'] ?? (string) $f['id_ficha']) ?>
                            </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>
                    </div>
                </div>

                </div>

                <div class="btn-row">
                    <button type="submit" class="btn-primary">
                       ✔ Actualizar Datos
                    </button>
                    <button type="reset" class="btn-secondary">↺ Limpiar</button>
                </div>
            </form>
        </div>
    </main>

    <?php
    $regHref = registroAssetHref();
    $vAccordion = @filemtime(dirname(__DIR__, 4) . '/js/registro-form-accordion.js') ?: time();
    $vBuscar = @filemtime(dirname(__DIR__, 4) . '/js/registro-aprendiz-buscar.js') ?: time();
    ?>
    <script src="<?= htmlspecialchars($regHref) ?>js/registro-form-accordion.js?v=<?= (int) $vAccordion ?>"></script>
    <script src="<?= htmlspecialchars($regHref) ?>js/registro-aprendiz-buscar.js?v=<?= (int) $vBuscar ?>"></script>
    <?php registroIncludeFooterScripts(); ?>
    <script>
    document.addEventListener('invalid', function(e){
        var target = e.target;
        var panel = target.closest('.registro-accordion-panel');
        if(panel) {
            var btnId = panel.getAttribute('aria-labelledby');
            if(btnId) {
                var btn = document.getElementById(btnId);
                if(btn && btn.getAttribute('aria-expanded') !== 'true') {
                    btn.click();
                }
            }
        }
    }, true);
    </script>
</body>
</html>