"""
Sistema de Reconocimiento Biométrico Multimodal
Aplicación Desktop - Python + OpenCV (cámara directa, sin diálogos)
"""

import os
import sys
import base64
import threading
import cv2
import numpy as np
from pathlib import Path
from datetime import datetime

try:
    import tkinter as tk
    from tkinter import ttk, messagebox, simpledialog, font as tkfont
    from PIL import Image, ImageTk
    HAS_TK = True
except ImportError:
    HAS_TK = False

from smartcset_client import SmartcsetClient, SmartcsetApiError, extraer_vector_local
import config_desktop

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

class Config:
    APP_NAME = "Sistema de Reconocimiento Biométrico Multimodal"
    APP_VERSION = "3.0.0-desktop"
    MOTOR_URL = os.getenv("BIOMETRIA_MOTOR_URL", "http://127.0.0.1:5000")
    MOTOR_API_KEY = os.getenv("BIOMETRIA_API_KEY", "cambiar-api-key-segura")
    BASE_DIR = Path(__file__).parent

# =============================================================================
# COLORES (mismos que el CSS original)
# =============================================================================

class Colors:
    BG_DARK = "#0f1117"
    BG_CARD = "#1a1d27"
    BG_CARD_ALT = "#1e2230"
    ACCENT = "#2d6a4f"
    ACCENT_LIGHT = "#409f6e"
    SCAN_GREEN = "#00ff88"
    TEXT_PRIMARY = "#e2e8f0"
    TEXT_SECONDARY = "#a0aec0"
    TEXT_MUTED = "#718096"
    SUCCESS = "#48bb78"
    DANGER = "#fc8181"
    WARNING = "#ecc94b"
    BORDER = "#2d3748"
    HERO_START = "#06120c"
    HERO_MID = "#0d2b1d"
    HERO_END = "#1a3b2a"

# =============================================================================
# APLICACIÓN PRINCIPAL CON Tkinter
# =============================================================================

