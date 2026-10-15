"""
Tokens de color reales de SmartCSET — leídos directamente de
`tab_config_sistema` en la BD real (192.168.1.71), NO valores por
defecto inventados. Si el admin cambia los colores corporativos desde
el panel de configuración, este archivo debe volver a sincronizarse
(ver REGLAS_APP_ESCRITORIO_SGI.md, sección 8 y Pilar 2 — Congruencia).

Réplica en Tkinter/ttk de los mismos derivados que
backend/core/AppConfig.php calcula para el tema oscuro
(darkenHex/lightenHex/hexToRgba) — sin usar CSS, con los valores ya
calculados a mano.
"""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk

# ---- Colores corporativos reales (tab_config_sistema) ----
V_OSCURO = "#2E4731"
V_OLIVA = "#6B8E23"

# ---- Superficies tema oscuro (derivadas, igual que AppConfig) ----
BG_DEEP = "#131e15"
BG_CARD = "#1b2a1d"
BG_PANEL = "#1b2a1d"
SIDEBAR_BG = "#131e15"

CYAN = "#00e5b0"
TEXT_PRIMARY = "#e8f4ff"
TEXT_MUTED = "#bacbaf"
BORDER = "#3f4a2b"
ERROR = "#ff3c6e"
SUCCESS = "#00e5b0"

# Tamaños base (diseño). ``apply_theme`` los escala vía ui.responsive.
_FONT_BODY_BASE = ("Segoe UI", 10)
_FONT_BODY_BOLD_BASE = ("Segoe UI", 10, "bold")
_FONT_PRIMARY_BUTTON_BASE = ("Segoe UI", 11, "bold")
_FONT_TITLE_BASE = ("Segoe UI", 15, "bold")
_FONT_LOGIN_TITLE_BASE = ("Segoe UI", 22, "bold")
_FONT_LOGIN_LABEL_BASE = ("Segoe UI", 12)
_FONT_LOGIN_INPUT_BASE = ("Segoe UI", 14)
_FONT_LOGIN_BUTTON_BASE = ("Segoe UI", 12, "bold")
_FONT_TOPBAR_BREADCRUMB_BASE = ("Segoe UI", 13, "bold")
_FONT_TOPBAR_USER_BASE = ("Segoe UI", 12)
_TOPBAR_HEIGHT_BASE = 58
_FONT_LABEL_SMALL_BASE = ("Segoe UI", 8)

# Valores activos (tras apply_theme + responsive).
FONT_BODY = _FONT_BODY_BASE
FONT_BODY_BOLD = _FONT_BODY_BOLD_BASE
FONT_PRIMARY_BUTTON = _FONT_PRIMARY_BUTTON_BASE
FONT_TITLE = _FONT_TITLE_BASE
FONT_LOGIN_TITLE = _FONT_LOGIN_TITLE_BASE
FONT_LOGIN_LABEL = _FONT_LOGIN_LABEL_BASE
FONT_LOGIN_INPUT = _FONT_LOGIN_INPUT_BASE
FONT_LOGIN_BUTTON = _FONT_LOGIN_BUTTON_BASE
FONT_TOPBAR_BREADCRUMB = _FONT_TOPBAR_BREADCRUMB_BASE
FONT_TOPBAR_USER = _FONT_TOPBAR_USER_BASE
TOPBAR_HEIGHT = _TOPBAR_HEIGHT_BASE
FONT_LABEL_SMALL = _FONT_LABEL_SMALL_BASE


def _aplicar_escala_fuentes() -> None:
    """Actualiza fuentes/altura topbar según ui.responsive (cambio «responsive»)."""
    global FONT_BODY, FONT_BODY_BOLD, FONT_PRIMARY_BUTTON, FONT_TITLE
    global FONT_LOGIN_TITLE, FONT_LOGIN_LABEL, FONT_LOGIN_INPUT, FONT_LOGIN_BUTTON
    global FONT_TOPBAR_BREADCRUMB, FONT_TOPBAR_USER, TOPBAR_HEIGHT
    global FONT_LABEL_SMALL

    from ui.responsive import sfont, sx

    FONT_BODY = sfont(_FONT_BODY_BASE)
    FONT_BODY_BOLD = sfont(_FONT_BODY_BOLD_BASE)
    FONT_PRIMARY_BUTTON = sfont(_FONT_PRIMARY_BUTTON_BASE)
    FONT_TITLE = sfont(_FONT_TITLE_BASE)
    FONT_LOGIN_TITLE = sfont(_FONT_LOGIN_TITLE_BASE)
    FONT_LOGIN_LABEL = sfont(_FONT_LOGIN_LABEL_BASE)
    FONT_LOGIN_INPUT = sfont(_FONT_LOGIN_INPUT_BASE)
    FONT_LOGIN_BUTTON = sfont(_FONT_LOGIN_BUTTON_BASE)
    FONT_TOPBAR_BREADCRUMB = sfont(_FONT_TOPBAR_BREADCRUMB_BASE)
    FONT_TOPBAR_USER = sfont(_FONT_TOPBAR_USER_BASE)
    TOPBAR_HEIGHT = sx(_TOPBAR_HEIGHT_BASE)
    FONT_LABEL_SMALL = sfont(_FONT_LABEL_SMALL_BASE)


