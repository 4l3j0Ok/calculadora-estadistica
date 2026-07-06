from enum import Enum

from pydantic import BaseModel, Field


class TableType(str, Enum):
    """Tipo de datos de entrada para el módulo de Frecuencias."""

    NO_AGRUPADOS = "no_agrupados"
    AGRUPADOS_VALOR = "agrupados_valor"
    AGRUPADOS_INTERVALO = "agrupados_intervalo"


class TableItem(BaseModel):
    xi: float = Field(..., description="Valor de x_i o marca de clase")
    f: int = Field(..., description="Frecuencia absoluta")
    lower: float | None = Field(None, description="Límite inferior del intervalo")
    upper: float | None = Field(None, description="Límite superior del intervalo")
    fr: float | None = Field(None, description="Frecuencia relativa")
    fa: int | None = Field(None, description="Frecuencia acumulada")
    f_percent: float | None = Field(None, description="Frecuencia porcentual")
    fa_percent: float | None = Field(
        None, description="Frecuencia porcentual acumulada"
    )


class Table(BaseModel):
    data_type: TableType = Field(
        TableType.AGRUPADOS_VALOR, description="Tipo de datos de entrada de la tabla"
    )
    items: list[TableItem] = Field(..., description="Lista de elementos de la tabla")
