"""Renderizado nativo de fórmulas LaTeX a PNG usando `matplotlib.mathtext`.

Reemplaza a KaTeX/QtWebEngine: las fórmulas `\\( ... \\)` (inline) y
`\\[ ... \\]` (bloque) se rasterizan con el motor `mathtext` de
matplotlib (backend `Agg`, 100% offline, sin JavaScript ni recursos
remotos) y se guardan como PNG con canal alfa transparente en la caché del
sistema operativo.

Las imágenes se cachean por (LaTeX normalizado, color, tamaño, device pixel
ratio). Si el PNG ya existe, se reutiliza; si falta, se genera solo ese.
"""

from __future__ import annotations

import io
import re
from hashlib import sha256
from pathlib import Path

from src.services.runtime_paths import get_user_cache_dir

# matplotlib se importa de forma perezosa dentro de `_render_png` para no
# penalizar el arranque de la app ni la importación de este módulo.

# `\displaystyle` (y variantes de estilo de tamaño) no están soportadas
# por el parser de mathtext y provocan un ParseFatalException; se
# eliminan antes de rasterizar (no afectan el resultado, solo el tamaño
# tipográfico dentro de tablas).
_UNSUPPORTED_COMMANDS = re.compile(
    r"\\(?:displaystyle|textstyle|scriptstyle|scriptscriptstyle)\s*"
)


def _normalize_latex(latex: str) -> str:
    # Las fórmulas de bloque suelen venir en varias líneas; mathtext no
    # maneja saltos de línea (emite warnings y los dibuja como glifo
    # dummy), así que se colapsa todo el espacio en blanco a espacios.
    collapsed = re.sub(r"\s+", " ", latex)
    return _UNSUPPORTED_COMMANDS.sub("", collapsed).strip()


class FormulaRenderer:
    """Rasteriza fórmulas LaTeX a PNG (mathtext + Agg), con caché en disco."""

    def __init__(self) -> None:
        self._memory_cache: dict[tuple[str, str, int, float], Path] = {}
        self._cache_dir = get_user_cache_dir() / "formulas"
        self._cache_dir.mkdir(parents=True, exist_ok=True)

    def render(
        self,
        latex: str,
        *,
        color: str = "#e8e8e8",
        size_px: int = 15,
        device_pixel_ratio: float = 1.0,
    ) -> Path:
        """Devuelve la ruta PNG cacheada de la fórmula renderizada.

        - `color`: color del texto de la fórmula (hex).
        - `size_px`: alto tipográfico objetivo en píxeles lógicos.
        - `device_pixel_ratio`: factor HiDPI; la imagen se rasteriza a
          mayor resolución para conservar nitidez.
        """
        dpr = round(device_pixel_ratio if device_pixel_ratio > 0 else 1.0, 2)
        normalized = _normalize_latex(latex)
        key = (normalized, color, size_px, dpr)
        cached = self._memory_cache.get(key)
        if cached is not None:
            return cached

        path = self._cache_dir / f"{_cache_key(normalized, color, size_px, dpr)}.png"
        if not path.exists():
            png = _render_png(normalized, color=color, size_px=size_px, dpr=dpr)
            path.write_bytes(png)

        self._memory_cache[key] = path
        return path


def _cache_key(latex: str, color: str, size_px: int, dpr: float) -> str:
    payload = f"v1\0{latex}\0{color}\0{size_px}\0{dpr}".encode("utf-8")
    return sha256(payload).hexdigest()


def _render_png(latex: str, *, color: str, size_px: int, dpr: float) -> bytes:
    import matplotlib

    matplotlib.use("Agg")
    from matplotlib import mathtext
    from matplotlib.font_manager import FontProperties

    # dpi = 72 * dpr  =>  pixeles = size_px(pt) * dpi / 72 = size_px * dpr,
    # que al marcar devicePixelRatio=dpr da el tamaño lógico deseado.
    dpi = 72.0 * dpr
    prop = FontProperties(size=size_px)
    buf = io.BytesIO()
    try:
        with matplotlib.rc_context({"savefig.transparent": True}):
            mathtext.math_to_image(
                f"${latex}$", buf, prop=prop, dpi=dpi, format="png", color=color
            )
    except Exception:
        # Fórmula no soportada por mathtext: se muestra el LaTeX crudo
        # como texto plano (escapado para que mathtext no lo interprete),
        # así la app nunca falla y sigue siendo 100% offline.
        buf = io.BytesIO()
        safe = _escape_as_text(latex)
        try:
            with matplotlib.rc_context({"savefig.transparent": True}):
                mathtext.math_to_image(
                    safe, buf, prop=prop, dpi=dpi, format="png", color=color
                )
        except Exception:
            return b""
    return buf.getvalue()


_MATHTEXT_SPECIALS = re.compile(r"([\\${}^_#&~%])")


def _escape_as_text(text: str) -> str:
    """Escapa caracteres especiales de mathtext para renderizar `text`
    como texto plano (fallback cuando la fórmula no parsea)."""
    return _MATHTEXT_SPECIALS.sub(r"\\\1", text)