class BiometricDesktopApp:
    def __init__(self, smartcset_client, nom_dispositivo=""):
        if not HAS_TK:
            print("[ERROR] tkinter o Pillow no disponibles.")
            print("Instale: pip install pillow")
            sys.exit(1)

        self.smartcset_client = smartcset_client

        self.root = tk.Tk()
        self.root.title(f"{Config.APP_NAME} — {nom_dispositivo}" if nom_dispositivo else Config.APP_NAME)
        self.root.geometry("1200x800")
        self.root.minsize(900, 600)
        self.root.configure(bg=Colors.BG_DARK)

        self.camera = None
        self.camera_running = False
        self.photo_image = None
        self.last_frame = None
        self.cedula_var = tk.StringVar()
        self.face_captured = False
        self.face_data = None
        self.face_data_hd = None
        self.finger_data = None
        self.log_lines = []

        self._setup_ui()
        self._start_camera()

    def _setup_ui(self):
        style = ttk.Style()
        style.theme_use('clam')

        main_frame = tk.Frame(self.root, bg=Colors.BG_DARK)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)

        hero = tk.Frame(main_frame, bg="#0d2b1d", height=55)
        hero.pack(fill=tk.X, pady=(0, 10))
        hero.pack_propagate(False)

        tk.Label(
            hero, text="Estación de Captura Biométrica Multimodal",
            bg="#0d2b1d", fg=Colors.TEXT_PRIMARY,
            font=("Segoe UI", 16, "bold")
        ).pack(expand=True)

        content = tk.Frame(main_frame, bg=Colors.BG_DARK)
        content.pack(fill=tk.BOTH, expand=True)

        left_panel = tk.Frame(content, bg=Colors.BG_DARK)
        left_panel.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 10))

        right_panel = tk.Frame(content, bg=Colors.BG_DARK)
        right_panel.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True, padx=(10, 0))

        self._build_camera_card(left_panel)
        self._build_fingerprint_card(right_panel)
        self._build_controls(main_frame)
        self._build_log(main_frame)

    def _build_camera_card(self, parent):
        card = tk.Frame(parent, bg=Colors.BG_CARD, bd=0, highlightthickness=1,
                        highlightbackground=Colors.BORDER)
        card.pack(fill=tk.BOTH, expand=True)

        tk.Label(card, text="\U0001f4f7 Reconocimiento Facial",
                 bg=Colors.BG_CARD, fg=Colors.ACCENT,
                 font=("Segoe UI", 12, "bold"), anchor="w").pack(fill=tk.X, padx=15, pady=(15, 10))

        self.video_frame = tk.Frame(card, bg="#000000", height=300)
        self.video_frame.pack(fill=tk.X, padx=15, pady=(0, 10))
        self.video_frame.pack_propagate(False)

        self.video_label = tk.Label(self.video_frame, bg="#000000", text="Iniciando cámara...",
                                     fg=Colors.TEXT_MUTED, font=("Segoe UI", 11))
        self.video_label.pack(expand=True)

        self.btn_capture = tk.Button(
            card,             text="Captura Facial",
            bg=Colors.ACCENT, fg="white", activebackground=Colors.ACCENT_LIGHT,
            activeforeground="white", font=("Segoe UI", 10, "bold"),
            bd=0, padx=20, pady=10, cursor="hand2",
            command=self._capture_face
        )
        self.btn_capture.pack(fill=tk.X, padx=15, pady=(0, 5))

        self.face_status = tk.Label(
            card, text="Canal de video inactivo",
            bg=Colors.BG_CARD, fg=Colors.TEXT_MUTED,
            font=("Segoe UI", 9)
        )
        self.face_status.pack(padx=15, pady=(0, 15))

    def _build_fingerprint_card(self, parent):
        card = tk.Frame(parent, bg=Colors.BG_CARD, bd=0, highlightthickness=1,
                        highlightbackground=Colors.BORDER)
        card.pack(fill=tk.BOTH, expand=True)

        tk.Label(card, text="\u261e Reconocimiento Dactilar",
                 bg=Colors.BG_CARD, fg=Colors.ACCENT,
                 font=("Segoe UI", 12, "bold"), anchor="w").pack(fill=tk.X, padx=15, pady=(15, 10))

        self.finger_frame = tk.Frame(card, bg=Colors.BG_CARD_ALT, height=300)
        self.finger_frame.pack(fill=tk.X, padx=15, pady=(0, 10))
        self.finger_frame.pack_propagate(False)

        self.finger_canvas = tk.Canvas(
            self.finger_frame, bg=Colors.BG_CARD_ALT,
            highlightthickness=0
        )
        self.finger_canvas.pack(fill=tk.BOTH, expand=True)

        self.scan_animation_id = None
        self.is_scanning = False
        self.finger_canvas.bind("<Configure>", self._on_canvas_resize)

        self.finger_status = tk.Label(
            self.finger_frame, text="Esperando huella...",
            bg=Colors.BG_CARD_ALT, fg=Colors.WARNING,
            font=("Segoe UI", 10, "bold")
        )
        self.finger_status.pack(side=tk.BOTTOM, pady=(0, 5))

        self.btn_finger = tk.Button(
            card,             text="Captura Dactilar",
            bg=Colors.ACCENT, fg="white", activebackground=Colors.ACCENT_LIGHT,
            activeforeground="white", font=("Segoe UI", 10, "bold"),
            bd=0, padx=20, pady=10, cursor="hand2",
            command=self._simulate_finger
        )
        self.btn_finger.pack(fill=tk.X, padx=15, pady=(0, 15))

    def _on_canvas_resize(self, event):
        self._draw_fingerprint_idle()

    def _draw_fingerprint_idle(self):
        self.finger_canvas.delete("all")
        w = self.finger_canvas.winfo_width()
        h = self.finger_canvas.winfo_height()
        if w < 10 or h < 10:
            return

        cx = w // 2
        cy = h // 2 - 5
        base_r = min(w, h) * 0.35
        color = Colors.TEXT_MUTED
        self._draw_spiral_fingerprint(cx, cy, base_r, color, 3)

        self.scan_line_id = self.finger_canvas.create_line(
            0, 0, 0, 0, fill=Colors.SCAN_GREEN, width=2, state="hidden"
        )

    def _draw_spiral_fingerprint(self, cx, cy, max_r, color, width):
        import math
        points = []
        total_angle = 720
        steps = 200
        min_r = max_r * 0.1

        for i in range(steps + 1):
            angle = math.radians(i * total_angle / steps)
            t = i / steps
            r = min_r + (max_r - min_r) * t
            x = cx + r * math.cos(angle)
            y = cy + r * math.sin(angle) * 0.85
            points.append((x, y))

        for i in range(len(points) - 1):
            x1, y1 = points[i]
            x2, y2 = points[i + 1]
            seg_t = i / len(points)
            alpha = 0.4 + 0.6 * seg_t
            self.finger_canvas.create_line(
                x1, y1, x2, y2,
                fill=color, width=width, smooth=True
            )

        for i in range(0, len(points) - 1, 8):
            x, y = points[i]
            self.finger_canvas.create_oval(
                x - 1, y - 1, x + 1, y + 1,
                fill=color, outline=""
            )

        self.finger_canvas.create_oval(
            cx - max_r - 10, cy - max_r - 10,
            cx + max_r + 10, cy + max_r + 10,
            outline=Colors.BORDER, width=2, dash=(4, 4)
        )

    def _start_scan_animation(self):
        if self.is_scanning:
            return
        self.is_scanning = True
        self.finger_canvas.delete("all")
        w = self.finger_canvas.winfo_width()
        h = self.finger_canvas.winfo_height()
        if w < 10 or h < 10:
            return

        cx = w // 2
        cy = h // 2 - 5
        base_r = min(w, h) * 0.35
        self._draw_spiral_fingerprint(cx, cy, base_r, Colors.TEXT_MUTED, 3)

        self.scan_line_id = self.finger_canvas.create_line(
            10, 10, w - 10, 10,
            fill=Colors.SCAN_GREEN, width=2
        )
        self._animate_scan(10)

    def _animate_scan(self, y):
        if not self.is_scanning:
            return
        w = self.finger_canvas.winfo_width()
        h = self.finger_canvas.winfo_height()
        if y > h - 10:
            self.finger_canvas.delete("scan_glow")
            self._animate_scan(10)
            return

        self.finger_canvas.coords(self.scan_line_id, 10, y, w - 10, y)
        self.finger_canvas.delete("scan_glow")
        self.finger_canvas.create_rectangle(
            10, y - 12, w - 10, y + 12,
            fill=Colors.SCAN_GREEN, outline="", stipple="gray25",
            tags="scan_glow"
        )
        self.finger_canvas.tag_raise(self.scan_line_id)

        cx = w // 2
        cy = h // 2 - 5
        base_r = min(w, h) * 0.35
        self.finger_canvas.delete("fp_green")
        import math
        for i in range(0, 200, 4):
            t = i / 200
            r = base_r * 0.1 + (base_r * 0.9) * t
            pt_y = cy + r * math.sin(math.radians(t * 720)) * 0.85
            if abs(pt_y - y) < 15:
                angle = math.radians(t * 720)
                px = cx + r * math.cos(angle)
                py = cy + r * math.sin(angle) * 0.85
                self.finger_canvas.create_oval(
                    px - 3, py - 3, px + 3, py + 3,
                    fill=Colors.SCAN_GREEN, outline="", tags="fp_green"
                )

        self.scan_animation_id = self.root.after(20, lambda: self._animate_scan(y + 4))

    def _stop_scan_animation(self):
        self.is_scanning = False
        if self.scan_animation_id:
            self.root.after_cancel(self.scan_animation_id)
            self.scan_animation_id = None
        self.finger_canvas.delete("scan_glow")
        self.finger_canvas.delete("fp_green")

    def _draw_fingerprint_success(self):
        self.finger_canvas.delete("all")
        w = self.finger_canvas.winfo_width()
        h = self.finger_canvas.winfo_height()
        if w < 10 or h < 10:
            return

        cx = w // 2
        cy = h // 2 - 5
        base_r = min(w, h) * 0.35
        self._draw_spiral_fingerprint(cx, cy, base_r, Colors.SUCCESS, 4)

    def _build_controls(self, parent):
        ctrl = tk.Frame(parent, bg=Colors.BG_DARK)
        ctrl.pack(fill=tk.X, pady=(8, 3))

        id_frame = tk.Frame(ctrl, bg=Colors.BG_CARD, bd=0, highlightthickness=1,
                            highlightbackground=Colors.BORDER)
        id_frame.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 10))

        tk.Label(id_frame, text="Cédula de Identidad",
                 bg=Colors.BG_CARD, fg=Colors.ACCENT,
                 font=("Segoe UI", 9, "bold"), anchor="w").pack(fill=tk.X, padx=15, pady=(6, 2))

        cedula_entry = tk.Entry(
            id_frame, textvariable=self.cedula_var,
            bg=Colors.BG_CARD_ALT, fg=Colors.TEXT_PRIMARY,
            insertbackground=Colors.TEXT_PRIMARY,
            font=("Segoe UI", 13), bd=0,
            highlightthickness=1, highlightbackground=Colors.BORDER,
            highlightcolor=Colors.ACCENT_LIGHT
        )
        cedula_entry.pack(fill=tk.X, padx=15, pady=(0, 6), ipady=3)

        self.btn_enroll = tk.Button(
            ctrl, text="\u2705  Enrolar en el Sistema",
            bg=Colors.ACCENT, fg="white", activebackground=Colors.ACCENT_LIGHT,
            activeforeground="white", font=("Segoe UI", 12, "bold"),
            bd=0, padx=30, pady=15, cursor="hand2",
            state=tk.DISABLED,
            command=self._enroll
        )
        self.btn_enroll.pack(side=tk.RIGHT)

        self.btn_identify = tk.Button(
            ctrl, text="Identificar (ingreso/salida)",
            bg=Colors.ACCENT_LIGHT, fg="white", activebackground=Colors.ACCENT,
            activeforeground="white", font=("Segoe UI", 12, "bold"),
            bd=0, padx=30, pady=15, cursor="hand2",
            state=tk.DISABLED,
            command=self._identify
        )
        self.btn_identify.pack(side=tk.RIGHT, padx=(0, 10))

    def _build_log(self, parent):
        log_frame = tk.Frame(parent, bg=Colors.BG_DARK)
        log_frame.pack(fill=tk.X, pady=(10, 0))

        self.log_text = tk.Text(
            log_frame, bg="#1a202c", fg=Colors.SUCCESS,
            font=("Consolas", 10), bd=0, height=10,
            highlightthickness=1, highlightbackground=Colors.BORDER,
            insertbackground=Colors.SUCCESS, state=tk.DISABLED
        )
        self.log_text.pack(fill=tk.X)

        self._log("Sistema inicializado. Cámara activándose...")

    def _log(self, msg, level="INFO"):
        t = datetime.now().strftime("%H:%M:%S")
        colors = {"INFO": Colors.SUCCESS, "OK": Colors.SUCCESS, "ERROR": Colors.DANGER}
        color = colors.get(level, Colors.TEXT_SECONDARY)
        self.log_text.configure(state=tk.NORMAL)
        self.log_text.insert(tk.END, f"[{t}] {msg}\n")
        self.log_text.see(tk.END)
        self.log_text.configure(state=tk.DISABLED)

    # =========================================================================
    # CÁMARA - OpenCV directo (sin navegador, sin diálogos)
    # =========================================================================

    def _start_camera(self):
        def _init():
            try:
                if sys.platform == "win32":
                    self.camera = cv2.VideoCapture(0, cv2.CAP_DSHOW)
                elif sys.platform == "linux":
                    self.camera = cv2.VideoCapture(0, cv2.CAP_V4L2)
                else:
                    self.camera = cv2.VideoCapture(0)

                if not self.camera.isOpened():
                    self.camera = cv2.VideoCapture(0)
                    if not self.camera.isOpened():
                        self._log("Cámara no disponible.", "ERROR")
                        return

                self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
                self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
                self.camera.set(cv2.CAP_PROP_BUFFERSIZE, 1)

                ret, test = self.camera.read()
                if not ret:
                    self._log("Cámara detectada pero no responde.", "ERROR")
                    self.camera.release()
                    self.camera = None
                    return

                self.camera_running = True
                self._log("Cámara iniciada (1280x720).")
                self.root.after(0, self._update_frame)
            except Exception as e:
                self._log(f"Error cámara: {e}", "ERROR")

        threading.Thread(target=_init, daemon=True).start()

    def _update_frame(self):
        if not self.camera_running or not self.camera:
            return

        ret, frame = self.camera.read()
        if ret:
            frame = cv2.flip(frame, 1)
            self.last_frame = frame.copy()
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            w = self.video_frame.winfo_width()
            h = self.video_frame.winfo_height()
            if w > 1 and h > 1:
                frame_resized = cv2.resize(frame_rgb, (w, h))
                img = Image.fromarray(frame_resized)
                self.photo_image = ImageTk.PhotoImage(img)
                self.video_label.configure(image=self.photo_image, text="")

        self.root.after(33, self._update_frame)

    def _capture_face(self):
        if self.last_frame is None:
            self._log("Cámara no activa.", "ERROR")
            return

        frame = self.last_frame.copy()
        frame = cv2.flip(frame, 1)

        h, w = frame.shape[:2]
        max_side = 480
        scale = min(max_side / w, max_side / h)
        new_w, new_h = int(w * scale), int(h * scale)
        resized = cv2.resize(frame, (new_w, new_h))

        _, buffer_compressed = cv2.imencode('.jpg', resized, [cv2.IMWRITE_JPEG_QUALITY, 78])
        self.face_data = base64.b64encode(buffer_compressed).decode('utf-8')

        _, buffer_hd = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 92])
        self.face_data_hd = base64.b64encode(buffer_hd).decode('utf-8')

        self.face_captured = True
        self.face_status.configure(text="✓ Rostro capturado", fg=Colors.SUCCESS)

        kb_compressed = len(self.face_data) * 3 / 4 / 1024
        kb_hd = len(self.face_data_hd) * 3 / 4 / 1024
        self._log(f"Rostro capturado. HD: {kb_hd:.1f} KB | Envío: {kb_compressed:.1f} KB")

        self._update_enroll_button()

    def _simulate_finger(self):
        self._log("Simulando huella...")
        self._start_scan_animation()
        self.finger_status.configure(text="Escaneando...", fg=Colors.SCAN_GREEN)
        self.root.after(1800, lambda: self._process_fingerprint(
            "4650540002000000320100002e0000000102030405060708090a0b0c0d0e0f22334455"
        ))

    def _process_fingerprint(self, hex_data):
        self.finger_data = hex_data
        self._stop_scan_animation()
        self._draw_fingerprint_success()
        self.finger_status.configure(text="✓ Huella capturada", fg=Colors.SUCCESS)
        self._log("Template de huella recibido.")
        self._update_enroll_button()

    def _update_enroll_button(self):
        # La huella sigue siendo simulada (sin lector real) y no se envía al
        # servidor: la biometría real hoy es solo facial. Se deja el widget de
        # huella como está (decorativo) pero no bloquea el enrolamiento.
        state = tk.NORMAL if self.face_captured else tk.DISABLED
        self.btn_enroll.configure(state=state)
        if hasattr(self, "btn_identify"):
            self.btn_identify.configure(state=state)

    # =========================================================================
    # ENROLAMIENTO
    # =========================================================================

    def _enroll(self):
        cedula = self.cedula_var.get().strip()
        if not cedula.isdigit() or not (6 <= len(cedula) <= 10):
            messagebox.showerror("Error", "Documento inválido: debe tener entre 6 y 10 dígitos.")
            return
        if not self.face_data:
            messagebox.showerror("Error", "Capture el rostro primero.")
            return

        self.btn_enroll.configure(state=tk.DISABLED, text="⏳ Procesando...")
        self._log("Extrayendo vector facial (motor local)...")

        def _send():
            try:
                vector_data = extraer_vector_local(
                    self.face_data, Config.MOTOR_URL, Config.MOTOR_API_KEY
                )
                calidad = vector_data.get("calidad_facial", 0.0)
                self._log(f"Vector extraído. Calidad: {calidad}%")

                foto_dataurl = f"data:image/jpeg;base64,{self.face_data_hd}"
                client = self.smartcset_client
                client.enrolar(
                    documento=cedula,
                    vector_facial=vector_data["vector_facial"],
                    foto_base64=foto_dataurl,
                    calidad_facial=calidad,
                )

                self._log("OK: enrolamiento exitoso.", "OK")
                self.root.after(0, lambda: messagebox.showinfo("Éxito", "Enrolamiento exitoso."))
                self.root.after(0, self._reset)
            except SmartcsetApiError as e:
                msg = e.mensaje
                self._log(f"ERROR: {msg}", "ERROR")
                self.root.after(0, lambda: messagebox.showerror("Error", msg))
            except Exception as e:
                msg = str(e)
                self._log(f"Error: {msg}", "ERROR")
                self.root.after(0, lambda: messagebox.showerror("Error", msg))
            finally:
                self.root.after(0, self._update_enroll_button)

        threading.Thread(target=_send, daemon=True).start()

    # =========================================================================
    # IDENTIFICACIÓN (ingreso/salida real vía backend SmartCSET)
    # =========================================================================

    def _identify(self):
        if not self.face_data:
            messagebox.showerror("Error", "Capture el rostro primero.")
            return

        self.btn_identify.configure(state=tk.DISABLED, text="⏳ Identificando...")
        self._log("Extrayendo vector facial (motor local)...")

        def _send():
            try:
                vector_data = extraer_vector_local(
                    self.face_data, Config.MOTOR_URL, Config.MOTOR_API_KEY
                )
                client = self.smartcset_client
                match = client.identificar(vector_data["vector_facial"])

                id_persona = match.get("id_persona")
                if id_persona is None:
                    self._log("Rostro no identificado.", "ERROR")
                    self.root.after(0, lambda: messagebox.showwarning(
                        "No identificado", "No se encontró una persona enrolada con ese rostro."
                    ))
                    return

                self._log(f"Identificado: documento {id_persona} (distancia {match.get('distancia'):.4f})", "OK")

                acceso = client.consultar_acceso(str(id_persona))
                persona = acceso.get("persona")
                if persona is None:
                    self._log("La persona identificada no existe en tab_personas.", "ERROR")
                    return

                foto_dataurl = f"data:image/jpeg;base64,{self.face_data_hd}"

                if acceso.get("puede_ingresar"):
                    resultado = client.registrar_ingreso(
                        documento=id_persona,
                        tipo_doc=persona.get("tipo_doc", "CC"),
                        tipo_persona=persona.get("tipo_persona", 1),
                        nombres=persona.get("nombres", ""),
                        apellidos=persona.get("apellidos", ""),
                        foto_base64=foto_dataurl,
                    )
                    self._log(f"OK: ingreso #{resultado.get('id_ingreso')} registrado.", "OK")
                    mensaje = f"Ingreso registrado.\n{persona.get('nombres', '')} {persona.get('apellidos', '')}"
                else:
                    resultado = client.registrar_salida(
                        documento=id_persona,
                        tipo_doc=persona.get("tipo_doc", "CC"),
                        foto_base64=foto_dataurl,
                    )
                    self._log(f"OK: salida registrada (ingreso #{resultado.get('id_ingreso')}).", "OK")
                    mensaje = f"Salida registrada.\n{persona.get('nombres', '')} {persona.get('apellidos', '')}"

                self.root.after(0, lambda: messagebox.showinfo("Éxito", mensaje))
                self.root.after(0, self._reset)
            except SmartcsetApiError as e:
                msg = e.mensaje
                self._log(f"ERROR: {msg}", "ERROR")
                self.root.after(0, lambda: messagebox.showerror("Error", msg))
            except Exception as e:
                msg = str(e)
                self._log(f"Error: {msg}", "ERROR")
                self.root.after(0, lambda: messagebox.showerror("Error", msg))
            finally:
                self.root.after(0, self._update_enroll_button)
                self.root.after(0, lambda: self.btn_identify.configure(text="Identificar (ingreso/salida)"))

        threading.Thread(target=_send, daemon=True).start()

    def _reset(self):
        self.face_captured = False
        self.face_data = None
        self.face_data_hd = None
        self.finger_data = None
        self.cedula_var.set("")
        self.face_status.configure(text="Canal de video activo", fg=Colors.TEXT_MUTED)
        self._stop_scan_animation()
        self._draw_fingerprint_idle()
        self.finger_status.configure(text="Esperando huella...", fg=Colors.WARNING)
        self.btn_enroll.configure(state=tk.DISABLED)
        self._log("Formulario reiniciado.")

    def run(self):
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)
        self.root.mainloop()

    def _on_close(self):
        self.camera_running = False
        if self.camera:
            self.camera.release()
        self.root.destroy()

