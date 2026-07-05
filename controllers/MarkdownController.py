import json

from PySide6.QtCore import QObject, Slot
from PySide6.QtWidgets import QApplication

from services import markdown_io


class MarkdownController(QObject):
    """Controller genérico para copiar/pegar datos de entrada (no las
    tablas ya calculadas) en formato Markdown, compartido entre los
    módulos de Frecuencias y Dispersión.

    También expone acceso al portapapeles del sistema: se probó usar
    `Qt.labs.platform.Clipboard` desde QML, pero ese tipo no llega a
    registrarse quando el backend de plataforma de Qt no expone soporte
    de portapapeles (p. ej. `offscreen`, algunos compositores Wayland
    minimalistas); `QApplication.clipboard()` es la vía soportada de
    forma más amplia, por eso el copiar/pegar se resuelve acá en vez de
    en QML.
    """

    @Slot(str)
    def setClipboardText(self, texto: str) -> None:
        QApplication.clipboard().setText(texto)

    @Slot(result=str)
    def clipboardText(self) -> str:
        return QApplication.clipboard().text()

    @Slot(str, str, result=str)
    def renderNoAgrupados(self, module: str, valores: str) -> str:
        """module: 'frecuencias' | 'dispersion'."""
        return markdown_io.render_no_agrupados(module, valores)

    @Slot(str, str, result=str)
    def renderAgrupadosValor(self, module: str, filas_json: str) -> str:
        """filas_json: JSON con [{xi, frecuencia}, ...]."""
        filas = json.loads(filas_json)
        return markdown_io.render_agrupados_valor(module, filas)

    @Slot(str, str, result=str)
    def renderAgrupadosIntervalo(self, module: str, filas_json: str) -> str:
        """filas_json: JSON con [{lower, upper, frecuencia}, ...]."""
        filas = json.loads(filas_json)
        return markdown_io.render_agrupados_intervalo(module, filas)

    @Slot(str, result=str)
    def parseMarkdown(self, texto: str) -> str:
        """
        Parsea un texto Markdown pegado por el usuario.

        Retorna un JSON con la forma:
        - éxito: {"ok": true, "module", "dataType", "text", "rows"}
        - error: {"ok": false, "error": "<mensaje>"}
        """
        try:
            parsed = markdown_io.parse_input_markdown(texto)
        except markdown_io.MarkdownIOError as exc:
            return json.dumps({"ok": False, "error": str(exc)})
        except Exception as exc:  # noqa: BLE001 - se muestra al usuario, no debe explotar la UI
            return json.dumps({"ok": False, "error": f"Error inesperado: {exc}"})

        return json.dumps(
            {
                "ok": True,
                "module": parsed.module,
                "dataType": parsed.data_type,
                "text": parsed.text,
                "rows": parsed.rows,
            }
        )
