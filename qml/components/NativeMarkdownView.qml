import QtQuick
import QtQuick.Controls
import QtQuick.Window

// Componente reutilizable para renderizar Markdown (con soporte de
// fórmulas LaTeX) de forma 100% nativa de Qt: sin QtWebEngine, sin
// Chromium, sin JavaScript ni recursos remotos.
//
// El Markdown se convierte a rich text con markdown-it-py y las fórmulas
// se rasterizan con matplotlib.mathtext (ver
// services/markdown_renderer.py, services/formula_renderer.py,
// controllers/MarkdownController.py::renderMarkdown*). El resultado se
// vuelca en el QTextDocument de un TextEdit nativo dentro de un
// ScrollView, conservando selección, copiado (Ctrl+C) y scroll nativo.
//
// Uso:
//   NativeMarkdownView {
//       anchors.fill: parent
//       markdownText: "# Hola\n\nLa media es \\(\\bar{x}\\)."
//   }
// o, para cargar desde archivo en disco:
//   NativeMarkdownView { markdownFile: "/ruta/a/formulas.md" }
// o, para cargar desde un recurso Qt embebido (resources.qrc):
//   NativeMarkdownView { markdownResource: "assets/docs/formulas.md" }
ScrollView {
    id: root

    // Texto Markdown a renderizar. Tiene prioridad sobre
    // markdownResource y markdownFile si varios están definidos.
    property string markdownText: ""
    // Ruta relativa a un recurso Qt embebido (`:/<markdownResource>`,
    // ver resources.qrc), con fallback a filesystem en dev/tests.
    // Tiene prioridad sobre markdownFile.
    property string markdownResource: ""
    // Ruta absoluta a un archivo .md a renderizar.
    property string markdownFile: ""
    // "dark" | "light". Por defecto se infiere del tema del sistema.
    property string theme: Theme.window_background.hslLightness > 0.5 ? "light" : "dark"
    property color textColor: Theme.primary_text

    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    function _refresh() {
        if (typeof markdownController === "undefined") {
            return;
        }
        var dpr = Screen.devicePixelRatio;
        var formulaColor = textColor.toString();
        if (markdownText.length > 0) {
            markdownController.renderMarkdownText(view.textDocument, markdownText, theme, dpr, formulaColor);
        } else if (markdownResource.length > 0) {
            markdownController.renderMarkdownResource(view.textDocument, markdownResource, theme, dpr, formulaColor);
        } else if (markdownFile.length > 0) {
            markdownController.renderMarkdownFile(view.textDocument, markdownFile, theme, dpr, formulaColor);
        }
    }

    onMarkdownTextChanged: _refresh()
    onMarkdownResourceChanged: _refresh()
    onMarkdownFileChanged: _refresh()
    onThemeChanged: _refresh()
    onTextColorChanged: _refresh()
    Component.onCompleted: _refresh()

    TextEdit {
        id: view
        width: root.availableWidth
        readOnly: true
        selectByMouse: true
        persistentSelection: true
        textFormat: TextEdit.RichText
        wrapMode: TextEdit.Wrap
        color: Theme.primary_text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accent_text
        leftPadding: 12
        rightPadding: 12
        topPadding: 12
        bottomPadding: 12

        // Enlaces internos del índice: navegan dentro del ScrollView.
        // Enlaces externos: se abren con el navegador del sistema. No
        // hay navegación embebida ni ejecución de recursos remotos.
        onLinkActivated: function (link) {
            if (link.charAt(0) === "#") {
                var y = markdownController.anchorY(view.textDocument, decodeURIComponent(link.substring(1)));
                if (y >= 0) {
                    root.contentItem.contentY = Math.max(0, Math.min(y, root.contentItem.contentHeight - root.contentItem.height));
                }
                return;
            }
            Qt.openUrlExternally(link);
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: view.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
        }
    }
}
