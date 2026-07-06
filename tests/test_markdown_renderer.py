"""Tests de services/markdown_renderer.py: conversión Markdown -> rich
text de Qt con markdown-it-py, fórmulas LaTeX rasterizadas con
matplotlib.mathtext (PNG cacheados) y soporte de temas.

No se usa QtWebEngine ni KaTeX: el visor es 100% nativo de Qt."""

from __future__ import annotations

from pathlib import Path

from services.markdown_renderer import MarkdownRenderer
from services.template_loader import load_resource_text


def _html(markdown: str, **kwargs) -> str:
    return MarkdownRenderer().render(markdown, **kwargs).html


def _path_from_file_url(url: str) -> Path:
    assert url.startswith("file://")
    return Path(url.removeprefix("file://"))


def test_headings() -> None:
    body = _html("# Titulo\n\n## Subtitulo\n")
    assert '<h1 id="titulo">Titulo</h1>' in body
    assert '<h2 id="subtitulo">Subtitulo</h2>' in body


def test_heading_anchors_for_internal_links() -> None:
    rendered = MarkdownRenderer().render("## 1. Notación básica\n")
    assert 'id="1-notación-básica"' in rendered.html
    assert rendered.anchors["1-notación-básica"] == "1. Notación básica"


def test_bold_and_italic() -> None:
    body = _html("**negrita** y *cursiva*")
    assert "<strong>negrita</strong>" in body
    assert "<em>cursiva</em>" in body


def test_lists() -> None:
    body = _html("- uno\n- dos\n- tres\n")
    assert "<li>uno</li>" in body
    assert body.count("<li>") == 3


def test_ordered_list() -> None:
    assert "<ol>" in _html("1. a\n2. b\n")


def test_table_has_borders_for_qtextdocument() -> None:
    body = _html("| A | B |\n|---|---|\n| 1 | 2 |\n")
    # QTextDocument no aplica border-collapse desde CSS: la tabla lleva
    # atributos de borde para verse con líneas.
    assert '<table border="1"' in body
    assert "<th>A</th>" in body
    assert "<td>1</td>" in body


def test_code_block() -> None:
    body = _html("```python\nprint('hola')\n```\n")
    assert "<pre>" in body
    assert "print" in body


def test_inline_code() -> None:
    assert "<code>codigo</code>" in _html("Usa `codigo` aca.")


def test_link() -> None:
    assert '<a href="https://example.com">texto</a>' in _html(
        "[texto](https://example.com)"
    )


def test_unicode_characters() -> None:
    body = _html("Ñandú, café, año, 你好")
    assert "Ñandú" in body
    assert "café" in body
    assert "你好" in body


def test_inline_math_becomes_cached_image_file() -> None:
    rendered = MarkdownRenderer().render(r"La media es \(\bar{x}\).")
    url = rendered.resources[r"\bar{x}"]
    assert f'<img src="{url}">' in rendered.html
    assert _path_from_file_url(url).exists()


def test_block_math_becomes_centered_cached_image_file() -> None:
    md = "\\[\n\\bar{x}=\\frac{\\sum x_i f_i}{\\sum f_i}\n\\]\n"
    formula = r"\bar{x}=\frac{\sum x_i f_i}{\sum f_i}"
    rendered = MarkdownRenderer().render(md)
    url = rendered.resources[formula]
    assert f'<img src="{url}">' in rendered.html
    assert 'align="center"' in rendered.html
    assert _path_from_file_url(url).exists()


def test_displaystyle_formula_does_not_crash() -> None:
    """LaTeX displaystyle no soportado debe rasterizar igual."""
    formula = r"\displaystyle s^2=\frac{\sum(x_i-\bar{x})^2}{n-1}"
    rendered = MarkdownRenderer().render(rf"| x | \({formula}\) |")
    assert _path_from_file_url(rendered.resources[formula]).exists()


def test_dollar_amounts_not_treated_as_math() -> None:
    rendered = MarkdownRenderer().render("Precio: $100 y otro $50.")
    assert "$100" in rendered.html
    assert "$50" in rendered.html
    assert "MATHBLOCKPLACEHOLDER" not in rendered.html
    assert "MATHINLINEPLACEHOLDER" not in rendered.html
    assert rendered.resources == {}


def test_no_html_injection_from_markdown() -> None:
    """html=False: el HTML embebido en el Markdown de entrada se escapa,
    no se ejecuta ni se inserta como HTML crudo."""
    body = _html("<script>alert('x')</script>")
    assert "<script>alert" not in body
    assert "&lt;script&gt;" in body


def test_no_remote_resources() -> None:
    """El visor es 100% offline: no debe referenciar CDNs ni URLs
    remotas en el HTML generado."""
    rendered = MarkdownRenderer().render(r"# Titulo \(\bar{x}\)")
    assert "http://" not in rendered.html
    assert "https://" not in rendered.html
    assert "cdn." not in rendered.html


def test_theme_dark_stylesheet() -> None:
    css = MarkdownRenderer().render("texto", theme="dark").stylesheet
    assert "#6cb6ff" in css  # link dark


def test_theme_light_stylesheet() -> None:
    css = MarkdownRenderer().render("texto", theme="light").stylesheet
    assert "#0b57d0" in css  # link light


def test_invalid_theme_falls_back_to_dark() -> None:
    css = MarkdownRenderer().render("texto", theme="rosa").stylesheet
    assert "#6cb6ff" in css


def test_hidpi_generates_cached_image_file() -> None:
    rendered = MarkdownRenderer().render(r"\(\bar{x}\)", device_pixel_ratio=2.0)
    assert _path_from_file_url(rendered.resources[r"\bar{x}"]).exists()


def test_formula_cache_reuses_same_file() -> None:
    renderer = MarkdownRenderer()
    a = renderer.render(r"\(\bar{x}\)").resources[r"\bar{x}"]
    b = renderer.render(r"\(\bar{x}\)").resources[r"\bar{x}"]
    assert a == b
    assert _path_from_file_url(a).exists()


def test_render_resource_from_module_formulas() -> None:
    """render_resource: usado por el módulo Fórmulas para convertir
    assets/docs/formulas.md (embebido como recurso Qt, con fallback a
    filesystem en dev/tests)."""
    rendered = MarkdownRenderer().render(load_resource_text("assets/docs/formulas.md"))
    assert "Fórmulas prácticas de Estadística" in rendered.html
    assert '<table border="1"' in rendered.html
    assert len(rendered.resources) > 0
