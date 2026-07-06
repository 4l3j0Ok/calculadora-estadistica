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

    readonly property bool isIntervalo: root.dataType === "agrupados_intervalo"
    readonly property bool isNoAgrupados: root.dataType === "no_agrupados"

    // ── Definición de encabezados ────────────────────────────────────────
    // Cada uno tiene: abreviatura (short), qué representa (long) y la
    // fórmula para calcularlo a mano en hoja (formula). Al hacer click en
    // un header, se alterna entre "short" y "long"; el tooltip siempre
    // muestra "long" + "formula".
    readonly property var headerIntervalo: ({
        short: "Intervalo",
        long: "Intervalo de clase",
        formula: "[Límite inferior, Límite superior)"
    })
    readonly property var headerXi: ({
        short: "Xi",
        long: root.isIntervalo ? "Marca de clase" : "Valor de la variable",
        formula: root.isIntervalo ? "Xi = (Li + Ls) / 2" : "Valor observado de la variable"
    })
    readonly property var headerFi: ({
        short: "fi",
        long: "Frecuencia absoluta",
        formula: root.isIntervalo
            ? "Cantidad de datos que caen dentro del intervalo"
            : "Cantidad de veces que se repite el valor"
    })
    readonly property var headerDiff: ({
        short: "Xi − x̄",
        long: "Desviación respecto a la media",
        formula: "Xi − x̄"
    })
    readonly property var headerDiffSq: ({
        short: "(Xi − x̄)²",
        long: "Desviación al cuadrado",
        formula: "(Xi − x̄)²"
    })
    readonly property var headerFDiffSq: ({
        short: "fi · (Xi − x̄)²",
        long: "Desviación cuadrática ponderada",
        formula: "fi × (Xi − x̄)²"
    })

    readonly property var headerDefs: {
        if (root.isNoAgrupados)
            return [headerXi, headerDiff, headerDiffSq];
        if (root.isIntervalo)
            return [headerIntervalo, headerXi, headerFi, headerDiff, headerDiffSq, headerFDiffSq];
        return [headerXi, headerFi, headerDiff, headerDiffSq, headerFDiffSq];
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
    readonly property int minTotalWidth: minColWidth * headerDefs.length

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
                    model: root.headerDefs
                    delegate: HeaderCell {
                        required property var modelData
                        headerDef: modelData
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

    // Header clickeable: alterna entre abreviatura y descripción, y
    // muestra en tooltip (hover) la descripción completa + la fórmula
    // para calcularlo a mano.
    component HeaderCell: Rectangle {
        id: headerCell

        property var headerDef: ({ short: "", long: "", formula: "" })
        property bool expanded: false

        Layout.fillWidth: true
        Layout.minimumWidth: root.minColWidth
        implicitHeight: 44
        color: headerHover.hovered ? Qt.darker(Theme.table_header_bg, 1.1) : Theme.table_header_bg

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        HoverHandler {
            id: headerHover
        }
        TapHandler {
            onTapped: headerCell.expanded = !headerCell.expanded
        }

        Text {
            anchors.fill: parent
            anchors.margins: 4
            text: headerCell.expanded ? headerCell.headerDef.long : headerCell.headerDef.short
            color: Theme.table_header_text
            font.bold: true
            font.pixelSize: headerCell.expanded ? 10 : 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 2
        }

        ToolTip.visible: headerHover.hovered
        ToolTip.delay: 350
        ToolTip.text: headerCell.headerDef.long + "\n" + headerCell.headerDef.formula
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
