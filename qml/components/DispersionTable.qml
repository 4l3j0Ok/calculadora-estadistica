pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Tabla para el módulo de Dispersión. Se adapta según dataType:
//   "no_agrupados"        → Xi | Xi − x̄ | (Xi − x̄)²
//   "agrupados_valor"     → Xi | fi | Xi − x̄ | (Xi − x̄)² | fi · (Xi − x̄)²
//   "agrupados_intervalo" → Intervalo | Xi | fi | Xi − x̄ | (Xi − x̄)² | fi · (Xi − x̄)²
//
// model: lista de objetos con los campos correspondientes al dataType.
// sumValue: string formateado del total Σ[fi · (Xi − x̄)²] (o Σ(Xi − x̄)² en no agrupados).
// totalN: int, total de Σfi (o n).

Item {
    id: root

    property string dataType: "agrupados_valor"
    property var model: []
    property string sumValue: "—"
    property int totalN: 0

    function fmtNum(v: real): string {
        return (v % 1 === 0) ? v.toFixed(0) : parseFloat(v.toFixed(4)).toString();
    }

    function rowValues(modelData) {
        if (root.dataType === "no_agrupados") {
            return [
                root.fmtNum(modelData.xi),
                modelData.diff.toFixed(2),
                modelData.diffSq.toFixed(2)
            ];
        }
        if (root.dataType === "agrupados_intervalo") {
            return [
                modelData.lower.toFixed(2) + " – " + modelData.upper.toFixed(2),
                root.fmtNum(modelData.xi),
                modelData.f.toString(),
                modelData.diff.toFixed(2),
                modelData.diffSq.toFixed(2),
                modelData.fDiffSq.toFixed(2)
            ];
        }
        return [
            root.fmtNum(modelData.xi),
            modelData.f.toString(),
            modelData.diff.toFixed(2),
            modelData.diffSq.toFixed(2),
            modelData.fDiffSq.toFixed(2)
        ];
    }

    readonly property var headers: {
        if (root.dataType === "no_agrupados")
            return ["Xi", "Xi − x̄", "(Xi − x̄)²"];
        if (root.dataType === "agrupados_intervalo")
            return ["Intervalo", "Xi", "fi", "Xi − x̄", "(Xi − x̄)²", "fi · (Xi − x̄)²"];
        return ["Xi", "fi", "Xi − x̄", "(Xi − x̄)²", "fi · (Xi − x̄)²"];
    }

    readonly property var totalsRow: {
        if (root.dataType === "no_agrupados")
            return ["Totales", "", root.sumValue];
        if (root.dataType === "agrupados_intervalo")
            return ["Totales", "", root.totalN.toString(), "", "", root.sumValue];
        return ["Totales", root.totalN.toString(), "", "", root.sumValue];
    }

    readonly property var rowsData: {
        var out = [];
        for (var i = 0; i < root.model.length; i++)
            out.push(root.rowValues(root.model[i]));
        return out;
    }

    readonly property int minColWidth: 90
    readonly property int minTotalWidth: minColWidth * headers.length

    ScrollView {
        anchors.fill: parent
        contentWidth: Math.max(root.width, root.minTotalWidth)
        contentHeight: tableCol.implicitHeight
        clip: true

        ColumnLayout {
            id: tableCol
            width: Math.max(root.width, root.minTotalWidth)
            spacing: 0

            // ── Encabezado ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 1

                Repeater {
                    model: root.headers
                    delegate: HeaderCell {
                        required property string modelData
                        cellText: modelData
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 2
                color: Theme.table_divider
            }

            // ── Filas de datos ─────────────────────────────────────────────
            Repeater {
                model: root.rowsData

                delegate: RowLayout {
                    id: rowDelegate
                    Layout.fillWidth: true
                    spacing: 1

                    required property var modelData
                    required property int index

                    readonly property color rowBg: index % 2 === 0
                        ? Theme.table_row_base
                        : Theme.table_row_alt

                    Repeater {
                        model: rowDelegate.modelData
                        delegate: DataCell {
                            required property string modelData
                            cellText: modelData
                            bgColor: rowDelegate.rowBg
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 2
                color: Theme.table_divider
            }

            // ── Fila de totales ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 1

                Repeater {
                    model: root.totalsRow
                    delegate: TotalCell {
                        required property string modelData
                        cellText: modelData
                    }
                }
            }
        }
    }

    // ── Sub-componentes ───────────────────────────────────────────────────

    component HeaderCell: Rectangle {
        property string cellText

        Layout.fillWidth: true
        Layout.minimumWidth: root.minColWidth
        implicitHeight: 38
        color: Theme.table_header_bg

        Text {
            anchors.centerIn: parent
            text: parent.cellText
            color: Theme.table_header_text
            font.bold: true
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }

    component DataCell: Rectangle {
        property var cellText
        property color bgColor: Theme.table_row_base

        Layout.fillWidth: true
        Layout.minimumWidth: root.minColWidth
        implicitHeight: 34
        color: bgColor

        Text {
            anchors.centerIn: parent
            text: parent.cellText
            color: Theme.table_cell_text
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }

    component TotalCell: Rectangle {
        property var cellText

        Layout.fillWidth: true
        Layout.minimumWidth: root.minColWidth
        implicitHeight: 36
        color: Theme.table_totals_bg

        Text {
            anchors.centerIn: parent
            text: parent.cellText
            color: Theme.table_totals_text
            font.bold: true
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
