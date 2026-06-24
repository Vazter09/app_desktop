<?php
require_once dirname(__DIR__, 2) . '/init.php';

if (!isset($_SESSION['id_usuario'])) {
    header('Location: ' . smartcsetLoginUrl());
    exit();
}

// A01 (OWASP) — Broken Access Control: el CRUD de usuarios es exclusivo de administradores.
if (!usuarioEsAdministrador($pdo, $_SESSION['id_usuario'])) {
    http_response_code(403);
    die('Acceso denegado. Esta sección es exclusiva para administradores.');
}

$w_mensaje     = '';
$w_tipo_alerta = 'success';

$stmt_list_users->execute();
$usuarios_lista = $stmt_list_users->fetchAll();

$page_title     = 'Usuarios';
$active_menu_id = '0201';
$wnom_usuario   = $_SESSION['nom_usuario'];

$_crud_hl_v = @filemtime(dirname(__DIR__, 2) . '/public/assets/css/crud-row-highlight.css') ?: time();
$extra_stylesheets = '<link rel="stylesheet" href="' . htmlspecialchars(smartcsetAsset('css/crud-row-highlight.css')) . '?v=' . (int) $_crud_hl_v . '">';

include smartcsetLayoutPath('head.php');
include smartcsetLayoutPath('sidebar.php');
include smartcsetLayoutPath('topbar.php');
?>

<?php renderPageFlash($w_mensaje, $w_tipo_alerta); ?>

