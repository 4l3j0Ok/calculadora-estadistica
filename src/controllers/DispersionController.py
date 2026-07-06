import json

from PySide6.QtCore import Property, QObject, Signal, Slot

from src.schemas.dispersion import DispersionItem, DispersionResult, DispersionType
from src.schemas.history import HistoryModule
from src.services import history_service, markdown_io
from src.services.calculator import DispersionCalculator, format_number
from src.services.parser import (
    DispersionParseError,
    parse_agrupados_intervalo,
    parse_agrupados_valor,
    parse_no_agrupados,
)


class DispersionController(QObject):
    """Controller para el módulo de dispersión estadística.

    Soporta tres tipos de datos de entrada: no agrupados, agrupados por
    valor y agrupados por intervalos. Toda la lógica de parsing/cálculo
    vive en services/parser.py y services/calculator.py; este controller
    solo orquesta y formatea la salida para QML.
    """

    tableModelChanged = Signal()
    resultChanged = Signal()
    errorChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._table_model: list[dict] = []
        self._result: dict = {}
        self._error: str = ""
        self._data_type: DispersionType | None = None
        self._poblacional: bool = True
        self._calculator = DispersionCalculator()

    # --- Propiedades expuestas a QML ---

    @Property(list, notify=tableModelChanged)
    def tableModel(self) -> list[dict]:
        return self._table_model

    @Property("QVariantMap", notify=resultChanged)
    def result(self) -> dict:
        return self._result

    @Property(str, notify=errorChanged)
    def error(self) -> str:
        return self._error

    # --- Slots públicos, uno por tipo de datos ---

    @Slot(str, bool)
    def calcularNoAgrupados(self, valores_str: str, poblacional: bool) -> None:
        """Recibe una lista de valores separados por coma (sin agrupar)."""
        try:
            items = parse_no_agrupados(valores_str)
        except DispersionParseError as exc:
            self._set_error(str(exc))
            return

        self._calcular(items, DispersionType.NO_AGRUPADOS, poblacional, valores_str)

    @Slot(str, bool)
    def calcularAgrupadosPorValor(self, filas_json: str, poblacional: bool) -> None:
        """Recibe JSON con filas [{xi, frecuencia}, ...]."""
        filas = self._decode_json(filas_json)
        if filas is None:
            return

        try:
            items = parse_agrupados_valor(filas)
        except DispersionParseError as exc:
            self._set_error(str(exc))
            return

        self._calcular(items, DispersionType.AGRUPADOS_VALOR, poblacional, filas_json)

    @Slot(str, bool)
    def calcularAgrupadosPorIntervalo(self, filas_json: str, poblacional: bool) -> None:
        """Recibe JSON con filas [{lower, upper, frecuencia}, ...]."""
        filas = self._decode_json(filas_json)
        if filas is None:
            return

        try:
            items = parse_agrupados_intervalo(filas)
        except DispersionParseError as exc:
            self._set_error(str(exc))
            return

        self._calcular(
            items, DispersionType.AGRUPADOS_INTERVALO, poblacional, filas_json
        )

    @Slot()
    def limpiar(self) -> None:
        self._table_model = []
        self._result = {}
        self._error = ""
        self._data_type = None
        self.tableModelChanged.emit()
        self.resultChanged.emit()
        self.errorChanged.emit()

    @Slot(result=str)
    def copiarResultadoMarkdown(self) -> str:
        """Renderiza la tabla de dispersión y las tarjetas de resumen
        actuales en Markdown, listas para copiar al portapapeles."""
        if not self._table_model or self._data_type is None:
            return ""

        intervalos = self._data_type == DispersionType.AGRUPADOS_INTERVALO
        rows = []
        for row in self._table_model:
            if intervalos:
                label = f"{format_number(row['lower'])} - {format_number(row['upper'])}"
            else:
                label = format_number(row["xi"])
            rows.append(
                {
                    "label": label,
                    "f": row["f"],
                    "diff": row["diff"],
                    "diffSq": row["diffSq"],
                    "fDiffSq": row["fDiffSq"],
                }
            )

        context = {
            "intervalos": intervalos,
            "poblacional": self._poblacional,
            "rows": rows,
            "n": self._result.get("n", ""),
            "mean": self._result.get("mean", ""),
            "rango": self._result.get("rango", ""),
            "varianza": self._result.get("varianza", ""),
            "desvio": self._result.get("desvio", ""),
            "cv": self._result.get("cv", ""),
        }
        return markdown_io.render_resultado_dispersion(context)

    # --- Helpers privados ---

    def _decode_json(self, filas_json: str) -> list[dict] | None:
        try:
            filas = json.loads(filas_json)
        except json.JSONDecodeError, ValueError:
            self._set_error("Error interno: formato de datos inválido.")
            return None
        return filas

    def _calcular(
        self,
        items: list[DispersionItem],
        data_type: DispersionType,
        poblacional: bool,
        input_payload: str,
    ) -> None:
        self._error = ""
        self._data_type = data_type
        self._poblacional = poblacional
        res = self._calculator.calculate(
            items, data_type=data_type, poblacional=poblacional
        )
        self._table_model = self._build_table_model(res)
        self._result = self._build_result(res)

        self.tableModelChanged.emit()
        self.resultChanged.emit()

        history_service.insert_entry(
            module=HistoryModule.DISPERSION,
            data_type=data_type.value,
            poblacional=poblacional,
            input_payload=input_payload,
            result_summary=json.dumps(self._result),
        )

    def _build_table_model(self, res: DispersionResult) -> list[dict]:
        rows: list[dict] = []
        for item in res.items:
            row = {
                "xi": item.xi,
                "f": item.f,
                "diff": item.diff or 0.0,
                "diffSq": item.diff_sq or 0.0,
                "fDiffSq": round(item.f_diff_sq or 0.0, 4),
            }
            if res.data_type == DispersionType.AGRUPADOS_INTERVALO:
                row["lower"] = item.lower
                row["upper"] = item.upper
            rows.append(row)
        return rows

    def _build_result(self, res: DispersionResult) -> dict:
        def fmt_optional(v: float | None) -> str:
            if v is None:
                return "—"
            return f"{v:.2f}"

        return {
            "dataType": res.data_type.value,
            "n": res.n,
            "mean": f"{res.mean:.2f}",
            "rango": f"{res.rango:.2f}",
            "varianza": fmt_optional(res.varianza),
            "desvio": fmt_optional(res.desvio),
            "cv": "No definido" if res.cv_undefined else fmt_optional(res.cv),
            "sumFDiffSq": f"{res.sum_f_diff_sq:.2f}",
            "statsUndefined": res.stats_undefined,
        }

    def _set_error(self, mensaje: str) -> None:
        self._error = mensaje
        self._table_model = []
        self._result = {}
        self._data_type = None
        self.tableModelChanged.emit()
        self.resultChanged.emit()
        self.errorChanged.emit()
