"""
Parsers y validadores de entrada compartidos por los módulos de
Frecuencias y Dispersión.

Cada función pública recibe datos crudos (string o lista de dicts, tal
como llegan desde QML) y devuelve una lista de items (TableItem o
DispersionItem) lista para ser calculada, o lanza ParseError con un
mensaje apto para mostrar al usuario.

La lógica de parsing/validación es genérica: se parametriza con un
"item_factory" (la clase pydantic a construir) para evitar duplicar
código entre los dos módulos.
"""

from schemas.dispersion import DispersionItem
from schemas.table import TableItem


class ParseError(ValueError):
    """Error de validación al parsear datos de entrada de tablas estadísticas."""


# Alias para mantener nombres específicos por módulo.
DispersionParseError = ParseError
TableParseError = ParseError


def _parse_float(valor: str, campo: str, fila_idx: int) -> float:
    valor = valor.strip()
    try:
        return float(valor.replace(",", "."))
    except ValueError:
        raise ParseError(
            f"Fila {fila_idx}: {campo} «{valor}» no es un número válido."
        )


def _parse_frecuencia(valor: str, fila_idx: int) -> int:
    valor = valor.strip()
    try:
        f = int(valor)
    except ValueError:
        raise ParseError(
            f"Fila {fila_idx}: la frecuencia «{valor}» debe ser un entero."
        )
    if f <= 0:
        raise ParseError(
            f"Fila {fila_idx}: la frecuencia debe ser un entero positivo (recibido: {f})."
        )
    return f


def _validate_no_overlap(items: list) -> None:
    """Detecta intervalos superpuestos. Los contiguos (upper == lower) están permitidos."""
    for i in range(len(items) - 1):
        actual = items[i]
        siguiente = items[i + 1]
        if actual.upper > siguiente.lower:
            raise ParseError(
                f"Los intervalos [{actual.lower}, {actual.upper}] y "
                f"[{siguiente.lower}, {siguiente.upper}] se superponen."
            )


# ── Helpers genéricos (parametrizados por item_factory) ────────────────────


def _parse_lista_valores(valores_str: str, item_factory) -> list:
    """
    Parsea una lista de valores individuales separados por punto y coma (;).

    El separador decimal puede ser "," o "." indistintamente (ambos se
    normalizan a punto en _parse_float); por eso no pueden usarse como
    separador de valores, y el splitter es el punto y coma.
    """
    partes = [p.strip() for p in valores_str.split(";") if p.strip() != ""]
    if not partes:
        raise ParseError("Ingresá al menos un valor.")

    items = []
    for idx, parte in enumerate(partes, start=1):
        xi = _parse_float(parte, "el valor", idx)
        items.append(item_factory(xi=xi, f=1))
    return items


def _parse_valor_filas(filas: list[dict], item_factory) -> list:
    """Parsea filas [{xi, frecuencia}, ...]."""
    filas_con_datos = [
        f
        for f in filas
        if str(f.get("xi", "")).strip() != "" or str(f.get("frecuencia", "")).strip() != ""
    ]

    if not filas_con_datos:
        raise ParseError("Ingresá al menos un par Xi / Frecuencia.")

    items = []
    for idx, fila in enumerate(filas_con_datos, start=1):
        xi_str = str(fila.get("xi", "")).strip()
        f_str = str(fila.get("frecuencia", "")).strip()

        if xi_str == "" or f_str == "":
            raise ParseError(
                f"Fila {idx}: ambos campos (Xi y Frecuencia) son obligatorios."
            )

        xi = _parse_float(xi_str, "Xi", idx)
        f = _parse_frecuencia(f_str, idx)
        items.append(item_factory(xi=xi, f=f))

    return items


def _parse_intervalo_filas(filas: list[dict], item_factory) -> list:
    """
    Parsea filas [{lower, upper, frecuencia}, ...].

    Valida que lower < upper, ordena por límite inferior ascendente y
    detecta intervalos superpuestos (los contiguos están permitidos).
    """
    filas_con_datos = [
        f
        for f in filas
        if any(str(f.get(k, "")).strip() != "" for k in ("lower", "upper", "frecuencia"))
    ]

    if not filas_con_datos:
        raise ParseError("Ingresá al menos un intervalo.")

    items = []
    for idx, fila in enumerate(filas_con_datos, start=1):
        lower_str = str(fila.get("lower", "")).strip()
        upper_str = str(fila.get("upper", "")).strip()
        f_str = str(fila.get("frecuencia", "")).strip()

        if lower_str == "" or upper_str == "" or f_str == "":
            raise ParseError(
                f"Fila {idx}: los campos límite inferior, límite superior y "
                "frecuencia son obligatorios."
            )

        lower = _parse_float(lower_str, "el límite inferior", idx)
        upper = _parse_float(upper_str, "el límite superior", idx)
        f = _parse_frecuencia(f_str, idx)

        if lower >= upper:
            raise ParseError(
                f"Fila {idx}: el límite inferior ({lower}) debe ser menor "
                f"que el límite superior ({upper})."
            )

        xi = (lower + upper) / 2
        items.append(item_factory(xi=xi, f=f, lower=lower, upper=upper))

    items.sort(key=lambda i: i.lower)
    _validate_no_overlap(items)

    return items


# ── API pública: Dispersión ─────────────────────────────────────────────────


def parse_no_agrupados(valores_str: str) -> list[DispersionItem]:
    """Parsea una lista de valores individuales, ej: '3, 6, 4, 6, 2, 5, 6, 4'."""
    return _parse_lista_valores(valores_str, DispersionItem)


def parse_agrupados_valor(filas: list[dict]) -> list[DispersionItem]:
    """Parsea filas [{xi, frecuencia}, ...]."""
    return _parse_valor_filas(filas, DispersionItem)


def parse_agrupados_intervalo(filas: list[dict]) -> list[DispersionItem]:
    """Parsea filas [{lower, upper, frecuencia}, ...]."""
    return _parse_intervalo_filas(filas, DispersionItem)


# ── API pública: Frecuencias ─────────────────────────────────────────────────


def parse_table_no_agrupados(valores_str: str) -> list[TableItem]:
    """
    Parsea una lista de valores individuales. Cada valor se registra con
    f=1; TableCalculator se encarga de unificar/contar las repeticiones,
    generando automáticamente la tabla de frecuencias.
    """
    return _parse_lista_valores(valores_str, TableItem)


def parse_table_agrupados_valor(filas: list[dict]) -> list[TableItem]:
    """Parsea filas [{xi, frecuencia}, ...]."""
    return _parse_valor_filas(filas, TableItem)


def parse_table_agrupados_intervalo(filas: list[dict]) -> list[TableItem]:
    """Parsea filas [{lower, upper, frecuencia}, ...]."""
    return _parse_intervalo_filas(filas, TableItem)