<div class="row g-3">
    <!-- Listado principal -->
    <div class="col-12">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-corporativo py-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
                <strong style="font-size:0.95rem;">
                    <i class="bi bi-people-fill me-2"></i>Usuarios del sistema
                    <span class="badge bg-light text-dark ms-1" style="font-size:0.72rem;"><?= count($usuarios_lista) ?></span>
                </strong>
                <button type="button" id="btn_nuevo_usuario" class="btn btn-sm btn-light fw-bold">
                    <i class="bi bi-person-plus-fill me-1"></i>Nuevo usuario
                </button>
            </div>
            <div class="table-responsive scroll-lista">
                <table class="table table-hover align-middle mb-0 table-sm" id="tabla-usuarios">
                    <thead class="thead-oliva sticky-top">
                        <tr style="font-size:0.85rem;">
                            <th class="ps-3 py-2">ID</th>
                            <th class="py-2">Nombre</th>
                            <th class="py-2">Correo</th>
                            <th class="text-center py-2">Rol</th>
                            <th class="text-center py-2">Estado</th>
                            <th class="text-center py-2" width="110">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($usuarios_lista)): ?>
                        <tr>
                            <td colspan="6" class="text-center text-muted py-4 small">
                                No hay usuarios registrados. Pulse <strong>Nuevo usuario</strong> para crear uno.
                            </td>
                        </tr>
                        <?php else: ?>
                        <?php foreach ($usuarios_lista as $u): ?>
                        <tr class="<?= !$u['ind_estado'] ? 'inactivo' : '' ?>"
                            data-id="<?= htmlspecialchars($u['id_usuario']) ?>"
                            style="font-size:0.875rem;">
                            <td class="ps-3 fw-bold py-2 text-muted small"><?= htmlspecialchars($u['id_usuario']) ?></td>
                            <td class="py-2 fw-medium" style="color:var(--v-oscuro);">
                                <?= htmlspecialchars($u['nom_usuario']) ?>
                            </td>
                            <td class="py-2 small text-muted"><?= htmlspecialchars($u['mail_usuario']) ?></td>
                            <td class="text-center py-2">
                                <?php if (!empty($u['ind_usuario'])): ?>
                                <span class="badge rounded-pill" style="background:rgba(107,142,35,0.2);color:var(--v-oscuro);font-size:0.7rem;">
                                    <i class="bi bi-shield-fill-check me-1"></i>Admin
                                </span>
                                <?php else: ?>
                                <span class="badge bg-light text-secondary border" style="font-size:0.7rem;">Usuario</span>
                                <?php endif; ?>
                            </td>
                            <td class="text-center py-2">
                                <span class="badge <?= $u['ind_estado'] ? 'bg-success' : 'bg-danger' ?>" style="font-size:0.72rem;">
                                    <?= $u['ind_estado'] ? 'ACTIVO' : 'INACTIVO' ?>
                                </span>
                            </td>
                            <td class="text-center py-2">
                                <div class="btn-group btn-group-sm" role="group" aria-label="Acciones">
                                    <button type="button"
                                            class="btn btn-outline-primary btn-editar-usuario border-0"
                                            title="Editar"
                                            data-id="<?= htmlspecialchars($u['id_usuario']) ?>"
                                            data-nom="<?= htmlspecialchars($u['nom_usuario']) ?>"
                                            data-mail="<?= htmlspecialchars($u['mail_usuario']) ?>"
                                            data-adm="<?= !empty($u['ind_usuario']) ? '1' : '0' ?>"
                                            data-est="<?= $u['ind_estado'] ? '1' : '0' ?>">
                                        <i class="bi bi-pencil-square"></i>
                                    </button>
                                    <form method="POST" class="d-inline form-toggle-estado" data-smart-confirm
                                          data-smart-confirm-title="<?= $u['ind_estado'] ? 'Desactivar usuario' : 'Activar usuario' ?>"
                                          data-smart-confirm-message="¿<?= $u['ind_estado'] ? 'Desactivar' : 'Activar' ?> al usuario «<?= htmlspecialchars($u['nom_usuario']) ?>»?"
                                          data-smart-confirm-ok="<?= $u['ind_estado'] ? 'Desactivar' : 'Activar' ?>"
                                          data-smart-confirm-variant="<?= $u['ind_estado'] ? 'warning' : 'primary' ?>">
                                        <input type="hidden" name="hid_id_usuario" value="<?= htmlspecialchars($u['id_usuario']) ?>">
                                        <input type="hidden" name="hid_nuevo_estado" value="<?= $u['ind_estado'] ? 'false' : 'true' ?>">
                                        <button type="submit" name="btn_toggle_estado"
                                                class="btn border-0 <?= $u['ind_estado'] ? 'btn-outline-danger' : 'btn-outline-success' ?>"
                                                title="<?= $u['ind_estado'] ? 'Desactivar' : 'Activar' ?>">
                                            <i class="bi <?= $u['ind_estado'] ? 'bi-lock-fill' : 'bi-check-circle-fill' ?>"></i>
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- Modal crear / editar usuario -->
<div class="modal fade modal-form-usuario" id="modalUsuario" tabindex="-1" aria-labelledby="editor-titulo" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header bg-corporativo text-white py-3">
                <div>
                    <h5 class="modal-title fs-6 fw-bold mb-0" id="editor-titulo">Nuevo usuario</h5>
                    <p class="small mb-0 opacity-75" id="editor-subtitulo">Complete los datos del usuario</p>
                </div>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>
            <form method="POST" id="form_usuario" data-watch-unsaved>
                <div class="modal-body">
                    <section class="form-section">
                        <div class="form-section-title">Identificación</div>
                        <div class="mb-3">
                            <label class="form-label" for="f_id">ID de usuario</label>
                            <input type="text" name="txt_id_usuario" id="f_id" class="form-control form-control-sm"
                                   required minlength="5" maxlength="50" autocomplete="off" placeholder="ej. jperez">
                            <div class="form-text">Identificador único para iniciar sesión (mín. 5 caracteres).</div>
                        </div>
                        <div>
                            <label class="form-label" for="f_nom">Nombre completo</label>
                            <input type="text" name="txt_nom_usuario" id="f_nom" class="form-control form-control-sm"
                                   required minlength="8" autocomplete="off" placeholder="Nombre y apellidos">
                        </div>
                    </section>

                    <section class="form-section">
                        <div class="form-section-title">Acceso</div>
                        <div class="mb-3">
                            <label class="form-label" for="f_mail">Correo electrónico</label>
                            <input type="email" name="txt_mail_usuario" id="f_mail" class="form-control form-control-sm"
                                   required autocomplete="off" placeholder="usuario@ejemplo.com">
                        </div>
                        <div>
                            <label class="form-label" for="f_pass">Contraseña</label>
                            <input type="password" name="txt_pass_usuario" id="f_pass" class="form-control form-control-sm"
                                   autocomplete="new-password" minlength="<?= PASSWORD_MIN_LENGTH ?>"
                                   placeholder="Mínimo <?= PASSWORD_MIN_LENGTH ?> caracteres">
                            <div class="form-text" id="f_pass_ayuda">Obligatoria al crear (mín. <?= PASSWORD_MIN_LENGTH ?>). Al editar, déjela vacía para no cambiarla.</div>
                        </div>
                    </section>

                    <section class="form-section">
                        <div class="form-section-title">Permisos y estado</div>
                        <div class="permisos-grid">
                            <div class="form-check permiso-item">
                                <input type="checkbox" name="chk_admin" id="f_adm" class="form-check-input">
                                <label class="form-check-label" for="f_adm">
                                    Administrador
                                    <span class="permiso-desc">Acceso total al catálogo de menús.</span>
                                </label>
                            </div>
                            <div class="form-check permiso-item">
                                <input type="checkbox" name="chk_estado" id="f_est" class="form-check-input" checked>
                                <label class="form-check-label" for="f_est">
                                    Habilitado
                                    <span class="permiso-desc">Puede ingresar al sistema.</span>
                                </label>
                            </div>
                        </div>
                    </section>
                </div>
                <div class="modal-footer d-flex justify-content-end gap-2">
                    <button type="button" class="btn btn-light btn-sm px-3" data-bs-dismiss="modal">Cancelar</button>
                    <button type="submit" name="btn_guardar" class="btn btn-corporativo btn-sm px-4">
                        <i class="bi bi-save me-1"></i>Guardar
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php
$_ar = dirname(__DIR__, 2) . '/public/assets';
$extra_js = '<script src="' . htmlspecialchars(smartcsetAsset('js/services/http-client.js')) . '?v=' . (int) (@filemtime($_ar . '/js/services/http-client.js') ?: time()) . '"></script>'
    . '<script src="' . htmlspecialchars(smartcsetAsset('js/services/usuarios-router.js')) . '?v=' . (int) (@filemtime($_ar . '/js/services/usuarios-router.js') ?: time()) . '"></script>'
    . '<script src="' . htmlspecialchars(smartcsetAsset('js/core/usuarios.js')) . '?v=' . (int) (@filemtime($_ar . '/js/core/usuarios.js') ?: time()) . '"></script>';
include smartcsetLayoutPath('footer.php');
?>
