pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

// Página: Tabla de Frecuencias
// Soporta tres tipos de datos: no agrupados, agrupados por valor y
// agrupados por intervalos. Toda la lógica de parsing/cálculo vive en
// Python (src/services/parser.py + src/services/calculator.py); este QML solo
// arma la entrada, la envía al controller y muestra el resultado.
Item {
    id: root

    property string dataType: "agrupados_valor"
    property string pasteError: ""
    readonly property bool controllerReady: !!calculadoraController
    readonly property var result: root.controllerReady ? calculadoraController.result : ({})
    readonly property var tableModel: root.controllerReady ? calculadoraController.tableModel : []
    readonly property string controllerError: root.controllerReady ? calculadoraController.error : ""

    signal toastRequested(string message, bool error)

    onControllerErrorChanged: {
        if (root.controllerError !== "")
            root.toastRequested(root.controllerError, true);
    }

    readonly property var tiposDeDatos: [
        {
            value: "no_agrupados",
            label: "No agrupados"
        },
        {
            value: "agrupados_valor",
            label: "Agrupados por valor"
        },
        {
            value: "agrupados_intervalo",
            label: "Agrupados por intervalos"
        }
    ]

    // ── Modelos de entrada, uno por tipo (nunca se mezclan) ────────────────
    property string valoresText: ""
    property bool focusNextValorRow: false
    property bool focusNextIntervaloRow: false

    ListModel {
        id: valorModel
        ListElement {
            xi: ""
            frecuencia: ""
        }
    }

    ListModel {
        id: intervaloModel
        ListElement {
            lower: ""
            upper: ""
            frecuencia: ""
        }
    }

    function setDataType(nuevoTipo) {
        if (root.dataType === nuevoTipo)
            return;
        root.dataType = nuevoTipo;
        root.limpiar();
    }

    function calcular() {
        if (root.dataType === "no_agrupados") {
            calculadoraController.calcularNoAgrupados(root.valoresText);
            return;
        }

        if (root.dataType === "agrupados_valor") {
            var filasValor = [];
            for (var i = 0; i < valorModel.count; i++) {
                filasValor.push({
                    xi: valorModel.get(i).xi,
                    frecuencia: valorModel.get(i).frecuencia
                });
            }
            calculadoraController.calcularAgrupadosPorValor(JSON.stringify(filasValor));
            return;
        }

        var filasIntervalo = [];
        for (var j = 0; j < intervaloModel.count; j++) {
            filasIntervalo.push({
                lower: intervaloModel.get(j).lower,
                upper: intervaloModel.get(j).upper,
                frecuencia: intervaloModel.get(j).frecuencia
            });
        }
        calculadoraController.calcularAgrupadosPorIntervalo(JSON.stringify(filasIntervalo));
    }

    function limpiar() {
        calculadoraController.limpiar();
        root.valoresText = "";
        root.pasteError = "";
        valorModel.clear();
        valorModel.append({
            xi: "",
            frecuencia: ""
        });
        intervaloModel.clear();
        intervaloModel.append({
            lower: "",
            upper: "",
            frecuencia: ""
        });
        root.toastRequested("Formulario limpiado", false);
    }

    // ── Copiar / Pegar datos en Markdown ────────────────────────────────
    function hayDatosParaCopiar() {
        if (root.dataType === "no_agrupados")
            return root.valoresText.trim() !== "";

        if (root.dataType === "agrupados_valor") {
            for (var i = 0; i < valorModel.count; i++)
                if (valorModel.get(i).xi.trim() !== "" || valorModel.get(i).frecuencia.trim() !== "")
                    return true;
            return false;
        }

        for (var j = 0; j < intervaloModel.count; j++)
            if (intervaloModel.get(j).lower.trim() !== "" || intervaloModel.get(j).upper.trim() !== "" || intervaloModel.get(j).frecuencia.trim() !== "")
                return true;
        return false;
    }

    function copiarDatos() {
        if (!root.hayDatosParaCopiar()) {
            root.toastRequested("No hay valores a copiar", true);
            return;
        }

        var md;
        if (root.dataType === "no_agrupados") {
            md = markdownController.renderNoAgrupados("frecuencias", root.valoresText);
        } else if (root.dataType === "agrupados_valor") {
            var filasValor = [];
            for (var i = 0; i < valorModel.count; i++)
                filasValor.push({
                    xi: valorModel.get(i).xi,
                    frecuencia: valorModel.get(i).frecuencia
                });
            md = markdownController.renderAgrupadosValor("frecuencias", JSON.stringify(filasValor));
        } else {
            var filasIntervalo = [];
            for (var j = 0; j < intervaloModel.count; j++)
                filasIntervalo.push({
                    lower: intervaloModel.get(j).lower,
                    upper: intervaloModel.get(j).upper,
                    frecuencia: intervaloModel.get(j).frecuencia
                });
            md = markdownController.renderAgrupadosIntervalo("frecuencias", JSON.stringify(filasIntervalo));
        }
        markdownController.setClipboardText(md);
        root.toastRequested("Datos copiados al portapapeles", false);
    }

    function cargarDesdeMarkdown(nuevoTipo, payload) {
        root.pasteError = "";
        root.dataType = nuevoTipo;

        if (nuevoTipo === "no_agrupados") {
            root.valoresText = payload.text;
        } else if (nuevoTipo === "agrupados_valor") {
            valorModel.clear();
            for (var i = 0; i < payload.rows.length; i++)
                valorModel.append({
                    xi: payload.rows[i].xi.toString(),
                    frecuencia: payload.rows[i].frecuencia.toString()
                });
        } else {
            intervaloModel.clear();
            for (var j = 0; j < payload.rows.length; j++)
                intervaloModel.append({
                    lower: payload.rows[j].lower.toString(),
                    upper: payload.rows[j].upper.toString(),
                    frecuencia: payload.rows[j].frecuencia.toString()
                });
        }
        root.calcular();
    }

    function pegarDatos() {
        // El pegado es cross-módulo: el tipo de dato (no agrupados /
        // agrupados por valor / agrupados por intervalos) es el mismo
        // formato en ambos módulos, así que los datos se cargan siempre
        // en la página donde el usuario está parado, sin importar desde
        // qué módulo se hayan copiado originalmente.
        var clipboardText = markdownController.clipboardText();
        if (clipboardText.trim() === "") {
            root.pasteError = "No había nada que pegar";
            root.toastRequested(root.pasteError, true);
            return;
        }

        var respuesta = JSON.parse(markdownController.parseMarkdown(clipboardText));
        if (!respuesta.ok) {
            root.pasteError = respuesta.error;
            root.toastRequested(respuesta.error, true);
            return;
        }
        root.pasteError = "";
        root.cargarDesdeMarkdown(respuesta.dataType, {
            text: respuesta.text,
            rows: respuesta.rows
        });
        root.toastRequested("Datos pegados y calculados", false);
    }

    function copiarTabla() {
        var md = calculadoraController.copiarResultadoMarkdown();
        if (md) {
            markdownController.setClipboardText(md);
            root.toastRequested("Tabla copiada al portapapeles", false);
        }
    }

    // ── Historial ───────────────────────────────────────────────────────
    readonly property var historyEntries: {
        if (!historyController)
            return [];

        var todas = historyController.entries;
        var propias = [];
        for (var i = 0; i < todas.length; i++)
            if (todas[i].module === "frecuencias")
                propias.push(todas[i]);
        return propias;
    }

    function cargarDesdeHistorial(entry) {
        var filas;
        root.dataType = entry.dataType;

        if (entry.dataType === "no_agrupados") {
            root.valoresText = entry.inputPayload;
        } else if (entry.dataType === "agrupados_valor") {
            filas = JSON.parse(entry.inputPayload);
            valorModel.clear();
            for (var i = 0; i < filas.length; i++)
                valorModel.append({
                    xi: filas[i].xi.toString(),
                    frecuencia: filas[i].frecuencia.toString()
                });
        } else if (entry.dataType === "agrupados_intervalo") {
            filas = JSON.parse(entry.inputPayload);
            intervaloModel.clear();
            for (var j = 0; j < filas.length; j++)
                intervaloModel.append({
                    lower: filas[j].lower.toString(),
                    upper: filas[j].upper.toString(),
                    frecuencia: filas[j].frecuencia.toString()
                });
        }

        historyPopup.close();
        root.calcular();
        root.toastRequested("Entrada cargada desde el historial", false);
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Panel izquierdo: carga de datos ───────────────────────────────
        Rectangle {
            Layout.fillHeight: true
            Layout.minimumWidth: 280
            Layout.preferredWidth: Math.max(280, parent.width * 0.34)
            Layout.maximumWidth: 420
            color: Theme.panel_background

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Rectangle {
                    Label {
                        text: "Frecuencias"
                        color: Theme.primary_text
                        font.bold: true
                        font.pixelSize: 15
                    }
                    Layout.bottomMargin: 15
                }

                RowLayout {
                    Layout.fillWidth: true

                    Button {
                        text: "Copiar"
                        implicitHeight: 28
                        onClicked: root.copiarDatos()

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? Theme.accent_hover : Theme.accent_subtle
                            border.color: Theme.accent
                            border.width: 1
                        }
                        contentItem: IconLabel {
                            iconSource: "qrc:/assets/markdown.svg"
                            label: "Copiar"
                            tintColor: Theme.accent
                            fontPixelSize: 11
                        }
                    }

                    Button {
                        text: "Pegar"
                        implicitHeight: 28
                        onClicked: root.pegarDatos()

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? Theme.accent_hover : Theme.accent_subtle
                            border.color: Theme.accent
                            border.width: 1
                        }
                        contentItem: IconLabel {
                            iconSource: "qrc:/assets/paste.svg"
                            label: "Pegar"
                            tintColor: Theme.accent
                            fontPixelSize: 11
                        }
                    }

                    Button {
                        text: "Historial"
                        implicitHeight: 28
                        onClicked: {
                            historyController.cargarHistorial();
                            historyPopup.open();
                        }

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? Theme.accent_hover : Theme.accent_subtle
                            border.color: Theme.accent
                            border.width: 1
                        }
                        contentItem: IconLabel {
                            iconSource: "qrc:/assets/history.svg"
                            label: "Historial"
                            tintColor: Theme.accent
                            fontPixelSize: 11
                        }
                    }
                }

                // ── Selector de tipo de datos ─────────────────────────────
                Label {
                    text: "Tipo de datos:"
                    color: Theme.muted_text
                    font.pixelSize: 12
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: root.tiposDeDatos

                        delegate: Rectangle {
                            id: tipoBtn
                            required property var modelData

                            readonly property bool selected: root.dataType === modelData.value

                            Layout.fillWidth: true
                            implicitHeight: 30
                            radius: 4
                            color: selected ? Theme.accent_subtle : Theme.button_background
                            border.color: selected ? Theme.border_focus : Theme.border_color
                            border.width: selected ? 2 : 1
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: tipoBtn.modelData.label
                                color: tipoBtn.selected ? Theme.accent : Theme.button_text
                                font.pixelSize: 12
                                font.bold: tipoBtn.selected
                            }
                            TapHandler {
                                onTapped: root.setDataType(tipoBtn.modelData.value)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.divider
                }

                // ── Entrada: No agrupados ──────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    visible: root.dataType === "no_agrupados"

                    Label {
                        text: "Valores separados por punto y coma:"
                        color: Theme.muted_text
                        font.pixelSize: 11
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextArea {
                            id: valoresArea
                            placeholderText: "Ej: 3; 6; 4; 6; 2; 5; 6; 4"
                            text: root.valoresText
                            wrapMode: TextArea.Wrap
                            color: Theme.input_text
                            placeholderTextColor: Theme.placeholder_text
                            background: Rectangle {
                                radius: 4
                                color: Theme.input_background
                                border.color: valoresArea.activeFocus ? Theme.border_focus : Theme.border_color
                                border.width: valoresArea.activeFocus ? 2 : 1
                            }
                            onTextChanged: {
                                var original = text;
                                // 1. Solo se permiten números, ";", ",", ".", espacio y signo menos.
                                //    "," y "." se aceptan ambos como separador decimal (no se reemplazan).
                                var procesado = original.replace(/[^0-9;,.\-\s]/g, "");
                                // 2. Si hay un número justo antes de un espacio, se convierte en "; ".
                                procesado = procesado.replace(/([0-9])[ \t]+/g, "$1; ");
                                // 3. Cualquier otro espacio (que no esté justo después de ";") se descarta.
                                procesado = procesado.replace(/(^|[^;])[ \t]+/g, "$1");
                                // 4. Máximo un separador decimal ("," o ".") por valor.
                                procesado = procesado.split(";").map(function (token) {
                                    var m = token.match(/[.,]/);
                                    if (!m)
                                        return token;
                                    var idx = token.indexOf(m[0]);
                                    return token.slice(0, idx + 1) + token.slice(idx + 1).replace(/[.,]/g, "");
                                }).join(";");

                                if (procesado !== original) {
                                    var pos = cursorPosition;
                                    var diff = procesado.length - original.length;
                                    text = procesado;
                                    cursorPosition = Math.max(0, Math.min(pos + diff, text.length));
                                    return;
                                }
                                root.valoresText = text;
                            }
                        }
                    }
                }

                // ── Entrada: Agrupados por valor ───────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    visible: root.dataType === "agrupados_valor"

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "Xi"
                            color: Theme.muted_text
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                        }
                        Label {
                            text: "Frecuencia"
                            color: Theme.muted_text
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                        }
                        Item {
                            implicitWidth: 30
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: availableWidth
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                id: valorRepeater
                                model: valorModel

                                delegate: RowLayout {
                                    id: valorRow
                                    width: parent ? parent.width : 0
                                    spacing: 8

                                    required property string xi
                                    required property string frecuencia
                                    required property int index

                                    Component.onCompleted: {
                                        if (root.focusNextValorRow && index === valorModel.count - 1) {
                                            root.focusNextValorRow = false;
                                            xiField.forceActiveFocus();
                                        }
                                    }

                                    TextField {
                                        id: xiField
                                        placeholderText: "Ej: 5"
                                        text: xi
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        color: Theme.input_text
                                        placeholderTextColor: Theme.placeholder_text
                                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        validator: RegularExpressionValidator {
                                            regularExpression: /^-?[0-9]*[.,]?[0-9]*$/
                                        }
                                        background: Rectangle {
                                            radius: 4
                                            color: Theme.input_background
                                            border.color: xiField.activeFocus ? Theme.border_focus : Theme.border_color
                                            border.width: xiField.activeFocus ? 2 : 1
                                            Behavior on border.color {
                                                ColorAnimation {
                                                    duration: 150
                                                }
                                            }
                                        }
                                        onTextChanged: valorModel.setProperty(index, "xi", text)
                                        onAccepted: root.calcular()
                                    }

                                    TextField {
                                        id: frecuenciaField
                                        placeholderText: "Ej: 3"
                                        text: frecuencia
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        color: Theme.input_text
                                        placeholderTextColor: Theme.placeholder_text
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        validator: RegularExpressionValidator {
                                            regularExpression: /^[0-9]*$/
                                        }
                                        background: Rectangle {
                                            radius: 4
                                            color: Theme.input_background
                                            border.color: frecuenciaField.activeFocus ? Theme.border_focus : Theme.border_color
                                            border.width: frecuenciaField.activeFocus ? 2 : 1
                                            Behavior on border.color {
                                                ColorAnimation {
                                                    duration: 150
                                                }
                                            }
                                        }
                                        onTextChanged: valorModel.setProperty(index, "frecuencia", text)
                                        onAccepted: root.calcular()
                                        Keys.onPressed: event => {
                                            if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier) && valorRow.index === valorModel.count - 1) {
                                                event.accepted = true;
                                                root.focusNextValorRow = true;
                                                valorModel.append({
                                                    xi: "",
                                                    frecuencia: ""
                                                });
                                            }
                                        }
                                    }

                                    Button {
                                        implicitWidth: 30
                                        implicitHeight: 30
                                        text: "✕"
                                        enabled: valorModel.count > 1
                                        opacity: enabled ? 1.0 : 0.35
                                        onClicked: valorModel.remove(index)

                                        background: Rectangle {
                                            radius: 4
                                            color: parent.hovered ? Theme.destructive_hover : Theme.destructive_bg
                                            border.color: Theme.destructive_border
                                            border.width: 1
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 120
                                                }
                                            }
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            color: Theme.error_text
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        text: "+ Agregar fila"
                        onClicked: valorModel.append({
                            xi: "",
                            frecuencia: ""
                        })

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? Theme.accent_hover : Theme.accent_subtle
                            border.color: Theme.accent
                            border.width: 1
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Theme.accent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 12
                        }
                    }
                }

                // ── Entrada: Agrupados por intervalos ──────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    visible: root.dataType === "agrupados_intervalo"

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "Lím. inf."
                            color: Theme.muted_text
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                        }
                        Item {
                            implicitWidth: 10
                        }
                        Label {
                            text: "Lím. sup."
                            color: Theme.muted_text
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                        }
                        Label {
                            text: "fi"
                            color: Theme.muted_text
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                        }
                        Item {
                            implicitWidth: 30
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: availableWidth
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                id: intervaloRepeater
                                model: intervaloModel

                                delegate: RowLayout {
                                    id: intervaloRow
                                    width: parent ? parent.width : 0
                                    spacing: 8

                                    required property string lower
                                    required property string upper
                                    required property string frecuencia
                                    required property int index

                                    Component.onCompleted: {
                                        if (root.focusNextIntervaloRow && index === intervaloModel.count - 1) {
                                            root.focusNextIntervaloRow = false;
                                            lowerField.forceActiveFocus();
                                        }
                                    }

                                    TextField {
                                        id: lowerField
                                        placeholderText: "10"
                                        text: lower
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        color: Theme.input_text
                                        placeholderTextColor: Theme.placeholder_text
                                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        validator: RegularExpressionValidator {
                                            regularExpression: /^-?[0-9]*[.,]?[0-9]*$/
                                        }
                                        background: Rectangle {
                                            radius: 4
                                            color: Theme.input_background
                                            border.color: lowerField.activeFocus ? Theme.border_focus : Theme.border_color
                                            border.width: lowerField.activeFocus ? 2 : 1
                                        }
                                        onTextChanged: intervaloModel.setProperty(index, "lower", text)
                                        onAccepted: root.calcular()
                                    }

                                    Label {
                                        text: "-"
                                        color: Theme.muted_text
                                        font.pixelSize: 13
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    TextField {
                                        id: upperField
                                        placeholderText: "19"
                                        text: upper
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        color: Theme.input_text
                                        placeholderTextColor: Theme.placeholder_text
                                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        validator: RegularExpressionValidator {
                                            regularExpression: /^-?[0-9]*[.,]?[0-9]*$/
                                        }
                                        background: Rectangle {
                                            radius: 4
                                            color: Theme.input_background
                                            border.color: upperField.activeFocus ? Theme.border_focus : Theme.border_color
                                            border.width: upperField.activeFocus ? 2 : 1
                                        }
                                        onTextChanged: intervaloModel.setProperty(index, "upper", text)
                                        onAccepted: root.calcular()
                                    }

                                    TextField {
                                        id: freqField
                                        placeholderText: "3"
                                        text: frecuencia
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        color: Theme.input_text
                                        placeholderTextColor: Theme.placeholder_text
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        validator: RegularExpressionValidator {
                                            regularExpression: /^[0-9]*$/
                                        }
                                        background: Rectangle {
                                            radius: 4
                                            color: Theme.input_background
                                            border.color: freqField.activeFocus ? Theme.border_focus : Theme.border_color
                                            border.width: freqField.activeFocus ? 2 : 1
                                        }
                                        onTextChanged: intervaloModel.setProperty(index, "frecuencia", text)
                                        onAccepted: root.calcular()
                                        Keys.onPressed: event => {
                                            if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier) && intervaloRow.index === intervaloModel.count - 1) {
                                                event.accepted = true;
                                                root.focusNextIntervaloRow = true;
                                                intervaloModel.append({
                                                    lower: "",
                                                    upper: "",
                                                    frecuencia: ""
                                                });
                                            }
                                        }
                                    }

                                    Button {
                                        implicitWidth: 30
                                        implicitHeight: 30
                                        text: "✕"
                                        enabled: intervaloModel.count > 1
                                        opacity: enabled ? 1.0 : 0.35
                                        onClicked: intervaloModel.remove(index)

                                        background: Rectangle {
                                            radius: 4
                                            color: parent.hovered ? Theme.destructive_hover : Theme.destructive_bg
                                            border.color: Theme.destructive_border
                                            border.width: 1
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            color: Theme.error_text
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        text: "+ Agregar intervalo"
                        onClicked: intervaloModel.append({
                            lower: "",
                            upper: "",
                            frecuencia: ""
                        })

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? Theme.accent_hover : Theme.accent_subtle
                            border.color: Theme.accent
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Theme.accent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 12
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.divider
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        text: "Calcular"
                        Layout.fillWidth: true
                        implicitHeight: 38
                        onClicked: root.calcular()

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? Qt.darker(Theme.accent, 1.12) : Theme.accent
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Theme.accent_text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }

                    Button {
                        text: "Limpiar"
                        Layout.fillWidth: true
                        implicitHeight: 38
                        onClicked: root.limpiar()

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? Qt.darker(Theme.button_background, 1.08) : Theme.button_background
                            border.color: Theme.border_color
                            border.width: 1
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Theme.button_text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Theme.divider
        }

        // ── Panel derecho: tabla ──────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.window_background

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Tabla de frecuencias"
                        color: Theme.primary_text
                        font.bold: true
                        font.pixelSize: 15
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Copiar tabla"
                        implicitHeight: 28
                        visible: root.tableModel.length > 0
                        onClicked: root.copiarTabla()

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? Theme.accent_hover : Theme.accent_subtle
                            border.color: Theme.accent
                            border.width: 1
                        }
                        contentItem: IconLabel {
                            iconSource: "qrc:/assets/markdown.svg"
                            label: "Copiar tabla"
                            tintColor: Theme.accent
                            fontPixelSize: 11
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.tableModel.length === 0

                    Label {
                        anchors.centerIn: parent
                        text: "Ingrese valores y presione Calcular"
                        color: Theme.muted_text
                        font.pixelSize: 13
                    }
                }

                // ── Tarjetas de resultados ──────────────────────────────
                GridLayout {
                    columns: 3
                    rowSpacing: 8
                    columnSpacing: 8
                    Layout.fillWidth: true
                    visible: root.tableModel.length > 0

                    ResultCard {
                        label: "n"
                        value: root.result["n"] !== undefined ? root.result["n"].toString() : "—"
                    }
                    ResultCard {
                        label: "Media (x̄)"
                        value: root.result["mean"] ?? "—"
                    }
                    ResultCard {
                        label: "Rango"
                        value: root.result["rango"] ?? "—"
                    }
                    ResultCard {
                        label: "Mediana (Me)"
                        value: root.result["mediana"] ?? "—"
                    }
                    ResultCard {
                        label: "Moda (Mo)"
                        value: root.result["moda"] ?? "—"
                    }
                }

                Table {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.tableModel.length > 0
                    dataType: root.dataType
                    model: root.tableModel
                }
            }
        }
    }

    // ── Popup: historial de operaciones de este módulo ─────────────────────
    Popup {
        id: historyPopup
        anchors.centerIn: parent
        width: Math.min(720, root.width * 0.9)
        height: Math.min(480, root.height * 0.85)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Theme.window_background
            radius: 6
            border.color: Theme.border_color
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "Historial — Frecuencias"
                    color: Theme.primary_text
                    font.bold: true
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }

                Button {
                    text: "Limpiar"
                    implicitHeight: 26
                    enabled: root.historyEntries.length > 0
                    onClicked: historyController.limpiarHistorialModulo("frecuencias")

                    background: Rectangle {
                        radius: 4
                        color: parent.hovered ? Theme.destructive_hover : Theme.destructive_bg
                        border.color: Theme.destructive_border
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.error_text
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "✕"
                    implicitWidth: 26
                    implicitHeight: 26
                    onClicked: historyPopup.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.panel_background
                radius: 4
                border.color: Theme.border_color
                border.width: 1
                clip: true

                HistoryTable {
                    anchors.fill: parent
                    anchors.margins: 1
                    model: root.historyEntries
                    onDeleteRequested: entryId => historyController.eliminarEntrada(entryId)
                    onLoadRequested: entry => root.cargarDesdeHistorial(entry)
                }
            }
        }
    }
}
