(function () {
    /* ---- Estado ---- */
    var num              = "";
    var puerta           = "";
    var step             = 1;
    var esPersonaNueva   = false;
    var fetchResult      = null;
    var fetchPromise     = null;
    var prefetchTimer    = null;

    /* ---- Refs ---- */
    var modalEl  = document.getElementById("documentModal");
    if (!modalEl || typeof bootstrap === "undefined" || !bootstrap.Modal) {
        return;
    }
    if (modalEl.parentElement !== document.body) {
        document.body.appendChild(modalEl);
    }
    var modal    = new bootstrap.Modal(modalEl, {backdrop:"static", keyboard:false});
    var numEl    = document.getElementById("dm-num");
    var btnSig   = document.getElementById("dm-btn-siguiente");
    var btnFinal = document.getElementById("dm-btn-final");
    var stepSub  = document.getElementById("dm-brand-sub");

    /* ---- Pre-fetch vía router portería (misma API que el formulario) ---- */
    function getTipoDoc() {
        var sel = document.getElementById("sel_tipo_doc");
        return sel && sel.value ? sel.value : "CC";
    }

    function prefetch() {
        if (num.length < 5) { fetchResult = null; fetchPromise = null; return; }
        if (typeof SmartcsetIngresoRouter === "undefined") {
            fetchResult = null;
            fetchPromise = null;
            return;
        }
        fetchPromise = SmartcsetIngresoRouter.consultar(num, getTipoDoc())
            .then(function (data) {
                fetchResult = data || null;
                return fetchResult;
            })
            .catch(function () { fetchResult = null; return null; });
    }

    /* ---- Navegar entre pasos ---- */
    function goStep(n) {
        var curr = document.getElementById("dm-slide-" + step);
        var next = document.getElementById("dm-slide-" + n);
        if (!next) return;
        curr.classList.remove("active");
        step = n;
        next.classList.add("active");
        document.querySelectorAll(".dm-step-dot").forEach(function(d) {
            var s = parseInt(d.dataset.s);
            d.className = "dm-step-dot " + (s < n ? "done" : s === n ? "active" : "pending");
        });
        if (stepSub) stepSub.textContent = "Paso " + n + " de 3";
    }

    /* ---- Render paso 1 ---- */
    function renderNum() {
        if (num === "") { numEl.textContent = "— — —"; numEl.classList.add("placeholder"); }
        else            { numEl.textContent = num;     numEl.classList.remove("placeholder"); }
        btnSig.disabled = num.length < 5;
        btnSig.style.opacity = num.length < 5 ? "0.28" : "1";
        btnSig.style.cursor  = num.length < 5 ? "not-allowed" : "pointer";
        /* Pre-fetch: lanzar en cuanto hay 5+ dígitos */
        clearTimeout(prefetchTimer);
        if (num.length >= 5) {
            prefetchTimer = setTimeout(prefetch, 120);
        } else {
            fetchResult = null; fetchPromise = null;
        }
    }

    function showLoading(show) {
        var l = document.getElementById("dm-loading");
        var f = document.getElementById("dm-persona-found");
        var n = document.getElementById("dm-persona-nueva");
        if (l) l.style.display = show ? "flex" : "none";
        if (f) f.style.display = "none";
        if (n) n.style.display = "none";
    }

    function renderStep2(data) {
        var persona = data && data.persona;
        var nomPersona = persona && (persona.nombres || persona.nom_persona || "");
        if (persona && nomPersona) {
            var nombre = (nomPersona + " " + (persona.apellidos || persona.ape_persona || "")).trim();
            var f = document.getElementById("dm-persona-found");
            f.style.display = "block";
            document.getElementById("dm-persona-nombre").textContent    = nombre;
            document.getElementById("dm-persona-tipo-text").textContent = persona.nom_tipo_persona || "Registrado";
            document.getElementById("dm-persona-doc-text").textContent  = getTipoDoc() + " " + num;
            document.getElementById("dm-confirm-name").textContent      = nomPersona.split(" ")[0];

            /* Actualizar formulario principal con los datos reales */
            var fNom = document.getElementById("txt_nombres");
            var fApe = document.getElementById("txt_apellidos");
            var fTip = document.getElementById("sel_tipo_persona");
            if (fNom) { fNom.value = nomPersona; fNom.readOnly = true; }
            if (fApe) { fApe.value = persona.apellidos || persona.ape_persona || ""; fApe.readOnly = true; }
            var idTipo = persona.tipo_persona || persona.id_tipo_persona;
            if (fTip && idTipo) fTip.value = String(idTipo);
        } else {
            var nv = document.getElementById("dm-persona-nueva");
            nv.style.cssText = "display:flex;flex-direction:column;align-items:center;padding:16px var(--dm-pad)";
            /* Liberar campos del formulario para que el usuario los llene */
            var fNom2 = document.getElementById("txt_nombres");
            var fApe2 = document.getElementById("txt_apellidos");
            if (fNom2) { fNom2.value = ""; fNom2.readOnly = false; }
            if (fApe2) { fApe2.value = ""; fApe2.readOnly = false; }
        }
        /* Siempre setear el documento en el formulario */
        var fDoc = document.getElementById("txt_documento");
        var fTipDoc = document.getElementById("sel_tipo_doc");
        if (fDoc) fDoc.value = num;
        if (fTipDoc) {
            var tipoDoc = getTipoDoc();
            var docOpt = Array.from(fTipDoc.options).find(function (o) { return o.value === tipoDoc; });
            if (docOpt) fTipDoc.value = tipoDoc;
        }
    }

    /* ---- Paso 1: teclado pantalla ---- */
    document.querySelectorAll(".dm-k[data-d]").forEach(function(b) {
        b.addEventListener("click", function() {
            if (num.length < 10) { num += this.dataset.d; renderNum(); }
        });
    });
    document.getElementById("dm-del").addEventListener("click", function() {
        num = num.slice(0, -1); renderNum();
    });

    /* ---- Paso 1: teclado físico ---- */
    document.addEventListener("keydown", function(e) {
        if (!modalEl.classList.contains("show")) return;
        if (step === 1) {
            if (e.key >= "0" && e.key <= "9") {
                if (num.length < 10) { num += e.key; renderNum(); }
            } else if (e.key === "Backspace") {
                num = num.slice(0, -1); renderNum();
            } else if (e.key === "Enter" && !btnSig.disabled) {
                btnSig.click();
            }
        } else if (step === 3 && e.key === "Enter" && !btnFinal.disabled) {
            btnFinal.click();
        }
    });

    /* ---- Paso 1 → 2: usar resultado pre-cargado o esperar fetch en vuelo ---- */
    btnSig.addEventListener("click", function() {
        if (fetchResult !== null) {
            /* Resultado ya disponible → paso 2 instantáneo */
            goStep(2);
            showLoading(false);
            renderStep2(fetchResult);
        } else if (fetchPromise !== null) {
            /* Fetch en vuelo → mostrar spinner breve y esperar */
            showLoading(true);
            goStep(2);
            fetchPromise.then(function(data) {
                showLoading(false);
                renderStep2(data);
            });
        } else {
            /* Sin fetch → lanzar ahora y esperar */
            showLoading(true);
            goStep(2);
            prefetch();
            fetchPromise.then(function(data) {
                showLoading(false);
                renderStep2(data);
            });
        }
    });

    /* ---- Paso 2: Sí → paso 3, No → paso 1 ---- */
    function irPaso3() { goStep(3); }
    function irPaso1Reset() {
        num = ""; fetchResult = null; fetchPromise = null;
        renderNum();
        goStep(1);
        showLoading(false);
        var fNom = document.getElementById("txt_nombres");
        var fApe = document.getElementById("txt_apellidos");
        if (fNom) { fNom.value = ""; fNom.readOnly = false; }
        if (fApe) { fApe.value = ""; fApe.readOnly = false; }
        document.getElementById("txt_documento").value = "";
    }

    document.getElementById("dm-btn-si").addEventListener("click", function() {
        esPersonaNueva = false;
        irPaso3();
    });
    document.getElementById("dm-btn-no").addEventListener("click", irPaso1Reset);
    document.getElementById("dm-btn-continuar-nueva").addEventListener("click", function() {
        esPersonaNueva = true;
        irPaso3();
    });
    document.getElementById("dm-btn-no-nueva").addEventListener("click", irPaso1Reset);

    /* ---- Paso 3: seleccionar puerta ---- */
    document.querySelectorAll(".dm-puerta").forEach(function(b) {
        b.addEventListener("click", function() {
            document.querySelectorAll(".dm-puerta").forEach(function(x){ x.classList.remove("selected"); });
            this.classList.add("selected");
            puerta = this.dataset.puerta;
            btnFinal.disabled = false;
        });
    });

    /* ---- Paso 3: confirmar → auto-submit o dejar completar si persona nueva ---- */
    btnFinal.addEventListener("click", function() {
        var hidPuerta = document.getElementById("sel_entrada");
        if (hidPuerta) hidPuerta.value = puerta;
        document.querySelectorAll(".ing-puerta").forEach(function (b) {
            b.classList.toggle("is-selected", b.dataset.puerta === puerta);
        });

        if (esPersonaNueva) {
            /* Persona no registrada: cerrar modal y dejar al operador completar nombres */
            modal.hide();
            setTimeout(function() {
                var f = document.getElementById("txt_nombres");
                if (f) f.focus();
            }, 300);
            return;
        }

        /* Persona conocida: liberar readOnly y registrar vía el mismo flujo del formulario */
        var fNom = document.getElementById("txt_nombres");
        var fApe = document.getElementById("txt_apellidos");
        if (fNom) fNom.readOnly = false;
        if (fApe) fApe.readOnly = false;
        var form = document.getElementById("form_ingreso");
        if (form && typeof form.requestSubmit === "function") {
            form.requestSubmit();
        } else {
            var btnReg = document.getElementById("btn_registrar_ingreso");
            if (btnReg) btnReg.click();
        }
    });

    /* ---- Reset al abrir ---- */
    modalEl.addEventListener("show.bs.modal", function() {
        num = ""; puerta = ""; step = 1; esPersonaNueva = false;
        fetchResult = null; fetchPromise = null;
        clearTimeout(prefetchTimer);
        renderNum();
        showLoading(false);
        document.querySelectorAll(".dm-slide").forEach(function(s){ s.classList.remove("active"); });
        document.getElementById("dm-slide-1").classList.add("active");
        document.querySelectorAll(".dm-step-dot").forEach(function(d,i){
            d.className = "dm-step-dot " + (i === 0 ? "active" : "pending");
        });
        if (stepSub) stepSub.textContent = "Paso 1 de 3";
        if (btnFinal) btnFinal.disabled = true;
    });

    /* ---- Abrir solo con el botón Teclado (no auto al cargar) ---- */
    var btnAbrirKiosk = document.getElementById("btn_abrir_modal_kiosk");
    if (btnAbrirKiosk) {
        btnAbrirKiosk.addEventListener("click", function () { modal.show(); });
    }
})();
