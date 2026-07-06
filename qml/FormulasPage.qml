import QtQuick
import QtQuick.Layouts
import "components"

// Página: Fórmulas
// Renderiza assets/docs/formulas.md (fórmulas prácticas de Estadística,
// con notación LaTeX) usando el componente reutilizable
// NativeMarkdownView (markdown-it-py + matplotlib.mathtext, 100% nativo
// de Qt, ver src/services/markdown_renderer.py).
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "Fórmulas"
            color: Theme.primary_text
            font.bold: true
            font.pixelSize: 20
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.divider
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.input_background
            border.color: Theme.border_color
            border.width: 1
            radius: 6
            clip: true

            NativeMarkdownView {
                anchors.fill: parent
                anchors.margins: 1
                markdownResource: "assets/docs/formulas.md"
            }
        }
    }
}
