"""Estadística descriptiva compartida entre Frecuencias y Dispersión.

Contiene únicamente las medidas que ambos módulos necesitan en común
(media y rango), para no duplicar esa lógica entre `TableCalculator` y
`DispersionCalculator`. Mediana y moda viven solo en el lado de
Frecuencias (`TableCalculator`); varianza/desvío/CV viven solo en
Dispersión (`DispersionCalculator`).

Los items recibidos solo necesitan exponer `xi`, `f`, `lower` y `upper`
(duck-typing), por lo que sirve tanto para `TableItem` como para
`DispersionItem`.
"""

from enum import Enum
from typing import Protocol


class _Item(Protocol):
    xi: float
    f: int
    lower: float | None
    upper: float | None


def mean(items: list[_Item]) -> float:
    """Media aritmética Σ(Xi·fi) / n. Devuelve 0.0 si no hay datos."""
    n = sum(item.f for item in items)
    if n == 0:
        return 0.0
    return round(sum(item.xi * item.f for item in items) / n, 2)


def rango(items: list[_Item], data_type: Enum) -> float:
    """
    Rango: para intervalos, límite superior máximo menos límite inferior
    mínimo; para el resto, Xi máximo menos Xi mínimo.
    """
    if data_type.value == "agrupados_intervalo":
        maximo = max(i.upper for i in items if i.upper is not None)
        minimo = min(i.lower for i in items if i.lower is not None)
    else:
        maximo = max(i.xi for i in items)
        minimo = min(i.xi for i in items)
    return round(maximo - minimo, 2)
