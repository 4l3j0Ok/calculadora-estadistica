from enum import Enum

from pydantic import BaseModel, Field


class DispersionType(str, Enum):
    """Tipo de datos de entrada para el módulo de Dispersión."""

    NO_AGRUPADOS = "no_agrupados"
    AGRUPADOS_VALOR = "agrupados_valor"
    AGRUPADOS_INTERVALO = "agrupados_intervalo"


class DispersionItem(BaseModel):
    xi: float = Field(..., description="Valor de x_i o marca de clase")
    f: int = Field(1, description="Frecuencia absoluta (1 para no agrupados)")
    lower: float | None = Field(None, description="Límite inferior del intervalo")
    upper: float | None = Field(None, description="Límite superior del intervalo")
    diff: float | None = Field(None, description="Xi - x̄")
    diff_sq: float | None = Field(None, description="(Xi - x̄)²")
    f_diff_sq: float | None = Field(None, description="fi · (Xi - x̄)²")


class DispersionResult(BaseModel):
    data_type: DispersionType = Field(..., description="Tipo de datos utilizado")
    n: int = Field(..., description="Total de datos (Σfi o n)")
    mean: float = Field(..., description="Media aritmética (x̄)")
    rango: float = Field(..., description="Rango")
    varianza: float | None = Field(None, description="Varianza (σ² o s²)")
    desvio: float | None = Field(None, description="Desvío estándar (σ o s)")
    cv: float | None = Field(None, description="Coeficiente de variación (%)")
    cv_undefined: bool = Field(
        False, description="True si CV no está definido (media=0 o n<=1 muestral)"
    )
    stats_undefined: bool = Field(
        False, description="True si varianza/desvío no están definidos (n<=1 muestral)"
    )
    sum_f_diff_sq: float = Field(0.0, description="Σ[fi · (Xi - x̄)²]")
    items: list[DispersionItem] = Field(default_factory=list)
