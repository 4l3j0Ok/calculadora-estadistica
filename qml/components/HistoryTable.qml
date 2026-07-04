pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Tabla de historial de operaciones de un módulo puntual.
//
// model: lista de objetos con:
//   id, module, moduleLabel, dataType, dataTypeLabel, poblacional,
//   inputPayload, resultSummary, createdAt, createdAtLabel
//
// Emite `deleteRequested(id)` al borrar una fila y `loadRequested(entry)`
// cuando el usuario pide recargar esa entrada en el formulario actual.

Item {
    id: root

    property var model: []

    signal deleteRequested(int entryId)
    signal loadRequested(var entry)

    readonly property var headers: ["Fecha", "Tipo", "Resumen", "Cargar", "Borrar"]
    readonly property var headerWidths: [130, 160, -1, 60, 40]

    function resumen(entry) {
        var data;
        try {
            data = JSON.parse(entry.resultSummary);
        } catch (e) {
            return "";
        }

        if (entry.module === "dispersion") {
            var pobl = entry.poblacional ? "poblacional" : "muestral";
            return "n=" + data.n + "  x̄=" + data.mean + "  s=" + data.desvio + " (" + pobl + ")";
        }

        // Frecuencias: data es una lista de filas
        if (Array.isArray(data))
            return data.length + " fila(s), Σf=" + data.reduce(function (acc, r) { return acc + r.frecuencia; }, 0);

        return "";
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: root.width
            spacing: 0

            // ── Encabezado ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 1

                Repeater {
                    model: root.headers
                    delegate: HeaderCell {
                        required property string modelData
                        required property int index
                        cellText: modelData
                        Layout.preferredWidth: root.headerWidths[index]
                        Layout.fillWidth: root.headerWidths[index] === -1
                        Layout.minimumWidth: root.headerWidths[index] === -1 ? 220 : -1
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 2
                color: Theme.table_divider
            }

            // ── Filas ─────────────────────────────────────────────────────
            Repeater {
                model: root.model

                delegate: RowLayout {
                    id: rowDelegate
                    Layout.fillWidth: true
                    spacing: 1

                    required property var modelData
                    required property int index

                    readonly property color rowBg: index % 2 === 0
                        ? Theme.table_row_base
                        : Theme.table_row_alt

                    DataCell {
                        Layout.preferredWidth: 130
                        cellText: rowDelegate.modelData.createdAtLabel
                        bgColor: rowDelegate.rowBg
                    }
                    DataCell {
                        Layout.preferredWidth: 160
                        cellText: rowDelegate.modelData.dataTypeLabel
                        bgColor: rowDelegate.rowBg
                    }
                    DataCell {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 220
                        cellText: root.resumen(rowDelegate.modelData)
                        bgColor: rowDelegate.rowBg
                        horizontalAlignment: Text.AlignLeft
                    }

                    Rectangle {
                        Layout.preferredWidth: 60
                        implicitHeight: 34
                        color: rowDelegate.rowBg

                        Rectangle {
                            anchors.centerIn: parent
                            width: 46
                            height: 24
                            radius: 4
                            color: loadHover.containsMouse ? Theme.accent_hover : Theme.accent_subtle
                            border.color: Theme.accent
                            border.width: 1

                            HoverHandler {
                                id: loadHover
                            }
                            TapHandler {
                                onTapped: root.loadRequested(rowDelegate.modelData)
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "Cargar"
                                color: Theme.accent
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        implicitHeight: 34
                        color: rowDelegate.rowBg

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 24
                            radius: 4
                            color: deleteHover.containsMouse ? Theme.destructive_hover : Theme.destructive_bg
                            border.color: Theme.destructive_border
                            border.width: 1

                            HoverHandler {
                                id: deleteHover
                            }
                            TapHandler {
                                onTapped: root.deleteRequested(rowDelegate.modelData.id)
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: Theme.error_text
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 24
                visible: root.model.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "No hay operaciones registradas todavía."
                    color: Theme.muted_text
                    font.pixelSize: 13
                }
            }
        }
    }

    // ── Componentes internos ──────────────────────────────────────────────

    component HeaderCell: Rectangle {
        property string cellText

        implicitHeight: 38
        color: Theme.table_header_bg

        Text {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            verticalAlignment: Text.AlignVCenter
            text: parent.cellText
            color: Theme.table_header_text
            font.bold: true
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    component DataCell: Rectangle {
        property string cellText
        property color bgColor: Theme.table_row_base
        property int horizontalAlignment: Text.AlignHCenter

        implicitHeight: 34
        color: bgColor

        Text {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: parent.horizontalAlignment
            text: parent.cellText
            color: Theme.table_cell_text
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }
}
