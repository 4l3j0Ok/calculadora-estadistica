pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property string titleText: ""

    implicitHeight: 50
    color: Theme.nav_background

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        Text {
            text: root.titleText
            color: Theme.nav_text
            font.bold: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            fontSizeMode: Text.Fit
            wrapMode: Text.Wrap
        }
    }
}
