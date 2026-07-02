(function () {
    var num              = "";
    var puerta           = "";
    var step             = 1;
    var puedeSalir       = false;
    var fetchResult      = null;
    var fetchPromise     = null;
    var prefetchTimer    = null;

    var modalEl  = document.getElementById("documentModal");
    if (!modalEl || typeof bootstrap === "undefined" || !bootstrap.Modal) {
        return;
    }
    if (modalEl.parentElement !== document.body) {
        document.body.appendChild(modalEl);
    }
    var modal    = new bootstrap.Modal(modalEl, {backdrop:"static", keyboard:false});
    var isDesktopKiosk = window.matchMedia("(min-width: 768px)").matches;
    var numEl    = document.getElementById("dm-num");
    var btnSig   = document.getElementById("dm-btn-siguiente");
    var btnFinal = document.getElementById("dm-btn-final");
    var stepSub  = document.getElementById("dm-brand-sub");

    function prefetch() {
        if (num.length < 5) { fetchResult = null; fetchPromise = null; return; }
        if (typeof SmartcsetSalidaRouter === 'undefined') {
            fetchResult = null;
            fetchPromise = null;
            return;
        }
        fetchPromise = SmartcsetSalidaRouter.consultar(num, "CC")
            .then(function(data){
                fetchResult = data || null;
                return fetchResult;
            })
            .catch(function(){ fetchResult = null; return null; });
    }

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

    function renderNum() {
        if (num === "") { numEl.textContent = "— — —"; numEl.classList.add("placeholder"); }
        else            { numEl.textContent = num;     numEl.classList.remove("placeholder"); }
        btnSig.disabled = num.length < 5;
        btnSig.style.opacity = num.length < 5 ? "0.28" : "1";
        btnSig.style.cursor  = num.length < 5 ? "not-allowed" : "pointer";
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
        var s = document.getElementById("dm-persona-sin-ingreso");
        if (l) l.style.display = show ? "flex" : "none";
        if (f) f.style.display = "none";
        if (s) s.style.display = "none";
    }

    function aplicarDatosFormulario(data) {
        var persona = data && data.persona;
        var ingreso = data && data.ingreso_abierto;
        var fDoc = document.getElementById("txt_documento");
        var fTipDoc = document.getElementById("sel_tipo_doc");
        var fNom = document.getElementById("txt_nombres");
        var fApe = document.getElementById("txt_apellidos");
        var fTip = document.getElementById("sel_tipo_persona");
        var hidIngreso = document.getElementById("hid_id_ingreso");

        if (fDoc) fDoc.value = num;
        if (fTipDoc) {
            var ccOpt = Array.from(fTipDoc.options).find(function(o){ return o.value === "CC"; });
            if (ccOpt) fTipDoc.value = "CC";
        }
        if (persona) {
            if (fNom) fNom.value = persona.nombres || persona.nom_persona || "";
            if (fApe) fApe.value = persona.apellidos || persona.ape_persona || "";
            if (fTip && persona.id_tipo_persona) fTip.value = String(persona.id_tipo_persona);
        }
        if (hidIngreso && ingreso) hidIngreso.value = String(ingreso.id_ingreso);
    }

    function renderStep2(data) {
        puedeSalir = Boolean(data && data.puede_salir);
        var persona = data && data.persona;
        var ingreso = data && data.ingreso_abierto;

        if (puedeSalir && (persona || ingreso)) {
            var nombre = persona
                ? ((persona.nombres || persona.nom_persona || "") + " " + (persona.apellidos || persona.ape_persona || "")).trim()
                : (((ingreso.nombres || ingreso.nom_persona || "") + " " + (ingreso.apellidos || ingreso.ape_persona || "")).trim());
            var tipoNom = (persona && persona.nom_tipo_persona)
                || (ingreso && ingreso.nom_tipo_persona)
                || "Registrado";
            var f = document.getElementById("dm-persona-found");
            f.style.display = "block";
            document.getElementById("dm-persona-nombre").textContent    = nombre;
            document.getElementById("dm-persona-tipo-text").textContent = tipoNom;
            document.getElementById("dm-persona-doc-text").textContent  = "CC " + num;
            document.getElementById("dm-confirm-name").textContent      = (persona && (persona.nombres || persona.nom_persona))
                ? (persona.nombres || persona.nom_persona).split(" ")[0]
                : nombre.split(" ")[0];
            aplicarDatosFormulario(data);
        } else {
            var s = document.getElementById("dm-persona-sin-ingreso");
            s.style.cssText = "display:flex;flex-direction:column;align-items:center;padding:16px var(--dm-pad)";
            document.getElementById("hid_id_ingreso").value = "";
        }
    }

    document.querySelectorAll(".dm-k[data-d]").forEach(function(b) {
        b.addEventListener("click", function() {
            if (num.length < 10) { num += this.dataset.d; renderNum(); }
        });
    });
    document.getElementById("dm-del").addEventListener("click", function() {
        num = num.slice(0, -1); renderNum();
    });

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

    btnSig.addEventListener("click", function() {
        if (fetchResult !== null) {
            goStep(2);
            showLoading(false);
            renderStep2(fetchResult);
        } else if (fetchPromise !== null) {
            showLoading(true);
            goStep(2);
            fetchPromise.then(function(data) {
                showLoading(false);
                renderStep2(data);
            });
        } else {
            showLoading(true);
            goStep(2);
            prefetch();
            fetchPromise.then(function(data) {
                showLoading(false);
                renderStep2(data);
            });
        }
    });

    function irPaso3() {
        if (!puedeSalir) return;
        goStep(3);
    }
    function irPaso1Reset() {
        num = ""; puedeSalir = false;
        fetchResult = null; fetchPromise = null;
        renderNum();
        goStep(1);
        showLoading(false);
        document.getElementById("txt_documento").value = "";
        document.getElementById("hid_id_ingreso").value = "";
        document.getElementById("txt_nombres").value = "";
        document.getElementById("txt_apellidos").value = "";
    }

    document.getElementById("dm-btn-si").addEventListener("click", irPaso3);
    document.getElementById("dm-btn-no").addEventListener("click", irPaso1Reset);
    document.getElementById("dm-btn-no-sin-ingreso").addEventListener("click", irPaso1Reset);

    document.querySelectorAll(".dm-puerta").forEach(function(b) {
        b.addEventListener("click", function() {
            document.querySelectorAll(".dm-puerta").forEach(function(x){ x.classList.remove("selected"); });
            this.classList.add("selected");
            puerta = this.dataset.puerta;
            btnFinal.disabled = false;
        });
    });

    btnFinal.addEventListener("click", function() {
        var hidPuerta = document.getElementById("sel_entrada");
        if (hidPuerta) hidPuerta.value = puerta;
        if (fetchResult) aplicarDatosFormulario(fetchResult);

        if (!puedeSalir || typeof SmartcsetSalidaRouter === "undefined") {
            return;
        }

        btnFinal.disabled = true;
        SmartcsetSalidaRouter.registrar({
            documento: num,
            tipo_doc: "CC",
            metodo_aut: Number(document.getElementById("hid_metodo_aut")?.value || 1),
            observaciones: document.getElementById("txt_observaciones")?.value || "",
            foto_base64: document.getElementById("hid_foto_data")?.value || "",
        }).then(function() {
            window.location.reload();
        }).catch(function(err) {
            btnFinal.disabled = false;
            if (window.SmartcsetToast) {
                window.SmartcsetToast.show("danger", "No se pudo completar", err.message);
            } else {
                alert(err.message);
            }
        });
    });

    modalEl.addEventListener("show.bs.modal", function() {
        num = ""; puerta = ""; step = 1; puedeSalir = false;
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

    var btnAbrirKiosk = document.getElementById("btn_abrir_modal_kiosk");
    if (btnAbrirKiosk) {
        btnAbrirKiosk.addEventListener("click", function () { modal.show(); });
    }
    if (isDesktopKiosk) {
        modal.show();
    }
})();
