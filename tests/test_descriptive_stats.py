"""Tests de mediana/moda/media/rango (src/services/calculator.py +
src/services/descriptive_stats.py)."""

from __future__ import annotations

from src.schemas.table import Table, TableItem, TableType
from src.services.calculator import TableCalculator


def _tabla(data_type: TableType, items: list[TableItem]) -> Table:
    calc = TableCalculator()
    table = Table(data_type=data_type, items=items)
    calc.calculate(table)
    return table


def test_no_agrupados_media_mediana_moda_rango() -> None:
    calc = TableCalculator()
    items = [TableItem(xi=x, f=1) for x in [3, 6, 4, 6, 2, 5, 6, 4]]
    table = _tabla(TableType.NO_AGRUPADOS, items)

    assert calc.calculate_mean(table) == 4.5
    assert calc.calculate_median(table) == 4.5
    assert calc.calculate_mode(table) == "6"
    assert calc.calculate_rango(table) == 4.0


def test_no_agrupados_multimodal() -> None:
    calc = TableCalculator()
    items = [TableItem(xi=x, f=1) for x in [1, 1, 2, 2, 3]]
    table = _tabla(TableType.NO_AGRUPADOS, items)

    moda = calc.calculate_mode(table)
    assert set(moda.split(", ")) == {"1", "2"}


def test_agrupados_valor_amodal() -> None:
    calc = TableCalculator()
    items = [TableItem(xi=1, f=2), TableItem(xi=2, f=2), TableItem(xi=3, f=2)]
    table = _tabla(TableType.AGRUPADOS_VALOR, items)

    assert calc.calculate_mode(table) == "No definida"


def test_agrupados_intervalo_mediana_moda() -> None:
    calc = TableCalculator()
    items = [
        TableItem(xi=(l + u) / 2, f=f, lower=l, upper=u)
        for l, u, f in [(0, 20, 15), (20, 40, 25), (40, 60, 60)]
    ]
    table = _tabla(TableType.AGRUPADOS_INTERVALO, items)

    assert calc.calculate_mean(table) == 39.0
    # Clase mediana: la de [20,40) porque fa=15,40 alcanza n/2=50 en [40,60).
    # n=100 -> n/2=50; fa(0,20)=15, fa(20,40)=40, fa(40,60)=100 -> clase [40,60)
    mediana = calc.calculate_median(table)
    assert 40 <= mediana <= 60
    # Clase modal es la de mayor frecuencia: [40, 60)
    moda = float(calc.calculate_mode(table))
    assert 40 <= moda <= 60


def test_rango_intervalos() -> None:
    calc = TableCalculator()
    items = [
        TableItem(xi=(l + u) / 2, f=f, lower=l, upper=u)
        for l, u, f in [(0, 20, 15), (20, 40, 25), (40, 60, 60)]
    ]
    table = _tabla(TableType.AGRUPADOS_INTERVALO, items)
    assert calc.calculate_rango(table) == 60.0
