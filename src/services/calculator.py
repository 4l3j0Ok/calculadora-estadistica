import math

from src.schemas.dispersion import DispersionItem, DispersionResult, DispersionType
from src.schemas.table import Table, TableItem, TableType
from src.services import descriptive_stats


def format_number(v: float) -> str:
    """Formatea un número sin decimales innecesarios (ej: 5.0 -> '5')."""
    v = round(v, 2)
    return f"{v:.0f}" if v == int(v) else f"{v:g}"


# Alias privado retrocompatible, usado dentro de este módulo.
_fmt_num = format_number

# - Frecuencia absoluta (f): Es la cantidad de veces que se repite cada valor
# de la variable
# - Frecuencia Relativa (fr): Es el cociente entre la frecuencia absoluta y el
# total de elementos que forman la muestra
# - Frecuencia acumulada (F): Es la frecuencia que se obtiene haciendo la
# suma parcial de frecuencias absolutas
# - Frecuencia porcentual: (f%) Es la frecuencia que mide los datos en
# porcentajes, se obtiene multiplicando la frecuencia relativa por cien.
# - Frecuencia porcentual acumulada (fa%) Se obtiene haciendo la suma
# parcial de las frecuencias porcentuales.


class TableCalculator:
    """Calcula las frecuencias de una tabla estadística.

    Soporta tres tipos de datos de entrada (ver TableType):
    - no agrupados: valores individuales, se unifican y cuentan como
      "agrupados por valor" (el resultado es la misma tabla de frecuencias).
    - agrupados por valor: pares (Xi, f), se unifican Xi repetidos.
    - agrupados por intervalos: cada item ya trae lower/upper/f; no se
      unifican (cada intervalo es una fila propia), solo se ordenan.
    """

    def merge_and_sort(
        self, items: list[TableItem], data_type: TableType = TableType.AGRUPADOS_VALOR
    ) -> list[TableItem]:
        """
        Para intervalos: ordena por límite inferior (no unifica).
        Para no agrupados / agrupados por valor: unifica items con el mismo
        valor xi sumando sus frecuencias, y ordena el resultado por xi
        ascendente.

        Retorna una nueva lista de TableItem.
        """
        if data_type == TableType.AGRUPADOS_INTERVALO:
            return sorted(items, key=lambda i: i.lower if i.lower is not None else i.xi)

        merged: dict[float, int] = {}
        for item in items:
            merged[item.xi] = merged.get(item.xi, 0) + item.f

        return [TableItem(xi=xi, f=f) for xi, f in sorted(merged.items())]

    def calculate_relative_frequency(self, table: Table) -> None:
        """
        Calcula la frecuencia relativa para cada elemento de la tabla.

        El resultado se redondea al centésimo (2 decimales).

        Modifica los items de la tabla en lugar de retornar nuevos objetos.
        """
        total_frequency = sum(item.f for item in table.items)
        for item in table.items:
            fr = item.f / total_frequency if total_frequency > 0 else 0.0
            item.fr = round(fr, 2)

    def calculate_cumulative_frequency(self, table: Table) -> None:
        """
        Calcula la frecuencia acumulada para cada elemento de la tabla.

        Modifica los items de la tabla en lugar de retornar nuevos objetos.
        """
        cumulative_frequency = 0
        for item in table.items:
            cumulative_frequency += item.f
            item.fa = cumulative_frequency

    def calculate_percentage_frequency(self, table: Table) -> None:
        """
        Calcula la frecuencia porcentual para cada elemento de la tabla.

        El resultado se redondea al centésimo (2 decimales).

        Modifica los items de la tabla en lugar de retornar nuevos objetos.
        """
        for item in table.items:
            item.f_percent = round((item.fr or 0) * 100, 2)

    def calculate_cumulative_percentage_frequency(self, table: Table) -> None:
        """
        Calcula la frecuencia porcentual acumulada para cada elemento de la tabla.

        Modifica los items de la tabla en lugar de retornar nuevos objetos.
        """
        cumulative_percentage = 0.0
        for item in table.items:
            cumulative_percentage += item.f_percent or 0
            item.fa_percent = round(cumulative_percentage, 2)

    def calculate(self, table: Table) -> None:
        """
        Prepara (merge + sort), luego calcula todas las frecuencias de la tabla.

        Aplica todos los cálculos en secuencia:
        merge/sort → relativa → acumulada → porcentual → acumulada porcentual.
        Todos los resultados (fr, f%, fa%) se redondean al centésimo
        (2 decimales).

        Modifica la tabla recibida en lugar de retornar nuevos objetos.
        """
        table.items = self.merge_and_sort(table.items, table.data_type)
        self.calculate_relative_frequency(table)
        self.calculate_cumulative_frequency(table)
        self.calculate_percentage_frequency(table)
        self.calculate_cumulative_percentage_frequency(table)

    # ── Medidas de resumen (media, mediana, moda, rango) ───────────────────
    # Deben llamarse después de `calculate()`, ya que usan los items
    # mergeados/ordenados (y, para la mediana, la frecuencia acumulada `fa`
    # ya calculada).

    def calculate_mean(self, table: Table) -> float:
        """Media aritmética Σ(Xi·fi) / n."""
        return descriptive_stats.mean(table.items)

    def calculate_rango(self, table: Table) -> float:
        """Rango (máximo - mínimo, o límite superior - límite inferior)."""
        return descriptive_stats.rango(table.items, table.data_type)

    def calculate_median(self, table: Table) -> float:
        """
        Mediana.

        - No agrupados / agrupados por valor: mediana clásica sobre los
          datos expandidos según su frecuencia.
        - Agrupados por intervalos: fórmula de interpolación
          Me = Li + ((n/2 - Fa_ant) / fi) · a, usando la clase donde la
          frecuencia acumulada alcanza o supera n/2.
        """
        items = table.items
        n = sum(item.f for item in items)
        if n == 0:
            return 0.0

        if table.data_type == TableType.AGRUPADOS_INTERVALO:
            mitad = n / 2
            acumulada_anterior = 0
            for item in items:
                acumulada_actual = item.fa if item.fa is not None else 0
                if acumulada_actual >= mitad:
                    amplitud = item.upper - item.lower
                    if item.f == 0:
                        return round(item.lower, 2)
                    return round(
                        item.lower + ((mitad - acumulada_anterior) / item.f) * amplitud,
                        2,
                    )
                acumulada_anterior = acumulada_actual
            return 0.0

        expandido: list[float] = []
        for item in items:
            expandido.extend([item.xi] * item.f)
        expandido.sort()

        medio = len(expandido) // 2
        if len(expandido) % 2 == 1:
            return round(expandido[medio], 2)
        return round((expandido[medio - 1] + expandido[medio]) / 2, 2)

    def calculate_mode(self, table: Table) -> str:
        """
        Moda, formateada como string.

        - No agrupados / agrupados por valor: valor(es) con mayor
          frecuencia; si hay empate, se listan todos separados por coma
          (multimodal). Si todos los valores tienen la misma frecuencia
          (y hay más de uno), se considera "No definida" (amodal).
        - Agrupados por intervalos: fórmula de interpolación de la clase
          modal, Mo = Li + (d1 / (d1 + d2)) · a, con d1 = fi - f_anterior
          y d2 = fi - f_siguiente.
        """
        items = table.items
        if not items:
            return "—"

        max_f = max(item.f for item in items)

        if table.data_type == TableType.AGRUPADOS_INTERVALO:
            idx = next(i for i, item in enumerate(items) if item.f == max_f)
            item = items[idx]
            f_anterior = items[idx - 1].f if idx > 0 else 0
            f_siguiente = items[idx + 1].f if idx < len(items) - 1 else 0
            amplitud = item.upper - item.lower
            d1 = item.f - f_anterior
            d2 = item.f - f_siguiente
            if d1 + d2 == 0:
                return _fmt_num((item.lower + item.upper) / 2)
            moda = item.lower + (d1 / (d1 + d2)) * amplitud
            return _fmt_num(moda)

        modas = [item.xi for item in items if item.f == max_f]
        if len(modas) == len(items) and len(items) > 1:
            return "No definida"
        return ", ".join(_fmt_num(v) for v in modas)


