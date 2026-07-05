pragma ComponentBehavior: Bound

import QtQuick

// Texto con efecto "carrusel" vertical al cambiar de contenido: el texto
// anterior se desliza hacia abajo mientras se desvanece, y el nuevo texto
// entra deslizándose desde arriba. Se dispara automáticamente cada vez
// que cambia `text` (o `fontSize`), siempre en la misma dirección sin
// importar si el cambio "va" o "vuelve" (p. ej. abreviatura ↔ descripción
// completa de un header de tabla).
Item {
    id: root

    property string text: ""
    property color textColor: "black"
    property real fontSize: 12
    property bool bold: true
    property int animDuration: 220

    property string _currentText: text
    property real _currentFontSize: fontSize

    clip: true

    Text {
        id: outText
        anchors.fill: parent
        color: root.textColor
        font.bold: root.bold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: 2
        opacity: 0
        y: 0
    }

    Text {
        id: inText
        anchors.fill: parent
        color: root.textColor
        font.bold: root.bold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: 2
        text: root._currentText
        font.pixelSize: root._currentFontSize
        opacity: 1
        y: 0
    }

    function _sync() {
        if (root.text === root._currentText && root.fontSize === root._currentFontSize)
            return;

        // El texto "actual" pasa a ser el saliente: se congela tal cual
        // estaba y se anima hacia abajo, desvaneciéndose.
        outText.text = inText.text;
        outText.font.pixelSize = inText.font.pixelSize;
        outText.y = 0;
        outText.opacity = 1;

        // El nuevo texto se ubica arriba (fuera de vista) antes de animar.
        root._currentText = root.text;
        root._currentFontSize = root.fontSize;
        inText.text = root._currentText;
        inText.font.pixelSize = root._currentFontSize;
        inText.y = -inText.height;
        inText.opacity = 0;

        swapAnim.start();
    }

    onTextChanged: root._sync()
    onFontSizeChanged: root._sync()

    ParallelAnimation {
        id: swapAnim

        NumberAnimation {
            target: outText
            property: "y"
            to: outText.height
            duration: root.animDuration
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: outText
            property: "opacity"
            to: 0
            duration: root.animDuration
        }
        NumberAnimation {
            target: inText
            property: "y"
            to: 0
            duration: root.animDuration
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: inText
            property: "opacity"
            to: 1
            duration: root.animDuration
        }
    }
}
