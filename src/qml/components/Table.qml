pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Tabla de frecuencias responsive. Se adapta según dataType:
//   "no_agrupados" / "agrupados_valor" → Xi | f | fr | F | f% | fa%
//   "agrupados_intervalo"              → Intervalo | Xi | f | fr | F | f% | fa%
//
// model: lista de objetos con:
//   xi, frecuencia, frecuenciaRelativa, frecuenciaAcumulada,
//   frecuenciaPorcentual, frecuenciaPorcentualAcumulada
//   (y para intervalos: intervalo, lower, upper)

Item {
    id: root

    property string dataType: "agrupados_valor"
    property var model: []

    readonly property bool showIntervalColumn: root.dataType === "agrupados_intervalo"

    readonly property int totalF: {
        var s = 0;
        for (var i = 0; i < model.length; i++) s += model[i].frecuencia;
        return s;
    }

    function fmtNum(v: real): string {
        return parseFloat(v.toFixed(2)).toString();
    }

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
        long: root.showIntervalColumn ? "Marca de clase" : "Valor de la variable",
        formula: root.showIntervalColumn ? "Xi = (Li + Ls) / 2" : "Valor observado de la variable"
    })
    readonly property var headerF: ({
        short: "f",
        long: "Frecuencia absoluta",
        formula: root.showIntervalColumn
            ? "Cantidad de datos que caen dentro del intervalo"
            : "Cantidad de veces que se repite el valor"
    })
    readonly property var headerFr: ({
        short: "fr",
        long: "Frecuencia relativa",
        formula: "fr = f / n"
    })
    readonly property var headerFA: ({
        short: "F",
        long: "Frecuencia acumulada",
        formula: "Fi = F(i-1) + fi   (F1 = f1)"
    })
    readonly property var headerFPercent: ({
        short: "f%",
        long: "Frecuencia porcentual",
        formula: "f% = fr × 100"
    })
    readonly property var headerFaPercent: ({
        short: "fa%",
        long: "Frecuencia porcentual acumulada",
        formula: "fa%i = fa%(i-1) + f%i   (fa%1 = f%1)"
    })

    readonly property var headerDefs: root.showIntervalColumn
        ? [headerIntervalo, headerXi, headerF, headerFr, headerFA, headerFPercent, headerFaPercent]
        : [headerXi, headerF, headerFr, headerFA, headerFPercent, headerFaPercent]

    readonly property var headers: {
        var out = [];
        for (var i = 0; i < headerDefs.length; i++)
            out.push(headerDefs[i].short);
        return out;
    }

    readonly property var totalsRow: root.showIntervalColumn
        ? ["Totales", "", root.totalF.toString(), "1", root.totalF.toString(), "100%", "100%"]
        : ["Totales", root.totalF.toString(), "1", root.totalF.toString(), "100%", "100%"]

    function rowValues(modelData) {
        var base = root.showIntervalColumn ? [modelData.intervalo, root.fmtNum(modelData.xi)] : [root.fmtNum(modelData.xi)];
        return base.concat([
            modelData.frecuencia.toString(),
            root.fmtNum(modelData.frecuenciaRelativa),
            modelData.frecuenciaAcumulada.toString(),
            root.fmtNum(modelData.frecuenciaPorcentual) + "%",
            root.fmtNum(modelData.frecuenciaPorcentualAcumulada) + "%"
        ]);
    }

    readonly property var rowsData: {
        var out = [];
        for (var i = 0; i < root.model.length; i++)
            out.push(root.rowValues(root.model[i]));
        return out;
    }

    readonly property int minColWidth: 70
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

            // ── Encabezado ────────────────────────────────────────────────
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

            // ── Filas de datos ────────────────────────────────────────────
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

            // ── Fila de totales ───────────────────────────────────────────
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

    // ── Componentes internos ──────────────────────────────────────────────

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
            font.pixelSize: headerCell.expanded ? 10 : 13
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
