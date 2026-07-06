"""Copiar/pegar datos en formato Markdown entre los módulos de
Frecuencias y Dispersión.

- Renderizado: se usan plantillas Jinja2 embebidas como recursos Qt
  (`assets/templates/*.md.j2`, ver `resources.qrc`).
- Parseo: se detecta el tipo de dato/módulo a través de un encabezado
  fijo (`---\\ntype: ...\\nmodule: ...\\n---`), y las tablas Markdown se
  extraen convirtiéndolas a HTML con `markdown-it-py` (mismo motor que
  `src.services.markdown_renderer`) + `html.parser.HTMLParser`, en vez de
  reimplementar un parser de tablas Markdown a mano.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from html.parser import HTMLParser

from markdown_it import MarkdownIt

from src.services.template_loader import render_template

_table_md = MarkdownIt("commonmark", {"html": False}).enable(["table"])

# Mapeo entre el valor de "type" usado en el encabezado Markdown (con
# guiones, legible para humanos) y el valor interno usado por
# TableType/DispersionType (con guion bajo).
_TYPE_MD_TO_INTERNAL = {
    "no-agrupados": "no_agrupados",
    "agrupados-valor": "agrupados_valor",
    "agrupados-intervalos": "agrupados_intervalo",
}
_TYPE_INTERNAL_TO_MD = {v: k for k, v in _TYPE_MD_TO_INTERNAL.items()}

_MODULES = ("frecuencias", "dispersion")

_TEMPLATE_FILES = {
    "no_agrupados": "no_agrupados.md.j2",
    "agrupados_valor": "agrupados_valor.md.j2",
    "agrupados_intervalo": "agrupados_intervalos.md.j2",
    "resultado_frecuencias": "resultado_frecuencias.md.j2",
    "resultado_dispersion": "resultado_dispersion.md.j2",
}

_HEADER_RE = re.compile(r"^\s*---\s*\n(.*?)\n---\s*\n?(.*)$", re.DOTALL)
_HEADER_FIELD_RE = re.compile(r"^\s*`?([A-Za-z_]+)`?\s*:\s*(.+?)\s*$")


class MarkdownIOError(ValueError):
    """Error al renderizar o parsear datos en formato Markdown."""


@dataclass
class ParsedInput:
    data_type: str  # "no_agrupados" | "agrupados_valor" | "agrupados_intervalo"
    module: str  # "frecuencias" | "dispersion"
    text: str | None = None  # para no_agrupados
    rows: list[dict] | None = None  # para agrupados_valor / agrupados_intervalo


def _render(template_key: str, **context) -> str:
    return render_template(_TEMPLATE_FILES[template_key], **context).strip() + "\n"


# ── Renderizado de entrada (para "Copiar datos") ────────────────────────────


def render_no_agrupados(module: str, valores: str) -> str:
    return _render("no_agrupados", module=module, valores=valores.strip())


def render_agrupados_valor(module: str, rows: list[dict]) -> str:
    return _render("agrupados_valor", module=module, rows=rows)


def render_agrupados_intervalo(module: str, rows: list[dict]) -> str:
    return _render("agrupados_intervalo", module=module, rows=rows)


# ── Renderizado de resultados (para "Copiar tabla") ─────────────────────────


def render_resultado_frecuencias(context: dict) -> str:
    return _render("resultado_frecuencias", **context)


def render_resultado_dispersion(context: dict) -> str:
    return _render("resultado_dispersion", **context)


# ── Parseo (para "Pegar datos") ─────────────────────────────────────────────


class _TableHTMLParser(HTMLParser):
    """Extrae filas de la primera tabla HTML encontrada (ignora <thead>)."""

    def __init__(self) -> None:
        super().__init__()
        self.rows: list[list[str]] = []
        self._current_row: list[str] | None = None
        self._current_cell: list[str] | None = None
        self._in_thead = False

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag == "thead":
            self._in_thead = True
        elif tag == "tr":
            self._current_row = []
        elif tag in ("td", "th"):
            self._current_cell = []

    def handle_endtag(self, tag: str) -> None:
        if tag == "thead":
            self._in_thead = False
        elif tag == "tr":
            if self._current_row is not None and not self._in_thead:
                self.rows.append(self._current_row)
            self._current_row = None
        elif tag in ("td", "th"):
            if self._current_cell is not None and self._current_row is not None:
                self._current_row.append("".join(self._current_cell).strip())
            self._current_cell = None

    def handle_data(self, data: str) -> None:
        if self._current_cell is not None:
            self._current_cell.append(data)


def _extract_table_rows(markdown_text: str) -> list[list[str]]:
    html = _table_md.render(markdown_text)
    parser = _TableHTMLParser()
    parser.feed(html)
    return parser.rows


def parse_input_markdown(text: str) -> ParsedInput:
    """
    Parsea un texto Markdown pegado por el usuario, detectando
    automáticamente el tipo de dato y el módulo a través del encabezado:

        ---
        type: no-agrupados | agrupados-valor | agrupados-intervalos
        module: frecuencias | dispersion
        ---

    Lanza MarkdownIOError con un mensaje apto para mostrar al usuario si
    el encabezado falta o es inválido.
    """
    match = _HEADER_RE.match(text.strip())
    if not match:
        raise MarkdownIOError(
            "El texto pegado no tiene el encabezado esperado "
            "(---\ntype: ...\nmodule: ...\n---)."
        )

    header_block, body = match.groups()
    header: dict[str, str] = {}
    for line in header_block.splitlines():
        field_match = _HEADER_FIELD_RE.match(line)
        if field_match:
            key = field_match.group(1).lower()
            header[key] = field_match.group(2).strip("`").strip()

    type_md = header.get("type", "")
    module = header.get("module", "")

    if type_md not in _TYPE_MD_TO_INTERNAL:
        raise MarkdownIOError(
            f"Tipo de datos desconocido en el encabezado: «{type_md}»."
        )
    if module not in _MODULES:
        raise MarkdownIOError(f"Módulo desconocido en el encabezado: «{module}».")

    data_type = _TYPE_MD_TO_INTERNAL[type_md]
    body = body.strip()

    if data_type == "no_agrupados":
        if not body:
            raise MarkdownIOError("El bloque de valores está vacío.")
        return ParsedInput(data_type=data_type, module=module, text=body)

    table_rows = _extract_table_rows(body)
    if not table_rows:
        raise MarkdownIOError("No se encontró una tabla Markdown válida en el texto.")

    if data_type == "agrupados_valor":
        rows = [
            {"xi": row[0], "frecuencia": row[1]} for row in table_rows if len(row) >= 2
        ]
    else:
        rows = [
            {"lower": row[0], "upper": row[1], "frecuencia": row[2]}
            for row in table_rows
            if len(row) >= 3
        ]

    if not rows:
        raise MarkdownIOError("La tabla Markdown no tiene columnas suficientes.")

    return ParsedInput(data_type=data_type, module=module, rows=rows)