def apply_theme(root: tk.Misc) -> ttk.Style:
    """Configura ttk.Style con los tokens reales — se llama una vez al
    iniciar la app, antes de construir cualquier vista."""
    _aplicar_escala_fuentes()
    style = ttk.Style(root)
    style.theme_use("clam")

    root.configure(bg=BG_DEEP)

    style.configure("App.TFrame", background=BG_DEEP)
    style.configure("Card.TFrame", background=BG_CARD)

    style.configure(
        "App.TLabel", background=BG_DEEP, foreground=TEXT_PRIMARY, font=FONT_BODY
    )
    style.configure(
        "Card.TLabel", background=BG_CARD, foreground=TEXT_PRIMARY, font=FONT_BODY
    )
    style.configure(
        "Muted.TLabel", background=BG_DEEP, foreground=TEXT_MUTED, font=FONT_BODY
    )
    style.configure(
        "CardMuted.TLabel", background=BG_CARD, foreground=TEXT_MUTED, font=FONT_BODY
    )
    style.configure(
        "Title.TLabel", background=BG_DEEP, foreground=TEXT_PRIMARY, font=FONT_TITLE
    )
    style.configure(
        "LoginTitle.TLabel",
        background=BG_CARD,
        foreground=TEXT_PRIMARY,
        font=FONT_LOGIN_TITLE,
    )
    style.configure(
        "LoginField.TLabel",
        background=BG_CARD,
        foreground=TEXT_MUTED,
        font=FONT_LOGIN_LABEL,
    )
    style.configure(
        "LoginError.TLabel",
        background=BG_CARD,
        foreground=ERROR,
        font=FONT_LOGIN_LABEL,
    )
    style.configure(
        "Login.TEntry",
        fieldbackground="#0f1712",
        foreground=TEXT_PRIMARY,
        font=FONT_LOGIN_INPUT,
        padding=(12, 10),
    )
    style.configure(
        "LoginPrimary.TButton",
        background=V_OLIVA,
        foreground="#ffffff",
        font=FONT_LOGIN_BUTTON,
        borderwidth=0,
        padding=(18, 14),
    )
    style.map(
        "LoginPrimary.TButton",
        background=[("active", V_OSCURO), ("disabled", BORDER)],
    )
    style.configure(
        "Primary.TButton",
        background=V_OLIVA,
        foreground="#ffffff",
        font=FONT_PRIMARY_BUTTON,
        borderwidth=0,
        padding=(14, 8),
    )
    style.map(
        "Primary.TButton",
        background=[("active", V_OSCURO), ("disabled", BORDER)],
    )

    style.configure(
        "Logout.TButton",
        background=BG_PANEL,
        foreground=TEXT_MUTED,
        font=FONT_BODY,
        borderwidth=1,
        padding=(10, 6),
    )
    style.configure(
        "TopbarLogout.TButton",
        background=BG_PANEL,
        foreground=TEXT_MUTED,
        font=FONT_TOPBAR_USER,
        borderwidth=1,
        padding=(14, 8),
    )
    style.map(
        "TopbarLogout.TButton",
        foreground=[("active", ERROR)],
    )
    style.map(
        "Logout.TButton",
        foreground=[("active", ERROR)],
    )

    style.configure(
        "Nav.TButton",
        background=SIDEBAR_BG,
        foreground=TEXT_PRIMARY,
        font=FONT_BODY,
        borderwidth=0,
        anchor="w",
        padding=(14, 9),
    )
    style.map(
        "Nav.TButton",
        background=[("active", "#22331f")],
    )

    style.configure("TEntry", fieldbackground="#0f1712", foreground=TEXT_PRIMARY)

    return style
