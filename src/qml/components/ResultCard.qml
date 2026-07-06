pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Tarjeta de resultado compacta: label + valor destacado.
// Usada en las grillas de resultados de Frecuencias y Dispersión.
Rectangle {
    id: root

    property string label: ""
    property string value: "—"
    property bool undefined_value: false

    Layout.fillWidth: true
    implicitHeight: 56
    radius: 6
    color: Theme.panel_background
    border.color: Theme.divider
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2

        Text {
            text: root.label
            color: Theme.muted_text
            font.pixelSize: 10
            Layout.fillWidth: true
        }
        Text {
            text: root.value
            color: root.undefined_value ? Theme.error_text : Theme.accent
            font.bold: true
            font.pixelSize: 14
            Layout.fillWidth: true
        }
    }
}
