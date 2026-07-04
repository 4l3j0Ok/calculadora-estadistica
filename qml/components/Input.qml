pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string labelText: ""
    property string placeholderText: ""
    property alias text: field.text
    property alias textField: field

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    property bool fieldFocused: false

    Behavior on fieldFocused {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 6

        Label {
            text: root.labelText
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        TextField {
            id: field
            placeholderText: root.placeholderText
            Layout.fillWidth: true

            onActiveFocusChanged: root.fieldFocused = activeFocus

            background: Rectangle {
                radius: 5
                color: Theme.window_background
                border.width: 1
                border.color: field.activeFocus ? Theme.border_focus : Theme.border_color

                Behavior on border.color {
                    ColorAnimation {
                        duration: 180
                    }
                }
                Behavior on border.width {
                    NumberAnimation {
                        duration: 180
                    }
                }

                SequentialAnimation on opacity {
                    running: field.activeFocus
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.88
                        duration: 900
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: 900
                        easing.type: Easing.InOutSine
                    }
                }
            }

            cursorDelegate: Rectangle {
                width: 2
                radius: 1
                color: Theme.nav_background

                SequentialAnimation on opacity {
                    running: field.activeFocus
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.15
                        duration: 450
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: 450
                    }
                }
            }
        }
    }
}