# =============================================================================
# LOGIN (validación de dispositivo contra el backend real de SmartCSET)
# =============================================================================

def _pedir_credenciales_dispositivo(root):
    """Diálogo simple: URL del servidor + token de 6 caracteres (generado con
    scripts/tools/generate_device_token.php). No hay usuario/clave: la
    identidad del PC de portería es el token, igual que la app móvil."""
    base_url = simpledialog.askstring(
        "SmartCSET — Configuración",
        "URL del servidor SmartCSET\n(ej: https://10.5.213.111/smartcset)",
        parent=root,
    )
    if not base_url:
        return None
    token = simpledialog.askstring(
        "SmartCSET — Configuración",
        "Token de dispositivo (6 caracteres)",
        parent=root,
    )
    if not token:
        return None
    return base_url.strip(), token.strip()


def _login_dispositivo():
    """Valida (o pide) el token de dispositivo contra /device/validate.php.
    Devuelve (SmartcsetClient, nom_dispositivo) o None si el operador cancela."""
    root_login = tk.Tk()
    root_login.withdraw()

    cfg = config_desktop.cargar_config()
    while True:
        if cfg is None:
            creds = _pedir_credenciales_dispositivo(root_login)
            if creds is None:
                root_login.destroy()
                return None
            base_url, token = creds
        else:
            base_url, token = cfg["base_url"], cfg["device_token"]

        client = SmartcsetClient(base_url, token)
        try:
            device = client.validar_dispositivo()
        except SmartcsetApiError as e:
            messagebox.showerror("No se pudo validar el dispositivo", e.mensaje, parent=root_login)
            cfg = None  # forzar reingreso de credenciales
            continue

        nom_dispositivo = device.get("nom_dispositivo", "")
        config_desktop.guardar_config(base_url, token, nom_dispositivo)
        root_login.destroy()
        return client, nom_dispositivo


if __name__ == "__main__":
    print("=" * 60)
    print(f" {Config.APP_NAME}")
    print(f" Versión {Config.APP_VERSION}")
    print("=" * 60)

    login = _login_dispositivo()
    if login is None:
        print("[INFO] Login cancelado. Cerrando.")
        sys.exit(0)

    smartcset_client, nom_dispositivo = login
    print(f"[OK] Dispositivo validado: {nom_dispositivo}")

    app = BiometricDesktopApp(smartcset_client, nom_dispositivo)
    app.run()

    print("[INFO] Aplicación cerrada.")
