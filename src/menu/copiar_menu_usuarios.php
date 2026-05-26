<?php
require_once(__DIR__ . '/../core/prepare.php');
require_once(__DIR__ . '/../core/helpers.php');
session_start();

if (!isset($_SESSION['id_usuario'])) {
    header("Location: ../../index.php");
    exit();
}

$lista_usuarios = [];
$error_carga    = null;

try {
    $stmt_list_usuarios->execute();
    $lista_usuarios = $stmt_list_usuarios->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    $error_carga = $e->getMessage();
}

$page_title     = 'Copiar Perfil';
$active_menu_id = '0204';
$wnom_usuario   = $_SESSION['nom_usuario'];

include __DIR__ . '/../layout/head.php';
include __DIR__ . '/../layout/sidebar.php';
include __DIR__ . '/../layout/topbar.php';
?>

<?php renderPageFlash($error_carga ? 'Error al cargar usuarios: ' . $error_carga : null, 'danger'); ?>

<div class="row g-3">
    <!-- Instrucciones -->
    <div class="col-lg-4">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-corporativo py-2">
                <strong style="font-size:0.95rem;"><i class="bi bi-info-circle-fill me-2"></i>Instrucciones</strong>
            </div>
            <div class="card-body p-3">
                <p class="mb-2" style="font-size:0.88rem;">
                    Seleccione un <strong>usuario origen</strong> (cuyo perfil desea copiar) y un
                    <strong>usuario destino</strong> (quien recibirá el perfil).
                </p>
                <span class="guide-badge d-inline-flex">
                    <i class="bi bi-exclamation-triangle-fill"></i>
                    El destino perderá sus menús actuales
                </span>
            </div>
        </div>
    </div>

    <!-- Formulario de copia -->
    <div class="col-lg-8">
        <div class="card shadow-sm border-0">
            <div class="card-header bg-corporativo py-2">
                <strong style="font-size:0.95rem;"><i class="bi bi-files me-2"></i>Copiar Perfil de Menús</strong>
            </div>
            <div class="card-body p-3">
                <form id="form_copiar">
                    <div class="row g-3 mb-3">
                        <div class="col-md-6">
                            <label class="form-label small fw-bold text-muted mb-1" style="font-size:0.75rem;">USUARIO ORIGEN</label>
                            <select id="sel_origen" name="usuario_origen" class="form-select form-select-sm">
                                <option value="">Seleccione un usuario...</option>
                                <?php foreach ($lista_usuarios as $u):
                                    $isAdmin = !empty($u['ind_usuario']);
                                ?>
                                <option value="<?= htmlspecialchars($u['id_usuario']) ?>"
                                        data-admin="<?= $isAdmin ? '1' : '0' ?>"
                                        <?= $isAdmin ? 'disabled' : '' ?>>
                                    <?= htmlspecialchars($u['nom_usuario']) ?><?= $isAdmin ? ' (Administrador)' : '' ?>
                                </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-bold text-muted mb-1" style="font-size:0.75rem;">USUARIO DESTINO</label>
                            <select id="sel_destino" name="usuario_destino" class="form-select form-select-sm">
                                <option value="">Seleccione un usuario...</option>
                                <?php foreach ($lista_usuarios as $u):
                                    $isAdmin = !empty($u['ind_usuario']);
                                ?>
                                <option value="<?= htmlspecialchars($u['id_usuario']) ?>"
                                        data-admin="<?= $isAdmin ? '1' : '0' ?>"
                                        <?= $isAdmin ? 'disabled' : '' ?>>
                                    <?= htmlspecialchars($u['nom_usuario']) ?><?= $isAdmin ? ' (Administrador)' : '' ?>
                                </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <button type="submit" id="btn_copiar" class="btn btn-corporativo w-100 fw-bold" disabled>
                        <i class="bi bi-files me-2"></i>COPIAR MENÚS
                    </button>
                </form>
            </div>
        </div>
    </div>
</div>

<script src="../../js/copiar_menu_usuarios.js"></script>

<?php include __DIR__ . '/../layout/footer.php'; ?>
