"""Tests de services/markdown_io.py: render y parse de datos de entrada
en formato Markdown, para los 3 tipos de dato y ambos módulos."""

from __future__ import annotations

import pytest

from services import markdown_io


def test_render_parse_no_agrupados_round_trip() -> None:
    md = markdown_io.render_no_agrupados("frecuencias", "3; 6; 4; 6; 2; 5; 6; 4")
    assert "type: no-agrupados" in md
    assert "module: frecuencias" in md

    parsed = markdown_io.parse_input_markdown(md)
    assert parsed.data_type == "no_agrupados"
    assert parsed.module == "frecuencias"
    assert parsed.text == "3; 6; 4; 6; 2; 5; 6; 4"


def test_render_parse_agrupados_valor_round_trip() -> None:
    rows = [{"xi": 700, "frecuencia": 5}, {"xi": 800, "frecuencia": 5}, {"xi": 1200, "frecuencia": 4}]
    md = markdown_io.render_agrupados_valor("dispersion", rows)
    assert "type: agrupados-valor" in md
    assert "module: dispersion" in md

    parsed = markdown_io.parse_input_markdown(md)
    assert parsed.data_type == "agrupados_valor"
    assert parsed.module == "dispersion"
    assert parsed.rows == [
        {"xi": "700", "frecuencia": "5"},
        {"xi": "800", "frecuencia": "5"},
        {"xi": "1200", "frecuencia": "4"},
    ]


def test_render_parse_agrupados_intervalo_round_trip() -> None:
    rows = [
        {"lower": 0, "upper": 20, "frecuencia": 15},
        {"lower": 20, "upper": 40, "frecuencia": 25},
        {"lower": 40, "upper": 60, "frecuencia": 60},
    ]
    md = markdown_io.render_agrupados_intervalo("frecuencias", rows)
    assert "type: agrupados-intervalos" in md

    parsed = markdown_io.parse_input_markdown(md)
    assert parsed.data_type == "agrupados_intervalo"
    assert parsed.module == "frecuencias"
    assert parsed.rows == [
        {"lower": "0", "upper": "20", "frecuencia": "15"},
        {"lower": "20", "upper": "40", "frecuencia": "25"},
        {"lower": "40", "upper": "60", "frecuencia": "60"},
    ]


def test_parse_sin_encabezado_lanza_error() -> None:
    with pytest.raises(markdown_io.MarkdownIOError):
        markdown_io.parse_input_markdown("10, 12, 8, 15, 9")


def test_parse_tipo_desconocido_lanza_error() -> None:
    texto = "---\ntype: invalido\nmodule: frecuencias\n---\n1; 2; 3"
    with pytest.raises(markdown_io.MarkdownIOError):
        markdown_io.parse_input_markdown(texto)


def test_parse_modulo_desconocido_lanza_error() -> None:
    texto = "---\ntype: no-agrupados\nmodule: otro\n---\n1; 2; 3"
    with pytest.raises(markdown_io.MarkdownIOError):
        markdown_io.parse_input_markdown(texto)


def test_render_resultado_frecuencias() -> None:
    context = {
        "intervalos": False,
        "rows": [{"label": 5, "f": 3, "fr": 0.3, "fa": 3, "f_percent": 30.0, "fa_percent": 30.0}],
        "n": 10,
        "mean": "5.00",
        "mediana": "5.00",
        "moda": "5",
        "rango": "4.00",
    }
    md = markdown_io.render_resultado_frecuencias(context)
    assert "Tabla de frecuencias" in md
    assert "Mediana (Me):** 5.00" in md
    assert "Moda (Mo):** 5" in md


def test_render_resultado_dispersion() -> None:
    context = {
        "intervalos": False,
        "poblacional": False,
        "rows": [{"label": 5, "f": 3, "diff": 0.5, "diffSq": 0.25, "fDiffSq": 0.75}],
        "n": 10,
        "mean": "5.00",
        "rango": "4.00",
        "varianza": "1.00",
        "desvio": "1.00",
        "cv": "20.00",
    }
    md = markdown_io.render_resultado_dispersion(context)
    assert "Muestra" in md
    assert "s²" in md
