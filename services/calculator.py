import math

from schemas.dispersion import DispersionItem, DispersionResult, DispersionType
from schemas.table import Table, TableItem, TableType

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
            return sorted(
                items, key=lambda i: i.lower if i.lower is not None else i.xi
            )

        merged: dict[float, int] = {}
        for item in items:
            merged[item.xi] = merged.get(item.xi, 0) + item.f

        return [
            TableItem(xi=xi, f=f)
            for xi, f in sorted(merged.items())
        ]

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


class DispersionCalculator:
    """
    Calcula medidas de dispersión a partir de distintos tipos de datos:
    no agrupados, agrupados por valor o agrupados por intervalos.

    Internamente todos los tipos se tratan de forma uniforme: cada dato
    individual (no agrupado) es un DispersionItem con f=1, por lo que la
    fórmula fi · (Xi - x̄)² es válida en los tres casos.
    """

    def _merge_and_sort_valor(self, items: list[DispersionItem]) -> list[DispersionItem]:
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
        mean = round(sum(i.xi * i.f for i in items) / n, 2) if n > 0 else 0.0

        if data_type == DispersionType.AGRUPADOS_INTERVALO:
            rango = max(i.upper for i in items if i.upper is not None) - min(
                i.lower for i in items if i.lower is not None
            )
        else:
            rango = max(i.xi for i in items) - min(i.xi for i in items)
        rango = round(rango, 2)

        for item in items:
            item.diff = round(item.xi - mean, 2)
            item.diff_sq = round(item.diff ** 2, 2)
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
