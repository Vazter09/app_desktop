"""
Detector de ráfagas de pistola / lector 2D (keyboard wedge) — sin Tk.

El lector "teclea" cada byte de la trama. Este detector decide, tecla a
tecla, si la secuencia es una ráfaga de escáner (se consume y se entrega
como texto a parsear) o mecanografía humana (se deja pasar al widget).

Las teclas de una posible ráfaga se retienen hasta saber qué son: si
resultan humanas, se *liberan* (el panel las inserta en el Entry con
foco) en el mismo orden en que se tipearon. Así no se pierde el primer
carácter tecleado a mano ni los tecleados despacio.

Tras procesar una trama, ``iniciar_descarte`` abre una ventana deslizante
que se come la cola del mismo escaneo (PDF417 de cédula: nombres con
relleno de espacios, RH y bloque binario de huella, que el lector
convierte en Tab / espacio / Enter). Cada tecla dentro de la ventana la
extiende, así que la cola se descarta completa sin importar su largo.

Carnet SENA (2026-10-19): su código de barras 1D entrega solo el
documento (8–10 dígitos) y NO manda Enter. Una ráfaga confirmada que
queda quieta ``RESET_MS`` siendo solo dígitos y sin bytes binarios se
entrega como trama (``tomar_trama``) en vez de descartarse. La cédula
nunca cumple esa forma: trae letras, ``@``/Tab o binario.

Sin dependencias de Tk: los tiempos llegan en ms monotónicos.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

from ui.field_validators import DOC_MAX_LEN, DOC_MIN_LEN
from ui.scan_capture import trama_pubdsk_incompleta, trama_pubdsk_lista

# Hueco máximo entre teclas de una ráfaga antes de confirmarla.
INTER_CHAR_MS = 120
# Hueco que da por terminada una ráfaga ya confirmada (PDF417 trae
# huecos por bytes binarios; por eso es mayor que INTER_CHAR_MS).
RESET_MS = 400
# Teclas rápidas consecutivas necesarias para confirmar ráfaga.
MIN_LEN = 4
# Trama larga: se parsea en Enter aunque haya tenido huecos.
CEDULA_MIN_LEN = 25
# Ventana deslizante para descartar la cola de un escaneo ya procesado.
COLA_MS = 400

_TECLAS_ENTER = ("Return", "KP_Enter")
_TECLAS_TAB = ("Tab", "ISO_Left_Tab")
# Carnet SENA: la trama completa es solo el documento.
_RE_CARNET = re.compile(rf"\d{{{DOC_MIN_LEN},{DOC_MAX_LEN}}}")


@dataclass(frozen=True)
class Decision:
    """Resultado de procesar una tecla.

    consumir: True → el evento no llega al widget ("break").
    liberar: texto humano retenido que debe insertarse en el widget
        antes de la tecla actual (puede ser "").
    trama: texto completo de una ráfaga terminada, para parsear
        (None si no hay trama lista).
    """

    consumir: bool
    liberar: str = ""
    trama: str | None = None


class DetectorRafaga:
    def __init__(self) -> None:
        self._buf: list[str] = []
        self._retenido: list[str] = []
        self._ultimo_ms = 0.0
        self._confirmada = False
        self._descartar_hasta_ms = 0.0
        self._hubo_binario = False
        self._trama_carnet: str | None = None

    # ---- API ----------------------------------------------------------

    @property
    def retiene(self) -> bool:
        """True si hay teclas humanas en espera de liberarse."""
        return bool(self._retenido) and not self._confirmada

    @property
    def pendiente(self) -> bool:
        """True si una ráfaga confirmada aún no terminó (carnet sin Enter)."""
        return self._confirmada and bool(self._buf)

    def tomar_trama(self) -> str | None:
        """Trama de carnet cerrada por silencio; None si no hay."""
        trama = self._trama_carnet
        self._trama_carnet = None
        return trama

    def iniciar_descarte(self, ahora_ms: float) -> None:
        """Descarta la cola del escaneo recién procesado (deslizante)."""
        self._reset()
        self._descartar_hasta_ms = ahora_ms + COLA_MS

    def tick(self, ahora_ms: float) -> str:
        """Llamar periódicamente: libera retenido si ya no es ráfaga."""
        if not self._buf:
            return ""
        quieto = ahora_ms - self._ultimo_ms
        if not self._confirmada and quieto > INTER_CHAR_MS:
            return self._soltar_retenido()
        if (
            self._confirmada
            and quieto > RESET_MS
            and not trama_pubdsk_incompleta(self._texto())
        ):
            # Ráfaga sin Enter final: carnet → trama; si no, se descarta
            # (no adivinar).
            self._cerrar_por_silencio()
        return ""

    def tecla(self, keysym: str, char: str, ahora_ms: float) -> Decision:
        if ahora_ms < self._descartar_hasta_ms:
            self._descartar_hasta_ms = ahora_ms + COLA_MS
            return Decision(consumir=True)

        liberar = self._evaluar_hueco(ahora_ms)

        if keysym in _TECLAS_ENTER:
            return self._enter(liberar)

        if keysym in _TECLAS_TAB:
            if self._buf:
                # Separador de campos PDF417 dentro de la ráfaga.
                self._buf.append("@")
                self._ultimo_ms = ahora_ms
                return Decision(consumir=True, liberar=liberar)
            return Decision(consumir=False, liberar=liberar)

        if not char or not char.isprintable():
            if self._buf:
                # Bytes binarios / modificadores: mantener viva la ráfaga.
                self._ultimo_ms = ahora_ms
                if char:
                    # Byte binario (huella de cédula): nunca es carnet.
                    self._hubo_binario = True
                return Decision(consumir=self._confirmada, liberar=liberar)
            return Decision(consumir=False, liberar=liberar)

        self._buf.append(char)
        self._ultimo_ms = ahora_ms
        if not self._confirmada:
            self._retenido.append(char)
            if len(self._buf) >= MIN_LEN:
                self._confirmada = True
                self._retenido = []

        texto = self._texto()
        if trama_pubdsk_lista(texto):
            # Cédula PubDSK_: el NUIP ya está delimitado; no esperar Enter.
            self._reset()
            return Decision(consumir=True, liberar=liberar, trama=texto)
        return Decision(consumir=True, liberar=liberar)

    # ---- Internos -----------------------------------------------------

    def _texto(self) -> str:
        return "".join(self._buf)

    def _reset(self) -> None:
        self._buf = []
        self._retenido = []
        self._ultimo_ms = 0.0
        self._confirmada = False
        self._hubo_binario = False

    def _cerrar_por_silencio(self) -> None:
        """Ráfaga confirmada sin Enter: carnet → trama; resto se descarta."""
        texto = self._texto()
        if not self._hubo_binario and _RE_CARNET.fullmatch(texto):
            self._trama_carnet = texto
        self._reset()

    def _soltar_retenido(self) -> str:
        texto = "".join(self._retenido)
        self._reset()
        return texto

    def _evaluar_hueco(self, ahora_ms: float) -> str:
        """Cierra la secuencia anterior si el hueco indica que terminó."""
        if not self._buf:
            return ""
        hueco = ahora_ms - self._ultimo_ms
        if not self._confirmada and hueco > INTER_CHAR_MS:
            return self._soltar_retenido()
        if (
            self._confirmada
            and hueco > RESET_MS
            and not trama_pubdsk_incompleta(self._texto())
        ):
            self._cerrar_por_silencio()
        return ""

    def _enter(self, liberar: str) -> Decision:
        texto = self._texto()
        if not texto:
            return Decision(consumir=False, liberar=liberar)
        if trama_pubdsk_incompleta(texto):
            # CR dentro del binario antes del NUIP: seguir acumulando.
            return Decision(consumir=True, liberar=liberar)
        if self._confirmada or len(texto) >= CEDULA_MIN_LEN:
            self._reset()
            return Decision(consumir=True, liberar=liberar, trama=texto)
        # Secuencia corta y rápida que no llegó a ráfaga: era humana.
        return Decision(
            consumir=False, liberar=liberar + self._soltar_retenido()
        )
