"""Carga de texto embebido como recurso Qt (ver `resources.qrc`), con
fallback a filesystem para tests y otros contextos que no cargan
`resources_rc`.

Único punto de lectura de plantillas Jinja2 (`src.services.markdown_io`,
`src.services.markdown_renderer`) y de otros archivos de texto embebidos
como recurso (p. ej. `assets/docs/formulas.md`, ver
`src.controllers.MarkdownController.renderFormulas`).
"""

from __future__ import annotations

from pathlib import Path

from jinja2 import Template

from src.services.runtime_paths import app_base_dir


def load_resource_text(relative_path: str) -> str:
    """Lee el contenido de `relative_path` (p. ej.
    `assets/docs/formulas.md`) desde `:/<relative_path>` (recurso Qt
    embebido) o, si no está disponible, desde el filesystem relativo a
    `app_base_dir()`."""
    try:
        from PySide6.QtCore import QFile, QIODevice

        qfile = QFile(f":/{relative_path}")
        if qfile.open(QIODevice.ReadOnly | QIODevice.Text):
            try:
                data = bytes(qfile.readAll()).decode("utf-8")
            finally:
                qfile.close()
            if data:
                return data
    except ImportError:
        pass

    path = Path(app_base_dir()) / relative_path
    return path.read_text(encoding="utf-8")


def load_template_text(filename: str) -> str:
    """Lee el contenido de una plantilla desde `assets/templates/`."""
    return load_resource_text(f"assets/templates/{filename}")


def render_template(filename: str, **context) -> str:
    """Carga la plantilla `filename` y la renderiza con Jinja2."""
    template_text = load_template_text(filename)
    return Template(template_text).render(**context)
