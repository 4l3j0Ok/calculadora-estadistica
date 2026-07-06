pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "components"

// Página: Acerca de
// Información del repositorio y del creador, con accesos directos a
// web personal, GitHub, LinkedIn y correo. Los íconos SVG se cargan desde recursos
// embebidos (resources.qrc) y se colorizan con MultiEffect para heredar
// el color del texto (Theme.primary_text), igual en cualquier paleta.
Item {
    id: root

    readonly property string repoUrl: "https://github.com/4l3j0Ok/calculadora-estadistica"
    readonly property string personalUrl: "https://www.alejoide.com"
    readonly property string personalGithubUrl: "https://github.com/4l3j0Ok"
    readonly property string linkedinUrl: "https://www.linkedin.com/in/alejoide"
    readonly property string mailAddress: "contacto@alejoide.com"

    component IconButton: Rectangle {
        id: iconBtn

        property string iconSource: ""
        property string label: ""
        property color iconColor: Theme.button_text

        signal clicked

        implicitWidth: 120
        implicitHeight: 40
        radius: 6
        color: btnHover.hovered ? Theme.accent_hover : Theme.accent_subtle
        border.color: Theme.accent
        border.width: 1

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        HoverHandler {
            id: btnHover
        }
        TapHandler {
            onTapped: iconBtn.clicked()
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Item {
                implicitWidth: 18
                implicitHeight: 18

                Image {
                    id: iconImg
                    anchors.fill: parent
                    source: iconBtn.iconSource
                    sourceSize: Qt.size(18, 18)
                    fillMode: Image.PreserveAspectFit
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: iconImg
                    colorization: 1.0
                    colorizationColor: iconBtn.iconColor
                    brightness: 1.0
                }
            }

            Text {
                text: iconBtn.label
                color: Theme.accent
                font.pixelSize: 13
                font.bold: true
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight + 48
        clip: true

        ColumnLayout {
            id: content
            width: Math.min(560, parent.width - 48)
            x: (parent.width - width) / 2
            y: 32
            spacing: 20

            Text {
                text: "Acerca de"
                color: Theme.primary_text
                font.bold: true
                font.pixelSize: 20
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.divider
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Calculadora de Probabilidad y Estadística"
                    color: Theme.primary_text
                    font.bold: true
                    font.pixelSize: 15
                }

                Text {
                    text: "Aplicación de escritorio (PySide6 + QML) para calcular medidas de " + "frecuencia y dispersión estadística." + "\nSolicitado por cátedra de Probabilidad y Estadística del ISFT N° 93."
                    color: Theme.muted_text
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Text {
                    text: "Versión " + appVersion
                    color: Theme.muted_text
                    font.pixelSize: 11
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                IconButton {
                    iconSource: "qrc:/assets/git.svg"
                    label: "Repositorio"
                    implicitWidth: 140
                    onClicked: Qt.openUrlExternally(root.repoUrl)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Creador"
                    color: Theme.muted_text
                    font.pixelSize: 11
                }

                Text {
                    text: "Alejoide"
                    color: Theme.primary_text
                    font.bold: true
                    font.pixelSize: 15
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    IconButton {
                        iconSource: "qrc:/assets/www.svg"
                        label: "Sitio web"
                        onClicked: Qt.openUrlExternally(root.personalUrl)
                    }

                    IconButton {
                        iconSource: "qrc:/assets/github.svg"
                        label: "GitHub"
                        onClicked: Qt.openUrlExternally(root.personalGithubUrl)
                    }

                    IconButton {
                        iconSource: "qrc:/assets/linkedin.svg"
                        label: "LinkedIn"
                        onClicked: Qt.openUrlExternally(root.linkedinUrl)
                    }

                    IconButton {
                        iconSource: "qrc:/assets/mail.svg"
                        label: "Mail"
                        onClicked: Qt.openUrlExternally("mailto:" + root.mailAddress)
                    }
                }
            }
        }
    }
}
