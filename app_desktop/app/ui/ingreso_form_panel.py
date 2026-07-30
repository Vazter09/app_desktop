"""
Columna central — réplica desktop del modal web «Nuevo ingreso»
(`frontend/web/pages/modulos/porteria/lib/formulario_ingreso.php`).
"""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk
from typing import Any, Callable

from smartcset_client import SmartcsetApiError, SmartcsetClient, SmartcsetConnectionError
from ui import theme


class IngresoFormPanel(tk.Frame):
    """Formulario de nuevo ingreso embebido (no Toplevel)."""

    def __init__(
        self,
        master: tk.Misc,
        client: SmartcsetClient,
        *,
        on_registrado: Callable[[], None] | None = None,
        on_mensaje_estado: Callable[[str, str], None] | None = None,
        on_ingreso_exitoso: Callable[[dict[str, Any]], None] | None = None,
        on_enriquecer_payload: Callable[[dict[str, Any]], None] | None = None,
    ) -> None:
        super().__init__(master, bg=theme.BG_PANEL, padx=14, pady=12)
        self._client = client
        self._on_registrado = on_registrado
        self._on_mensaje_estado = on_mensaje_estado
        self._on_ingreso_exitoso = on_ingreso_exitoso
        # FacialModal: adjunta embedding/foto si hay rostro en cámara.
        self._on_enriquecer_payload = on_enriquecer_payload
        # True tras pegar visitante desde pistola: evita doble consulta FocusOut.
        self._omitir_consulta_focus_out = False

        self._catalogos: dict[str, Any] = {
            "tipos_doc": [],
            "tipos_persona": [],
            "entradas": [],
        }
        self._tipo_doc_ids: list[str] = []
        self._tipo_persona_map: dict[str, int] = {}
        self._entrada_seleccionada: int = 0
        self._puerta_btns: dict[int, tk.Frame] = {}
        self._persona_existente: dict[str, Any] | None = None
        self._bloqueo_ingreso = False

        self._msg_var = tk.StringVar(value="")
        self._badge_var = tk.StringVar(value="")
        self._documento_var = tk.StringVar()
        self._nombres_var = tk.StringVar()
        self._apellidos_var = tk.StringVar()
        self._obs_var = tk.StringVar()

        self._build()

    # ---- API pública -------------------------------------------------

    def documento(self) -> str:
        return self._documento_var.get().strip()

    def set_documento(self, valor: str) -> None:
        self._documento_var.set(valor)

    def aplicar_visitante_escaneado(
        self,
        documento: str,
        *,
        tipo_doc: str = "CC",
        nombres: str = "",
        apellidos: str = "",
    ) -> None:
        """Visitante no registrado: deja el documento (y nombres si PDF417)."""
        # Evitar que FocusOut dispare consulta al reenfocar el campo.
        self._omitir_consulta_focus_out = True
        if tipo_doc and tipo_doc in self._tipo_doc_ids:
            self._tipo_doc_combo.set(tipo_doc)
        self._documento_var.set(documento)
        if nombres:
            self._nombres_var.set(nombres)
        if apellidos:
            self._apellidos_var.set(apellidos)
        self._persona_existente = None
        self._bloqueo_ingreso = False
        self._set_campos_editables(True)
        self._badge_var.set("Persona nueva — complete nombres y tipo")
        self._badge_lbl.configure(fg=theme.CYAN)
        if nombres and apellidos:
            self._msg_var.set("Datos leídos del documento — verifique y registre.")
        else:
            self._msg_var.set("")
        self.focus_documento()

    def focus_documento(self) -> None:
        self._documento_entry.focus_set()

    def mostrar_error_catalogos(self, mensaje: str) -> None:
        """Muestra fallo de carga de catálogos en el propio formulario."""
        self._msg_var.set(mensaje)
        self._badge_var.set("")
        self._bloqueo_ingreso = True

    def cargar_catalogos(self, catalogos: dict[str, Any]) -> None:
        self._catalogos = catalogos or self._catalogos
        tipos_doc = self._catalogos.get("tipos_doc", [])
        self._tipo_doc_ids = [str(t.get("id") or "") for t in tipos_doc if t.get("id")]
        self._tipo_doc_combo.configure(values=self._tipo_doc_ids)
        if self._tipo_doc_ids:
            self._tipo_doc_combo.set(self._tipo_doc_ids[0])

        tipos_persona = self._catalogos.get("tipos_persona", [])
        self._tipo_persona_map = {
            str(t.get("nombre") or ""): int(t.get("id") or 0)
            for t in tipos_persona
            if t.get("nombre")
        }
        # Evitar clave vacía que deja el combo sin opciones visibles.
        self._tipo_persona_map.pop("", None)
        nombres = list(self._tipo_persona_map.keys())
        self._tipo_persona_combo.configure(values=nombres)
        if nombres:
            self._tipo_persona_combo.set(nombres[0])

        self._rebuild_puertas()
        if self._tipo_doc_ids and nombres:
            self._msg_var.set("")
            self._bloqueo_ingreso = False
        else:
            self.mostrar_error_catalogos(
                "Catálogos incompletos (tipos de documento/persona)."
            )

    def aplicar_persona_identificada(self, persona: dict[str, Any]) -> None:
        """Rellena el formulario tras match biométrico (persona existente)."""
        doc = str(
            persona.get("documento")
            or persona.get("num_docum")
            or persona.get("id_persona")
            or ""
        )
        tipo = str(persona.get("tipo_doc") or persona.get("id_tipo_docum") or "CC")
        if doc:
            self._documento_var.set(doc)
        if tipo in self._tipo_doc_ids:
            self._tipo_doc_combo.set(tipo)
        self._nombres_var.set(str(persona.get("nombres") or ""))
        self._apellidos_var.set(str(persona.get("apellidos") or ""))
        nom_tipo = str(persona.get("nom_tipo_persona") or "")
        if nom_tipo and nom_tipo in self._tipo_persona_map:
            self._tipo_persona_combo.set(nom_tipo)
        self._persona_existente = persona
        self._set_campos_editables(False)
        self._badge_var.set("Persona encontrada en el sistema")
        self._msg_var.set("")
        self._bloqueo_ingreso = False

    def limpiar(self) -> None:
        self._documento_var.set("")
        self._nombres_var.set("")
        self._apellidos_var.set("")
        self._obs_var.set("")
        self._persona_existente = None
        self._bloqueo_ingreso = False
        self._badge_var.set("")
        self._msg_var.set("")
        self._set_campos_editables(True)
        if self._tipo_doc_ids:
            self._tipo_doc_combo.set(self._tipo_doc_ids[0])
        nombres = list(self._tipo_persona_map.keys())
        if nombres:
            self._tipo_persona_combo.set(nombres[0])

    # ---- UI ----------------------------------------------------------

    def _build(self) -> None:
        # Pie anclado abajo
        foot = tk.Frame(self, bg=theme.BG_PANEL)
        foot.pack(side="bottom", fill="x")
        ttk.Label(
            foot,
            textvariable=self._msg_var,
            style="CardMuted.TLabel",
            wraplength=280,
        ).pack(anchor="w", pady=(0, 6))

        btns = ttk.Frame(foot, style="Card.TFrame")
        btns.pack(fill="x")
        btns.columnconfigure(0, weight=1)
        ttk.Button(
            btns,
            text="Registrar ingreso",
            style="Primary.TButton",
            command=self._registrar,
        ).grid(row=0, column=0, sticky="ew", ipady=2)

        body = tk.Frame(self, bg=theme.BG_PANEL)
        body.pack(side="top", fill="both", expand=True)

        # Observación anclada abajo del body: no se aplasta si falta altura.
        obs_wrap = tk.Frame(body, bg=theme.BG_PANEL)
        obs_wrap.pack(side="bottom", fill="x")
        ttk.Label(
            obs_wrap,
            text="Observación / Novedad",
            style="Card.TLabel",
        ).pack(anchor="w", pady=(8, 4))
        self._obs_entry = ttk.Entry(
            obs_wrap, textvariable=self._obs_var, font=theme.FONT_LOGIN_LABEL
        )
        self._obs_entry.pack(fill="x", ipady=8)

        head = tk.Frame(body, bg=theme.BG_PANEL)
        head.pack(fill="x")
        ttk.Label(
            head,
            text="👤  Nuevo ingreso",
            style="Card.TLabel",
            font=theme.FONT_BODY_BOLD,
        ).pack(side="left")

        ttk.Label(body, text="Documento de identidad", style="Card.TLabel").pack(
            anchor="w", pady=(10, 2)
        )
        doc_row = tk.Frame(body, bg=theme.BG_PANEL)
        doc_row.pack(fill="x")
        self._tipo_doc_combo = ttk.Combobox(
            doc_row, width=6, state="readonly", font=theme.FONT_LOGIN_LABEL
        )
        self._tipo_doc_combo.pack(side="left", padx=(0, 6))
        self._documento_entry = ttk.Entry(
            doc_row, textvariable=self._documento_var, font=theme.FONT_LOGIN_LABEL
        )
        self._documento_entry.pack(side="left", fill="x", expand=True, ipady=4)
        self._documento_entry.bind("<Return>", self._on_documento_enter)
        self._documento_entry.bind("<FocusOut>", self._on_documento_focus_out)
        # Escritura manual / Enter / FocusOut → consultar y cargar form.
        # Pistola QR/barras la maneja FacialRecognitionPanel (modal), no aquí.

        self._badge_lbl = tk.Label(
            body,
            textvariable=self._badge_var,
            bg=theme.BG_PANEL,
            fg=theme.CYAN,
            font=theme.FONT_LABEL_SMALL,
            anchor="w",
        )
        self._badge_lbl.pack(fill="x", pady=(2, 0))

        ttk.Label(body, text="Tipo de persona", style="Card.TLabel").pack(
            anchor="w", pady=(8, 2)
        )
        self._tipo_persona_combo = ttk.Combobox(
            body, state="readonly", font=theme.FONT_LOGIN_LABEL
        )
        self._tipo_persona_combo.pack(fill="x", ipady=4)

        # Separación moderada (deja aire para el badge sin abrir un hueco grande).
        ttk.Label(body, text="Datos de la persona", style="Card.TLabel").pack(
            anchor="w", pady=(14, 2)
        )
        nom_row = tk.Frame(body, bg=theme.BG_PANEL)
        nom_row.pack(fill="x")
        nom_row.columnconfigure(0, weight=1, uniform="cols_form")
        nom_row.columnconfigure(1, weight=1, uniform="cols_form")

        left = tk.Frame(nom_row, bg=theme.BG_PANEL)
        left.grid(row=0, column=0, sticky="ew", padx=(0, 4))
        ttk.Label(left, text="Nombres", style="CardMuted.TLabel").pack(anchor="w")
        self._nombres_entry = ttk.Entry(
            left, textvariable=self._nombres_var, font=theme.FONT_LOGIN_LABEL
        )
        self._nombres_entry.pack(fill="x", ipady=4)

        right = tk.Frame(nom_row, bg=theme.BG_PANEL)
        right.grid(row=0, column=1, sticky="ew", padx=(4, 0))
        ttk.Label(right, text="Apellidos", style="CardMuted.TLabel").pack(anchor="w")
        self._apellidos_entry = ttk.Entry(
            right, textvariable=self._apellidos_var, font=theme.FONT_LOGIN_LABEL
        )
        self._apellidos_entry.pack(fill="x", ipady=4)

        ttk.Label(body, text="Puerta de ingreso", style="Card.TLabel").pack(
            anchor="w", pady=(10, 4)
        )
        self._puertas_frame = tk.Frame(body, bg=theme.BG_PANEL)
        self._puertas_frame.pack(fill="x")

    def _rebuild_puertas(self) -> None:
        for child in self._puertas_frame.winfo_children():
            child.destroy()
        self._puerta_btns.clear()
        entradas = [
            e
            for e in (self._catalogos.get("entradas") or [])
            if "parqueadero" not in str(e.get("nombre") or "").casefold()
        ]
        if not entradas:
            ttk.Label(
                self._puertas_frame,
                text="Sin puertas configuradas.",
                style="CardMuted.TLabel",
                foreground=theme.ERROR,
            ).pack(anchor="w")
            self._entrada_seleccionada = 0
            return

        # Misma rejilla 50/50 y paddings que Nombres | Apellidos.
        row = tk.Frame(self._puertas_frame, bg=theme.BG_PANEL)
        row.pack(fill="x")
        row.columnconfigure(0, weight=1, uniform="cols_form")
        row.columnconfigure(1, weight=1, uniform="cols_form")

        for idx, entrada in enumerate(entradas):
            eid = int(entrada.get("id") or 0)
            nombre = str(entrada.get("nombre") or f"Entrada {eid}")
            col = idx % 2
            fila = idx // 2
            if col == 0:
                row.rowconfigure(fila, weight=0, minsize=48)

            pad = (0, 4) if col == 0 else (4, 0)
            card = tk.Frame(
                row,
                bg="#0f1712",
                highlightthickness=2,
                highlightbackground=theme.BORDER,
                cursor="hand2",
                padx=8,
                pady=8,
                height=48,
            )
            card.grid(row=fila, column=col, sticky="nsew", padx=pad)
            card.grid_propagate(False)

            inner = tk.Frame(card, bg="#0f1712")
            inner.pack(fill="both", expand=True)
            num = tk.Label(
                inner,
                text=str(eid),
                bg=theme.V_OSCURO,
                fg=theme.TEXT_PRIMARY,
                font=theme.FONT_BODY_BOLD,
                width=3,
            )
            num.pack(side="left", padx=(0, 8))
            nom = tk.Label(
                inner,
                text=nombre,
                bg="#0f1712",
                fg=theme.TEXT_PRIMARY,
                font=theme.FONT_LABEL_SMALL,
                anchor="w",
                justify="left",
            )
            nom.pack(side="left", fill="x", expand=True)
            for w in (card, inner, num, nom):
                w.bind("<Button-1>", lambda _e, i=eid: self._seleccionar_puerta(i))
            self._puerta_btns[eid] = card
            if idx == 0:
                self._seleccionar_puerta(eid)

    def _seleccionar_puerta(self, id_entrada: int) -> None:
        self._entrada_seleccionada = id_entrada
        for eid, card in self._puerta_btns.items():
            selected = eid == id_entrada
            card.configure(
                highlightbackground=theme.CYAN if selected else theme.BORDER,
                highlightthickness=2,
                bg="#142018" if selected else "#0f1712",
            )
            bg = card.cget("bg")
            for child in card.winfo_children():
                try:
                    child.configure(bg=bg)
                except tk.TclError:
                    pass
                for sub in child.winfo_children():
                    # El número conserva el verde corporativo.
                    if isinstance(sub, tk.Label) and str(sub.cget("width")) == "3":
                        continue
                    try:
                        sub.configure(bg=bg)
                    except tk.TclError:
                        pass

    def _set_campos_editables(self, editable: bool) -> None:
        estado = "normal" if editable else "disabled"
        self._nombres_entry.configure(state=estado)
        self._apellidos_entry.configure(state=estado)
        self._tipo_persona_combo.configure(
            state="readonly" if editable else "disabled"
        )

    # ---- Eventos -----------------------------------------------------

    def _on_documento_enter(self, _event: tk.Event | None = None) -> str | None:
        """Enter: consulta id_persona y carga datos en el formulario."""
        self._omitir_consulta_focus_out = True
        self._consultar_documento()
        return "break"

    def _on_documento_focus_out(self, _event: tk.Event | None = None) -> None:
        """Al salir del campo: misma consulta (si no se acaba de consultar)."""
        if self._omitir_consulta_focus_out:
            self._omitir_consulta_focus_out = False
            return
        if not self.documento():
            return
        self._consultar_documento()

    def tipo_doc_actual(self) -> str:
        """Tipo de documento seleccionado en el formulario (CC/TI/CE/…)."""
        val = self._tipo_doc_combo.get().strip()
        return val or "CC"

    def set_tipo_doc(self, tipo: str) -> None:
        """Sincroniza el combo si el tipo existe en el catálogo cargado."""
        tipo = (tipo or "").strip()
        if tipo and tipo in self._tipo_doc_ids:
            self._tipo_doc_combo.set(tipo)

    def _tipo_doc_actual(self) -> str:
        return self.tipo_doc_actual()

    def _consultar_documento(self) -> None:
        documento = self.documento()
        if not documento:
            return
        tipo_doc = self._tipo_doc_actual()
        try:
            resultado = self._client.ingreso_consultar(documento, tipo_doc)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._msg_var.set(str(exc))
            return

        if resultado.get("ingreso_abierto") is not None:
            self._bloqueo_ingreso = True
            self._persona_existente = resultado.get("persona")
            self._badge_var.set("Ya tiene ingreso abierto")
            self._badge_lbl.configure(fg=theme.ERROR)
            self._msg_var.set(
                "No se puede registrar otro ingreso hasta registrar la salida."
            )
            persona = resultado.get("persona") or {}
            if persona:
                self._nombres_var.set(str(persona.get("nombres") or ""))
                self._apellidos_var.set(str(persona.get("apellidos") or ""))
                self._set_campos_editables(False)
            return

        if resultado.get("en_espera_reingreso"):
            self._bloqueo_ingreso = True
            persona = resultado.get("persona") or {}
            self._persona_existente = persona or None
            rest = int(resultado.get("segundos_restantes_reingreso") or 0)
            min_rest = max(1, (rest + 59) // 60)
            self._badge_var.set("Espere para reingresar")
            self._badge_lbl.configure(fg=theme.ERROR)
            self._msg_var.set(
                f"Salida reciente: espere ~{min_rest} min para un nuevo ingreso."
            )
            if persona:
                self._nombres_var.set(str(persona.get("nombres") or ""))
                self._apellidos_var.set(str(persona.get("apellidos") or ""))
                self._set_campos_editables(False)
            return

        self._bloqueo_ingreso = False
        self._badge_lbl.configure(fg=theme.CYAN)
        persona = resultado.get("persona")
        if persona is None:
            self._persona_existente = None
            self._badge_var.set("Persona nueva — complete nombres y tipo")
            self._set_campos_editables(True)
            self._msg_var.set("")
            return

        self.aplicar_persona_identificada(
            {
                **persona,
                "documento": documento,
                "tipo_doc": tipo_doc,
                "nombres": persona.get("nombres"),
                "apellidos": persona.get("apellidos"),
                "nom_tipo_persona": persona.get("nom_tipo_persona"),
                "tipo_persona": persona.get("tipo_persona"),
            }
        )
        self._msg_var.set("Datos cargados desde la base de datos.")

    def _registrar(self) -> None:
        if self._bloqueo_ingreso:
            self._msg_var.set(
                "Esta persona ya tiene ingreso abierto. Registre la salida primero."
            )
            return
        documento = self.documento()
        nombres = self._nombres_var.get().strip()
        apellidos = self._apellidos_var.get().strip()
        if not documento:
            self._msg_var.set("Ingrese el número de documento.")
            self.focus_documento()
            return
        if not nombres or not apellidos:
            self._msg_var.set("Complete nombres y apellidos.")
            return
        if not self._entrada_seleccionada:
            self._msg_var.set("Seleccione una puerta de ingreso.")
            return

        tipo_persona = self._tipo_persona_map.get(self._tipo_persona_combo.get(), 0)
        if self._persona_existente and not tipo_persona:
            tipo_persona = int(self._persona_existente.get("tipo_persona") or 0)

        payload = {
            "tipo_doc": self._tipo_doc_actual(),
            "documento": documento,
            "nombres": nombres,
            "apellidos": apellidos,
            "tipo_persona": tipo_persona,
            "id_entrada": self._entrada_seleccionada,
            "observaciones": self._obs_var.get().strip(),
            "metodo_aut": 1,
        }
        if self._on_enriquecer_payload is not None:
            self._on_enriquecer_payload(payload)
        try:
            resultado = self._client.ingreso_registrar(payload)
        except (SmartcsetApiError, SmartcsetConnectionError) as exc:
            self._msg_var.set(str(exc))
            if self._on_mensaje_estado is not None:
                self._on_mensaje_estado(str(exc), theme.ERROR)
            return

        id_ingreso = resultado.get("id_ingreso") if isinstance(resultado, dict) else None
        msg = f"Ingreso registrado: {nombres} {apellidos}."
        if id_ingreso:
            msg = f"Ingreso #{id_ingreso} registrado: {nombres} {apellidos}."
        self._msg_var.set(msg)
        if self._on_mensaje_estado is not None:
            self._on_mensaje_estado(msg, theme.SUCCESS)

        persona_datos: dict[str, Any] = {
            "documento": documento,
            "tipo_doc": self._tipo_doc_actual(),
            "nombres": nombres,
            "apellidos": apellidos,
            "tipo_persona": tipo_persona,
            "nom_tipo_persona": self._tipo_persona_combo.get() or "",
            "estado_formacion": (
                (self._persona_existente or {}).get("estado_formacion")
                or (self._persona_existente or {}).get("ind_etdo_formacion")
            ),
            "id_ficha": (self._persona_existente or {}).get("id_ficha"),
            "ind_estado_instructor": (self._persona_existente or {}).get(
                "ind_estado_instructor"
            ),
            "ind_tipo_contrato": (self._persona_existente or {}).get(
                "ind_tipo_contrato"
            ),
            # Sin enrolamiento facial: el panel deja la caja oscura vacía.
            "foto_base64": (self._persona_existente or {}).get("foto_base64"),
        }
        # Tras registrar, reconsultar para traer campos de tab_instructores
        # (si ya existe fila) y tipo/nombre canónicos de BD.
        try:
            consulta = self._client.ingreso_consultar(
                documento, self._tipo_doc_actual()
            )
            persona_api = consulta.get("persona") or {}
            if persona_api:
                for key in (
                    "nombres",
                    "apellidos",
                    "tipo_persona",
                    "nom_tipo_persona",
                    "ind_estado_instructor",
                    "ind_tipo_contrato",
                    "id_ficha",
                    "estado_formacion",
                ):
                    if persona_api.get(key) is not None:
                        persona_datos[key] = persona_api.get(key)
        except (SmartcsetApiError, SmartcsetConnectionError):
            pass

        era_existente = self._persona_existente is not None
        persona_datos["_persona_existente"] = era_existente

        if self._on_ingreso_exitoso is not None:
            self._on_ingreso_exitoso(persona_datos)
            return

        if self._on_registrado is not None:
            self._on_registrado()
        self.limpiar()
