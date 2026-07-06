import QtQuick

Rectangle {
    id: root

    property string message: ""
    property bool error: false

    function show(newMessage, isError) {
        root.message = newMessage;
        root.error = isError;
        root.visible = true;
        root.y = root.parent.height + 12;
        toastIn.restart();
        toastTimer.restart();
    }

    anchors.right: parent.right
    anchors.rightMargin: 18
    width: Math.min(Math.max(toastText.implicitWidth + 36, 260), parent.width - 36)
    height: Math.max(44, toastText.implicitHeight + 22)
    radius: 8
    color: root.error ? Qt.rgba(0.50, 0.11, 0.11, 0.65) : Qt.rgba(0.08, 0.33, 0.18, 0.65)
    border.color: root.error ? "#f87171" : "#4ade80"
    border.width: 1
    y: parent.height + 12
    visible: false
    z: 20

    YAnimator {
        id: toastIn
        target: root
        from: root.parent.height + 12
        to: root.parent.height - root.height - 18
        duration: 220
        easing.type: Easing.OutCubic
    }

    YAnimator {
        id: toastOut
        target: root
        from: root.y
        to: root.parent.height + 12
        duration: 180
        easing.type: Easing.InCubic
        onFinished: root.visible = false
    }

    Text {
        id: toastText
        anchors.fill: parent
        anchors.margins: 11
        text: root.message
        color: "#ffffff"
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }

    Timer {
        id: toastTimer
        interval: root.error ? 3600 : 2200
        onTriggered: toastOut.restart()
    }
}
