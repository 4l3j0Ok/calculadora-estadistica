import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// Etiqueta reutilizable con ícono SVG (colorizado vía MultiEffect) + texto.
// Pensada para usarse como contentItem de Button/Rectangle en toda la app.
RowLayout {
    id: root

    property string iconSource: ""
    property alias label: labelText.text
    property color tintColor: "white"
    property int iconSize: 14
    property int fontPixelSize: 12
    property bool bold: false

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    spacing: 6

    Item {
        implicitWidth: root.iconSource !== "" ? root.iconSize : 0
        implicitHeight: root.iconSize
        visible: root.iconSource !== ""
        Layout.alignment: Qt.AlignVCenter

        Image {
            id: iconImg
            anchors.fill: parent
            source: root.iconSource
            sourceSize: Qt.size(root.iconSize, root.iconSize)
            fillMode: Image.PreserveAspectFit
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: iconImg
            colorization: 1.0
            colorizationColor: root.tintColor
            brightness: 1.0
        }
    }

    Text {
        id: labelText
        color: root.tintColor
        font.pixelSize: root.fontPixelSize
        font.bold: root.bold
        height: root.iconSize
        verticalAlignment: Text.AlignVCenter
        Layout.alignment: Qt.AlignVCenter
    }
}
