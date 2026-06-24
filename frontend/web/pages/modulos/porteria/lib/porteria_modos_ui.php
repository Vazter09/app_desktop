<?php
/**
 * Barra de modos escáner / foto (ingreso y salida).
 *
 * @var string $pt_contexto 'ingreso'|'salida'
 */
$pt_contexto = $pt_contexto ?? 'ingreso';
?>
<div class="pt-modos-toolbar" data-pt-contexto="<?= htmlspecialchars($pt_contexto) ?>">
    <button type="button" class="pt-modo-btn" id="btn_modo_escaner" aria-pressed="false" title="Optimiza el campo documento para pistola lectora">
        <i class="bi bi-upc-scan" aria-hidden="true"></i> Modo escáner
    </button>
    <button type="button" class="pt-modo-btn" id="btn_modo_foto" aria-pressed="false"
            title="<?= $pt_contexto === 'salida' ? 'Foto opcional al registrar la salida' : 'Foto opcional al registrar el ingreso' ?>">
        <i class="bi bi-camera" aria-hidden="true"></i> Foto
    </button>
</div>
<p id="pt_modo_escaner_hint" class="pt-modo-hint d-none" role="status">
    Listo para leer cédula: el cursor queda en el documento. Escanee y revise el resto del formulario.
</p>
<div id="pt_foto_panel" class="pt-foto-panel d-none" aria-hidden="true">
    <div class="pt-foto-video-wrap">
        <video id="pt_foto_video" playsinline muted autoplay></video>
        <img id="pt_foto_preview" class="d-none" alt="Vista previa de la foto">
    </div>
    <div class="pt-foto-actions">
        <button type="button" class="btn btn-sm btn-outline-secondary" id="pt_foto_capturar">
            <i class="bi bi-camera-fill me-1"></i>Capturar
        </button>
        <button type="button" class="btn btn-sm btn-outline-secondary" id="pt_foto_archivo">
            <i class="bi bi-image me-1"></i>Archivo
        </button>
        <button type="button" class="btn btn-sm btn-outline-danger d-none" id="pt_foto_quitar">
            <i class="bi bi-x-lg me-1"></i>Quitar
        </button>
    </div>
    <input type="file" id="pt_foto_file" accept="image/*" capture="environment" class="d-none">
</div>
<input type="hidden" name="hid_foto_data" id="hid_foto_data" value="">
