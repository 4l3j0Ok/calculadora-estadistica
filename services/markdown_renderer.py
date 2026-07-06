"""Renderizado nativo de Markdown para toda la aplicación.

Único punto de conversión Markdown -> contenido para un
`QTextDocument` de Qt (sin QtWebEngine, sin Chromium, sin JavaScript ni
recursos remotos):

- El Markdown se parsea con `markdown-it-py` (preset `commonmark` +
  tablas + task lists vía `mdit-py-plugins`) para generar HTML del
  subconjunto de rich text que entiende `QTextDocument`.
- Las fórmulas LaTeX `\\( ... \\)` (inline) y `\\[ ... \\]` (bloque) se
  rasterizan con `matplotlib.mathtext` (ver `services.formula_renderer`)
  y se insertan como `<img>` que apuntan a PNG cacheados en el directorio
  de caché del sistema operativo.

No se implementa ningún parsing de Markdown "a mano" (regex, splits,
reemplazos manuales de encabezados/tablas/negritas/listas): todo el
Markdown se delega a `markdown-it-py`.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

from markdown_it import MarkdownIt
from mdit_py_plugins.anchors import anchors_plugin
from mdit_py_plugins.tasklists import tasklists_plugin
from PySide6.QtCore import QUrl
from PySide6.QtGui import QTextDocument

from services.formula_renderer import FormulaRenderer
from services.template_loader import load_resource_text

# Placeholders únicos (alfanuméricos, sin sintaxis Markdown) usados para
# proteger las fórmulas LaTeX del procesamiento de markdown-it, y
# restaurarlas luego de convertir a HTML. No se usan bytes NUL: los
# parsers CommonMark (incluido markdown-it-py) los reemplazan por
# U+FFFD según el spec, lo que rompería el placeholder.
_MATH_BLOCK_PLACEHOLDER = "MATHBLOCKPLACEHOLDERxz{idx}zx"
_MATH_INLINE_PLACEHOLDER = "MATHINLINEPLACEHOLDERxz{idx}zx"

# \[ ... \] (bloque) y \( ... \) (inline); también admite $$...$$ y
# $...$ evitando falsos positivos con importes monetarios (un "$"
# suelto o seguido/precedido de dígitos sin cierre correspondiente no
# se toca).
_BLOCK_MATH_RE = re.compile(r"\\\[(.+?)\\\]|\${2}(.+?)\${2}", re.DOTALL)
_INLINE_MATH_RE = re.compile(r"\\\((.+?)\\\)|(?<!\$)\$(?!\s)([^$\n]+?)(?<!\s)\$(?!\$)")

# Tamaños tipográficos (px lógicos) de las fórmulas rasterizadas.
_INLINE_MATH_SIZE_PX = 15
_BLOCK_MATH_SIZE_PX = 17

# Paletas de color por tema (usadas tanto para el color del texto de las
# fórmulas como para la hoja de estilos del documento).
_THEMES = {
    "dark": {
        "fg": "#e8e8e8",
        "muted": "#a0a0a0",
        "border": "#3a3a3a",
        "code_bg": "#2a2a2a",
        "link": "#6cb6ff",
    },
    "light": {
        "fg": "#1e1e1e",
        "muted": "#555555",
        "border": "#d0d0d0",
        "code_bg": "#f2f2f2",
        "link": "#0b57d0",
    },
}


@dataclass
class RenderedMarkdown:
    """Resultado del renderizado listo para volcar en un `QTextDocument`."""

    html: str
    stylesheet: str
    resources: dict[str, str] = field(default_factory=dict)
    anchors: dict[str, str] = field(default_factory=dict)


def _normalize_theme(theme: str) -> str:
    return theme if theme in ("dark", "light") else "dark"


def _normalize_color(color: str) -> str:
    """Convierte colores de QML a un formato aceptado por matplotlib.

    `color.toString()` en QML puede devolver `#AARRGGBB`; matplotlib
    interpreta colores hex como `#RRGGBB` o `#RRGGBBAA`. Para fórmulas
    usamos solo RGB y descartamos alfa.
    """
    if re.fullmatch(r"#[0-9A-Fa-f]{8}", color):
        return f"#{color[3:]}"
    if re.fullmatch(r"#[0-9A-Fa-f]{6}", color):
        return color
    return ""


def _extract_math(text: str) -> tuple[str, list[str], list[str]]:
    """Reemplaza las fórmulas LaTeX por placeholders y las devuelve
    aparte, para que markdown-it no las interprete como Markdown."""
    block_formulas: list[str] = []
    inline_formulas: list[str] = []

    def _block_sub(match: re.Match) -> str:
        formula = match.group(1) if match.group(1) is not None else match.group(2)
        block_formulas.append(formula.strip())
        return _MATH_BLOCK_PLACEHOLDER.format(idx=len(block_formulas) - 1)

    text = _BLOCK_MATH_RE.sub(_block_sub, text)

    def _inline_sub(match: re.Match) -> str:
        formula = match.group(1) if match.group(1) is not None else match.group(2)
        inline_formulas.append(formula.strip())
        return _MATH_INLINE_PLACEHOLDER.format(idx=len(inline_formulas) - 1)

    text = _INLINE_MATH_RE.sub(_inline_sub, text)

    return text, block_formulas, inline_formulas


def _build_markdown_it() -> MarkdownIt:
    md = MarkdownIt(
        "commonmark",
        {
            "html": False,  # no se acepta HTML arbitrario embebido en el Markdown
            "linkify": True,
            "typographer": True,
        },
    )
    md.enable(["table"])
    md.use(anchors_plugin, min_level=1, max_level=6)
    md.use(tasklists_plugin)
    return md


_HEADING_RE = re.compile(
    r'<h[1-6]\s+id="([^"]+)">(.*?)</h[1-6]>', re.IGNORECASE | re.DOTALL
)
_TAG_RE = re.compile(r"<[^>]+>")


def _extract_heading_anchors(html: str) -> dict[str, str]:
    anchors: dict[str, str] = {}
    for match in _HEADING_RE.finditer(html):
        anchor = match.group(1)
        title = _TAG_RE.sub("", match.group(2)).strip()
        if title:
            anchors[anchor] = title
    return anchors


def _decorate_tables(html: str) -> str:
    """Agrega atributos de borde a las tablas para que se vean con
    líneas en el subconjunto de HTML de `QTextDocument` (que no aplica
    `border-collapse` desde CSS)."""
    return html.replace(
        "<table>", '<table border="1" cellspacing="0" cellpadding="4" width="100%">'
    )


def _stylesheet(theme: str) -> str:
    palette = _THEMES[_normalize_theme(theme)]
    return (
        f"a {{ color: {palette['link']}; }}"
        f"code, pre {{ background-color: {palette['code_bg']}; "
        f"font-family: 'CaskaydiaCove NFM','Cascadia Code',monospace; }}"
        f"th, td {{ padding: 4px 8px; }}"
        f"th {{ background-color: {palette['code_bg']}; }}"
        f"blockquote {{ color: {palette['muted']}; }}"
    )


class MarkdownRenderer:
    """Servicio reutilizable para convertir Markdown (con fórmulas LaTeX)
    a contenido nativo de `QTextDocument`: HTML del subconjunto de rich
    text de Qt, fórmulas como PNG cacheados, y una hoja de estilos por tema."""

    def __init__(self) -> None:
        self._md = _build_markdown_it()
        self._formulas = FormulaRenderer()

    # ── API pública ──────────────────────────────────────────────────

    def render(
        self,
        markdown_text: str,
        theme: str = "dark",
        device_pixel_ratio: float = 1.0,
        text_color: str = "",
    ) -> RenderedMarkdown:
        """Convierte un string Markdown a un `RenderedMarkdown`."""
        theme = _normalize_theme(theme)
        protected_text, block_formulas, inline_formulas = _extract_math(markdown_text)
        body_html = self._md.render(protected_text)
        anchors = _extract_heading_anchors(body_html)
        body_html, resources = self._replace_math_with_images(
            body_html, block_formulas, inline_formulas, theme, device_pixel_ratio, text_color
        )
        body_html = _decorate_tables(body_html)
        return RenderedMarkdown(
            html=body_html,
            stylesheet=_stylesheet(theme),
            resources=resources,
            anchors=anchors,
        )

    def render_into(
        self,
        document: QTextDocument,
        markdown_text: str,
        theme: str = "dark",
        device_pixel_ratio: float = 1.0,
        text_color: str = "",
    ) -> RenderedMarkdown:
        """Renderiza `markdown_text` directamente dentro de `document`:
        aplica la hoja de estilos del tema y setea el HTML."""
        rendered = self.render(markdown_text, theme, device_pixel_ratio, text_color)
        document.setDefaultStyleSheet(rendered.stylesheet)
        document.setHtml(rendered.html)
        return rendered

    def render_file_into(
        self,
        document: QTextDocument,
        path: str,
        theme: str = "dark",
        device_pixel_ratio: float = 1.0,
        text_color: str = "",
    ) -> RenderedMarkdown:
        """Igual que `render_into` leyendo el Markdown desde disco."""
        text = Path(path).read_text(encoding="utf-8")
        return self.render_into(document, text, theme, device_pixel_ratio, text_color)

    def render_resource_into(
        self,
        document: QTextDocument,
        relative_path: str,
        theme: str = "dark",
        device_pixel_ratio: float = 1.0,
        text_color: str = "",
    ) -> RenderedMarkdown:
        """Igual que `render_into` leyendo el Markdown desde un recurso Qt
        embebido (`:/<relative_path>`, ver `resources.qrc`), con fallback
        a filesystem para dev/tests. Usado por el módulo Fórmulas para
        renderizar `assets/docs/formulas.md`."""
        text = load_resource_text(relative_path)
        return self.render_into(document, text, theme, device_pixel_ratio, text_color)

    # ── Interno ──────────────────────────────────────────────────────

    def _replace_math_with_images(
        self,
        body_html: str,
        block_formulas: list[str],
        inline_formulas: list[str],
        theme: str,
        device_pixel_ratio: float,
        text_color: str,
    ) -> tuple[str, dict[str, str]]:
        palette = _THEMES[theme]
        color = _normalize_color(text_color) or palette["fg"]
        resources: dict[str, str] = {}

        for idx, formula in enumerate(block_formulas):
            path = self._formulas.render(
                formula,
                color=color,
                size_px=_BLOCK_MATH_SIZE_PX,
                device_pixel_ratio=device_pixel_ratio,
            )
            url = QUrl.fromLocalFile(str(path)).toString()
            resources[formula] = url
            placeholder = _MATH_BLOCK_PLACEHOLDER.format(idx=idx)
            body_html = body_html.replace(
                placeholder,
                f'</p><p align="center"><img src="{url}"></p><p>',
            )

        for idx, formula in enumerate(inline_formulas):
            path = self._formulas.render(
                formula,
                color=color,
                size_px=_INLINE_MATH_SIZE_PX,
                device_pixel_ratio=device_pixel_ratio,
            )
            url = QUrl.fromLocalFile(str(path)).toString()
            resources[formula] = url
            placeholder = _MATH_INLINE_PLACEHOLDER.format(idx=idx)
            body_html = body_html.replace(placeholder, f'<img src="{url}">')

        return body_html, resources
