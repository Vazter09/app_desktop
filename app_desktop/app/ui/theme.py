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
SIDEBAR_BG_DEEP = "#0d140e"

CYAN = "#00e5b0"
TEXT_PRIMARY = "#e8f4ff"
TEXT_MUTED = "#bacbaf"
BORDER = "#3f4a2b"
ERROR = "#ff3c6e"
SUCCESS = "#00e5b0"

FONT_BODY = ("Segoe UI", 10)
FONT_BODY_BOLD = ("Segoe UI", 10, "bold")
FONT_TITLE = ("Segoe UI", 15, "bold")
FONT_LOGIN_TITLE = ("Segoe UI", 22, "bold")
FONT_LOGIN_LABEL = ("Segoe UI", 12)
FONT_LOGIN_INPUT = ("Segoe UI", 14)
FONT_LOGIN_BUTTON = ("Segoe UI", 12, "bold")
FONT_TOPBAR_BREADCRUMB = ("Segoe UI", 13, "bold")
FONT_TOPBAR_USER = ("Segoe UI", 12)
TOPBAR_HEIGHT = 58
FONT_KPI = ("Segoe UI", 22, "bold")
FONT_LABEL_SMALL = ("Segoe UI", 8)


def apply_theme(root: tk.Misc) -> ttk.Style:
    """Configura ttk.Style con los tokens reales — se llama una vez al
    iniciar la app, antes de construir cualquier vista."""
    style = ttk.Style(root)
    style.theme_use("clam")

    root.configure(bg=BG_DEEP)

    style.configure("App.TFrame", background=BG_DEEP)
    style.configure("Card.TFrame", background=BG_CARD)
    style.configure("Sidebar.TFrame", background=SIDEBAR_BG)
    style.configure("Topbar.TFrame", background=BG_PANEL)

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
        "Kpi.TLabel", background=BG_CARD, foreground=CYAN, font=FONT_KPI
    )
    style.configure(
        "Sidebar.TLabel",
        background=SIDEBAR_BG,
        foreground=TEXT_PRIMARY,
        font=FONT_BODY,
    )
    style.configure(
        "SidebarMuted.TLabel",
        background=SIDEBAR_BG,
        foreground=TEXT_MUTED,
        font=FONT_LABEL_SMALL,
    )

    style.configure(
        "Primary.TButton",
        background=V_OLIVA,
        foreground="#ffffff",
        font=FONT_BODY_BOLD,
        borderwidth=0,
        padding=(14, 10),
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
    style.configure(
        "NavActive.TButton",
        background=V_OLIVA,
        foreground="#ffffff",
        font=FONT_BODY_BOLD,
        borderwidth=0,
        anchor="w",
        padding=(14, 9),
    )

    style.configure("TEntry", fieldbackground="#0f1712", foreground=TEXT_PRIMARY)

    return style
