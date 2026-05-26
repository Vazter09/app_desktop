<?php
require_once '../includes/auth.php';
require_once '../includes/db.php';
requireAuth();

$success = false;
$error   = '';
/*
try {
    $tiposDoc    = getTiposDocumento();
    $nivelesEst  = getNivelesEstudio();
    $profesiones = getProfesiones();
    $centros     = getCentros();
    $redes       = getRedes();
    $dptos       = getDepartamentos();
} catch (Exception $e) {
    $error = 'Error al cargar catálogos: ' . $e->getMessage();
    $tiposDoc = $nivelesEst = $profesiones = $centros = $redes = $dptos = [];
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $pdo = getDBConnection();

        // Insertar en tab_personas (tipo_persona=2 → Instructor)
        $sqlPersona = "
            INSERT INTO tab_personas (
                id_persona, id_tipo_docum, id_tipo_persona,
                nom_persona, ape_persona, mail_persona,
                fec_nacimiento, ind_genero,
                fec_ultima_entrada, fec_ultima_salida,
                id_nivel_estudio, id_profesion,
                id_dpto_reside, id_ciudad_reside, dir_ciudad_reside,
                tel_persona_fijo, tel_persona_movil,
                nom_contacto_emergencias, tel_contacto_emergencias,
                ind_envio_correo, ind_estado,
                usr_insert, fec_insert
            ) VALUES (
                :id_persona, :id_tipo_docum, 2,
                :nom_persona, :ape_persona, :mail_persona,
                :fec_nacimiento, :ind_genero,
                NOW(), NOW(),
                :id_nivel_estudio, :id_profesion,
                :id_dpto_reside, :id_ciudad_reside, :dir_ciudad_reside,
                :tel_persona_fijo, :tel_persona_movil,
                :nom_contacto_emergencias, :tel_contacto_emergencias,
                :ind_envio_correo, TRUE,
                :usr_insert, NOW()
            )
        ";
        $stmtP = $pdo->prepare($sqlPersona);
        $stmtP->execute([
            ':id_persona'              => $_POST['id_persona'],
            ':id_tipo_docum'           => $_POST['id_tipo_docum'],
            ':nom_persona'             => $_POST['nom_persona'],
            ':ape_persona'             => $_POST['ape_persona'],
            ':mail_persona'            => $_POST['mail_persona'],
            ':fec_nacimiento'          => $_POST['fec_nacimiento'],
            ':ind_genero'              => $_POST['ind_genero'],
            ':id_nivel_estudio'        => $_POST['id_nivel_estudio'],
            ':id_profesion'            => $_POST['id_profesion'],
            ':id_dpto_reside'          => $_POST['id_dpto_reside'],
            ':id_ciudad_reside'        => $_POST['id_ciudad_reside'],
            ':dir_ciudad_reside'       => $_POST['dir_ciudad_reside'],
            ':tel_persona_fijo'        => $_POST['tel_persona_fijo'],
            ':tel_persona_movil'       => $_POST['tel_persona_movil'],
            ':nom_contacto_emergencias'=> $_POST['nom_contacto_emergencias'],
            ':tel_contacto_emergencias'=> $_POST['tel_contacto_emergencias'],
            ':ind_envio_correo'        => isset($_POST['ind_envio_correo']) ? 'true' : 'false',
            ':usr_insert'              => $_SESSION['username'],
        ]);

        // Insertar en tab_instructores
        $sqlInst = "
            INSERT INTO tab_instructores (
                id_instructor, id_centro,
                ind_tipo_contrato, ind_contratado_actual,
                ind_genero, ind_est_civil,
                id_nivel_estudio, id_profesion, id_red,
                ind_disponibilidad, ind_estado,
                usr_insert, fec_insert
            ) VALUES (
                :id_instructor, :id_centro,
                :ind_tipo_contrato, :ind_contratado_actual,
                :ind_genero, :ind_est_civil,
                :id_nivel_estudio, :id_profesion, :id_red,
                :ind_disponibilidad, :ind_estado,
                :usr_insert, NOW()
            )
        ";
        $stmtI = $pdo->prepare($sqlInst);
        $stmtI->execute([
            ':id_instructor'       => $_POST['id_persona'],
            ':id_centro'           => $_POST['id_centro'],
            ':ind_tipo_contrato'   => isset($_POST['ind_tipo_contrato']) ? 'true' : 'false',
            ':ind_contratado_actual'=> isset($_POST['ind_contratado_actual']) ? 'true' : 'false',
            ':ind_genero'          => $_POST['ind_genero'],
            ':ind_est_civil'       => $_POST['ind_est_civil'],
            ':id_nivel_estudio'    => $_POST['id_nivel_estudio'],
            ':id_profesion'        => $_POST['id_profesion'],
            ':id_red'              => $_POST['id_red'],
            ':ind_disponibilidad'  => isset($_POST['ind_disponibilidad']) ? 'true' : 'false',
            ':ind_estado'          => $_POST['ind_estado'],
            ':usr_insert'          => $_SESSION['username'],
        ]);

        $success = true;
    } catch (PDOException $e) {
        $error = 'Error al guardar el instructor: ' . $e->getMessage();
    }
}
*/
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CSET — Registro Instructor</title>
    <link rel="stylesheet" href="../assets/style.css">
    <style>
        :root { --panel-accent: #4a9eff; }
    </style>
</head>
<body>
    <div class="scanline"></div>

    <header class="sys-header">
        <a href="../index.php" class="sys-logo">
            CSET <span>// Sistema de Gestión</span>
        </a>
        <nav class="sys-nav">
            <button id="theme-toggle" class="theme-toggle" type="button" aria-label="Cambiar modo de color">🌙</button>
            <a href="../index.php" class="nav-link">Inicio</a>
            <a href="../index.php?logout=1" class="btn-logout">Salir</a>
        </nav>
    </header>

    <main class="main-wrapper">
        <div class="breadcrumb animate-in">
            <a href="../index.php">INICIO</a>
            <span class="sep">//</span>
            <span class="current">REGISTRO INSTRUCTOR</span>
        </div>

        <div class="form-container">
            <p class="section-title" em style="color:#4a9eff;text-shadow:0 0 20px rgba(74,158,255,0.5)">Módulo 02</p>
            <h1 class="section-heading" style="margin-bottom:0.3rem">Registro de <em style="color:#4a9eff;text-shadow:0 0 20px rgba(74,158,255,0.5)">Instructor</em></h1>
            <p class="section-sub">Diligencie la información del instructor de planta o contratista.</p>

            <?php if ($success): ?>
            <div class="alert alert-success">✔ Instructor registrado exitosamente en el sistema.</div>
            <?php endif; ?>
            <?php if ($error): ?>
            <div class="alert alert-error">⚠ <?= htmlspecialchars($error) ?></div>
            <?php endif; ?>

            <form method="POST" class="form-panel animate-in" style="animation-delay:0.1s">

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
        fetch('../includes/ajax_ciudades.php?id_dpto=' + encodeURIComponent(idDpto))
            .then(r => r.json())
            .then(data => {
                sel.innerHTML = '<option value="">— Seleccione ciudad —</option>';
                data.forEach(c => { sel.innerHTML += `<option value="${c.id_ciudad}">${c.nom_ciudad}</option>`; });
            })
            .catch(() => { sel.innerHTML = '<option value="">Error al cargar</option>'; });
    }
    </script>
    <script src="../assets/theme-toggle.js"></script>
</body>
</html>
