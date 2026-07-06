import json

from PySide6.QtCore import QObject, Slot
from PySide6.QtQuick import QQuickTextDocument
from PySide6.QtWidgets import QApplication
from shiboken6 import getCppPointer

from src.services import markdown_io
from src.services.markdown_renderer import MarkdownRenderer


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

    También expone `renderMarkdown*`, usados por el componente QML
    reutilizable `NativeMarkdownView.qml` para volcar Markdown (con
    fórmulas LaTeX opcionales) directamente en el `QTextDocument` de un
    `TextEdit` nativo, sin QtWebEngine.
    """

    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self._renderer = MarkdownRenderer()
        self._document_anchors: dict[int, dict[str, str]] = {}

    def _document_key(self, quick_document: QQuickTextDocument) -> int:
        return getCppPointer(quick_document.textDocument())[0]

    @Slot(QQuickTextDocument, str, str, float, str)
    def renderMarkdownText(
        self,
        quick_document: QQuickTextDocument,
        markdown_text: str,
        theme: str = "dark",
        device_pixel_ratio: float = 1.0,
        text_color: str = "",
    ) -> None:
        """Vuelca Markdown (+ LaTeX) dentro del `QTextDocument` del
        `TextEdit`, con estilos para `theme` ('dark' | 'light') y las
        fórmulas rasterizadas nativamente (matplotlib mathtext)."""
        document = quick_document.textDocument()
        rendered = self._renderer.render_into(
            document, markdown_text, theme, device_pixel_ratio, text_color
        )
        self._document_anchors[self._document_key(quick_document)] = rendered.anchors

    @Slot(QQuickTextDocument, str, str, float, str)
    def renderMarkdownFile(
        self,
        quick_document: QQuickTextDocument,
        path: str,
        theme: str = "dark",
        device_pixel_ratio: float = 1.0,
        text_color: str = "",
    ) -> None:
        """Igual que `renderMarkdownText` pero leyendo el Markdown desde
        un archivo en disco."""
        document = quick_document.textDocument()
        rendered = self._renderer.render_file_into(
            document, path, theme, device_pixel_ratio, text_color
        )
        self._document_anchors[self._document_key(quick_document)] = rendered.anchors

    @Slot(QQuickTextDocument, str, str, float, str)
    def renderMarkdownResource(
        self,
        quick_document: QQuickTextDocument,
        relative_path: str,
        theme: str = "dark",
        device_pixel_ratio: float = 1.0,
        text_color: str = "",
    ) -> None:
        """Igual que `renderMarkdownText` pero leyendo el Markdown desde
        un recurso Qt embebido (`:/<relative_path>`, ver `resources.qrc`),
        con fallback a filesystem para dev/tests. Usado por el módulo
        Fórmulas para renderizar `assets/docs/formulas.md`."""
        document = quick_document.textDocument()
        rendered = self._renderer.render_resource_into(
            document, relative_path, theme, device_pixel_ratio, text_color
        )
        self._document_anchors[self._document_key(quick_document)] = rendered.anchors

    @Slot(QQuickTextDocument, str, result=float)
    def anchorY(self, quick_document: QQuickTextDocument, anchor: str) -> float:
        """Devuelve la posición vertical del heading asociado a `anchor`
        dentro del `QTextDocument`, para navegación interna del índice.

        Los anchors se generan desde los títulos Markdown. Si no se
        encuentra el destino, devuelve -1 para que QML no haga scroll.
        """
        document = quick_document.textDocument()
        title = self._document_anchors.get(self._document_key(quick_document), {}).get(
            anchor.lstrip("#")
        )
        if not title:
            return -1.0
        cursor = document.find(title)
        if cursor.isNull():
            return -1.0
        return document.documentLayout().blockBoundingRect(cursor.block()).top()

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
