from PySide6.QtCore import Property, QObject, Signal, Slot

from src.schemas.history import HistoryEntry, HistoryModule
from src.services import history_service

_DATA_TYPE_LABELS = {
    "no_agrupados": "No agrupados",
    "agrupados_valor": "Agrupados por valor",
    "agrupados_intervalo": "Agrupados por intervalos",
}

_MODULE_LABELS = {
    "frecuencias": "Frecuencias",
    "dispersion": "Dispersión",
}


def _fmt_fecha(iso: str) -> str:
    # "2026-07-04T12:34:56.789012+00:00" -> "04/07/2026 12:34"
    try:
        fecha, hora = iso.split("T")
        anio, mes, dia = fecha.split("-")
        hh_mm = hora[:5]
        return f"{dia}/{mes}/{anio} {hh_mm}"
    except ValueError, IndexError:
        return iso


class HistoryController(QObject):
    """Controller para el historial de operaciones de ambos módulos.

    No calcula nada: solo lee/escribe entradas via services/history_service.py
    (sqlite3) y las expone a QML como una lista de dicts, siguiendo el mismo
    patrón que CalculadoraController/DispersionController.
    """

    historyChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        history_service.init_db()
        self._entries: list[dict] = []
        self._cargar()

    @Property(list, notify=historyChanged)
    def entries(self) -> list[dict]:
        return self._entries

    @Slot()
    def cargarHistorial(self) -> None:
        """Recarga el historial desde la base de datos."""
        self._cargar()

    @Slot(int)
    def eliminarEntrada(self, entry_id: int) -> None:
        history_service.delete_entry(entry_id)
        self._cargar()

    @Slot()
    def limpiarHistorial(self) -> None:
        history_service.clear_history()
        self._cargar()

    @Slot(str)
    def limpiarHistorialModulo(self, module: str) -> None:
        """Borra el historial de un solo módulo (ej: 'frecuencias' o 'dispersion')."""
        try:
            modulo = HistoryModule(module)
        except ValueError:
            return
        history_service.clear_by_module(modulo)
        self._cargar()

    def _cargar(self) -> None:
        self._entries = [
            self._to_view_dict(entry) for entry in history_service.list_entries()
        ]
        self.historyChanged.emit()

    @staticmethod
    def _to_view_dict(entry: HistoryEntry) -> dict:
        return {
            "id": entry.id,
            "module": entry.module.value,
            "moduleLabel": _MODULE_LABELS.get(entry.module.value, entry.module.value),
            "dataType": entry.data_type,
            "dataTypeLabel": _DATA_TYPE_LABELS.get(entry.data_type, entry.data_type),
            "poblacional": entry.poblacional,
            "inputPayload": entry.input_payload,
            "resultSummary": entry.result_summary,
            "createdAt": entry.created_at,
            "createdAtLabel": _fmt_fecha(entry.created_at),
        }
