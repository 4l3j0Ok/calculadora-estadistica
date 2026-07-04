import json

from PySide6.QtCore import Property, QObject, Signal, Slot

from schemas.history import HistoryModule
from schemas.table import Table, TableItem, TableType
from services import history_service
from services.calculator import TableCalculator
from services.parser import (
    TableParseError,
    parse_table_agrupados_intervalo,
    parse_table_agrupados_valor,
    parse_table_no_agrupados,
)


def _fmt_bound(v: float) -> str:
    """Formatea un límite de intervalo sin decimales innecesarios."""
    return f"{v:.0f}" if v == int(v) else f"{v:g}"


class CalculadoraController(QObject):
    """Controller para la tabla de frecuencias.

    Soporta tres tipos de datos de entrada: no agrupados, agrupados por
    valor y agrupados por intervalos. Toda la lógica de parsing/cálculo
    vive en services/parser.py y services/calculator.py; este controller
    solo orquesta y formatea la salida para QML.
    """

    tableModelChanged = Signal()
    errorChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._table_model: list[dict] = []
        self._error: str = ""
        self._calculator = TableCalculator()

    # --- Propiedades expuestas a QML ---

    @Property(list, notify=tableModelChanged)
    def tableModel(self) -> list[dict]:
        """Retorna los datos de la tabla calculada para QML."""
        return self._table_model

    @Property(str, notify=errorChanged)
    def error(self) -> str:
        """Mensaje de error si hubo algún problema en el cálculo."""
        return self._error

    # --- Slots públicos, uno por tipo de datos ---

    @Slot(str)
    def calcularNoAgrupados(self, valores_str: str) -> None:
        """Recibe una lista de valores separados por coma (sin agrupar)."""
        try:
            items = parse_table_no_agrupados(valores_str)
        except TableParseError as exc:
            self._set_error(str(exc))
            return

        self._calcular(items, TableType.NO_AGRUPADOS, valores_str)

    @Slot(str)
    def calcularAgrupadosPorValor(self, filas_json: str) -> None:
        """Recibe JSON con filas [{xi, frecuencia}, ...]."""
        filas = self._decode_json(filas_json)
        if filas is None:
            return

        try:
            items = parse_table_agrupados_valor(filas)
        except TableParseError as exc:
            self._set_error(str(exc))
            return

        self._calcular(items, TableType.AGRUPADOS_VALOR, filas_json)

    @Slot(str)
    def calcularAgrupadosPorIntervalo(self, filas_json: str) -> None:
        """Recibe JSON con filas [{lower, upper, frecuencia}, ...]."""
        filas = self._decode_json(filas_json)
        if filas is None:
            return

        try:
            items = parse_table_agrupados_intervalo(filas)
        except TableParseError as exc:
            self._set_error(str(exc))
            return

        self._calcular(items, TableType.AGRUPADOS_INTERVALO, filas_json)

    @Slot(str)
    def calcularDesdeFilas(self, filas_json: str) -> None:
        """
        Compatibilidad retroactiva: equivalente a calcularAgrupadosPorValor.
        """
        self.calcularAgrupadosPorValor(filas_json)

    @Slot()
    def limpiar(self) -> None:
        """Limpia la tabla y el mensaje de error."""
        self._table_model = []
        self._error = ""
        self.tableModelChanged.emit()
        self.errorChanged.emit()

    # --- Helpers privados ---

    def _decode_json(self, filas_json: str) -> list[dict] | None:
        try:
            filas = json.loads(filas_json)
        except (json.JSONDecodeError, ValueError):
            self._set_error("Error interno: formato de datos inválido.")
            return None
        return filas

    def _calcular(
        self, items: list[TableItem], data_type: TableType, input_payload: str
    ) -> None:
        self._error = ""
        table = Table(data_type=data_type, items=items)
        self._calculator.calculate(table)
        self._table_model = self._build_table_model(table)
        self.tableModelChanged.emit()

        history_service.insert_entry(
            module=HistoryModule.FRECUENCIAS,
            data_type=data_type.value,
            input_payload=input_payload,
            result_summary=json.dumps(self._table_model),
        )

    def _build_table_model(self, table: Table) -> list[dict]:
        rows: list[dict] = []
        for item in table.items:
            row = {
                "xi": item.xi,
                "frecuencia": item.f,
                "frecuenciaRelativa": item.fr or 0,
                "frecuenciaAcumulada": item.fa,
                "frecuenciaPorcentual": item.f_percent or 0,
                "frecuenciaPorcentualAcumulada": round(item.fa_percent or 0, 2),
            }
            if table.data_type == TableType.AGRUPADOS_INTERVALO:
                row["lower"] = item.lower
                row["upper"] = item.upper
                row["intervalo"] = f"{_fmt_bound(item.lower)} - {_fmt_bound(item.upper)}"
            rows.append(row)
        return rows

    def _set_error(self, mensaje: str) -> None:
        self._error = mensaje
        self._table_model = []
        self.tableModelChanged.emit()
        self.errorChanged.emit()
