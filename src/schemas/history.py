from enum import Enum

from pydantic import BaseModel


class HistoryModule(str, Enum):
    """Módulo de la aplicación que generó la entrada de historial."""

    FRECUENCIAS = "frecuencias"
    DISPERSION = "dispersion"


class HistoryEntry(BaseModel):
    """Una entrada de historial: registra qué se calculó y con qué resultado.

    `input_payload` y `result_summary` se guardan como texto JSON en SQLite
    (no como sub-objetos anidados), por eso acá son `str`: el servicio de
    persistencia es responsable de serializar/deserializar.
    """

    id: int | None = None
    module: HistoryModule
    data_type: str
    poblacional: bool | None = None
    input_payload: str
    result_summary: str
    created_at: str