class DispersionCalculator:
    """
    Calcula medidas de dispersión a partir de distintos tipos de datos:
    no agrupados, agrupados por valor o agrupados por intervalos.

    Internamente todos los tipos se tratan de forma uniforme: cada dato
    individual (no agrupado) es un DispersionItem con f=1, por lo que la
    fórmula fi · (Xi - x̄)² es válida en los tres casos.
    """

    def _merge_and_sort_valor(
        self, items: list[DispersionItem]
    ) -> list[DispersionItem]:
        """Unifica Xi repetidos sumando frecuencias y ordena ascendente."""
        merged: dict[float, int] = {}
        for item in items:
            merged[item.xi] = merged.get(item.xi, 0) + item.f
        return [DispersionItem(xi=xi, f=f) for xi, f in sorted(merged.items())]

    def _sort_no_agrupados(self, items: list[DispersionItem]) -> list[DispersionItem]:
        return sorted(items, key=lambda i: i.xi)

    def _sort_intervalos(self, items: list[DispersionItem]) -> list[DispersionItem]:
        return sorted(items, key=lambda i: i.lower if i.lower is not None else i.xi)

    def calculate(
        self,
        items: list[DispersionItem],
        data_type: DispersionType,
        poblacional: bool = True,
    ) -> DispersionResult:
        """
        Calcula todas las medidas de dispersión.

        Parámetros:
            items: lista de DispersionItem (xi, f y, para intervalos, lower/upper).
            data_type: tipo de datos de entrada.
            poblacional: True → varianza/desvío poblacional (÷n),
                         False → muestral (÷(n-1)).

        Todos los resultados (media, rango, (Xi - x̄), (Xi - x̄)², varianza,
        desvío, CV, etc.) se redondean al centésimo (2 decimales).

        Retorna un DispersionResult con todos los valores calculados.
        """
        if data_type == DispersionType.AGRUPADOS_VALOR:
            items = self._merge_and_sort_valor(items)
        elif data_type == DispersionType.AGRUPADOS_INTERVALO:
            items = self._sort_intervalos(items)
        else:
            items = self._sort_no_agrupados(items)

        n = sum(i.f for i in items)
        mean = descriptive_stats.mean(items)
        rango = descriptive_stats.rango(items, data_type)

        for item in items:
            item.diff = round(item.xi - mean, 2)
            item.diff_sq = round(item.diff**2, 2)
            item.f_diff_sq = round(item.f * item.diff_sq, 2)

        sum_f_diff_sq = round(sum(i.f_diff_sq or 0.0 for i in items), 2)

        varianza: float | None = None
        desvio: float | None = None
        cv: float | None = None
        cv_undefined = False
        stats_undefined = False

        if poblacional:
            varianza = sum_f_diff_sq / n if n > 0 else None
        else:
            if n <= 1:
                stats_undefined = True
                cv_undefined = True
            else:
                varianza = sum_f_diff_sq / (n - 1)

        if varianza is not None:
            varianza = round(varianza, 2)
            desvio = round(math.sqrt(varianza), 2)
            if mean == 0:
                cv_undefined = True
            else:
                cv = round((desvio / abs(mean)) * 100, 2)

        return DispersionResult(
            data_type=data_type,
            n=n,
            mean=mean,
            rango=rango,
            varianza=varianza,
            desvio=desvio,
            cv=cv,
            cv_undefined=cv_undefined,
            stats_undefined=stats_undefined,
            sum_f_diff_sq=sum_f_diff_sq,
            items=items,
        )
