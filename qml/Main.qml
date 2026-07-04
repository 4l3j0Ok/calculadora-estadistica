import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ApplicationWindow {
    id: root
    visible: true
    minimumHeight: 600
    minimumWidth: 860
    title: "Probabilidad y Estadística + Programación Orientada a Objetos"
    color: Theme.window_background

    // ── Estado de la sidebar ──────────────────────────────────────────────
    property int currentPage: 0
    property bool sidebarExpanded: true

    readonly property int sidebarExpandedWidth: 190
    readonly property int sidebarCollapsedWidth: 50

    // ── Layout principal ──────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        NavBar {
            Layout.fillWidth: true
            titleText: "Probabilidad y Estadística x POO"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ── Sidebar ───────────────────────────────────────────────────
            Rectangle {
                id: sidebar
                Layout.fillHeight: true
                Layout.preferredWidth: root.sidebarExpanded ? root.sidebarExpandedWidth : root.sidebarCollapsedWidth
                Layout.minimumWidth: root.sidebarCollapsedWidth
                Layout.maximumWidth: root.sidebarExpandedWidth
                color: Theme.sidebar_background
                clip: true

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Botón colapsar / expandir
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        color: toggleHover.containsMouse ? Theme.accent_subtle : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        HoverHandler {
                            id: toggleHover
                        }
                        TapHandler {
                            onTapped: root.sidebarExpanded = !root.sidebarExpanded
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 13
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: root.sidebarExpanded ? "◀" : "▶"
                                color: Theme.muted_text
                                font.pixelSize: 12
                            }
                            Text {
                                text: "Menú"
                                color: Theme.muted_text
                                font.pixelSize: 12
                                visible: root.sidebarExpanded
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.divider
                    }

                    NavItem {
                        icon: "f(x)"
                        label: "Frecuencias"
                        active: root.currentPage === 0
                        expanded: root.sidebarExpanded
                        onActivated: root.currentPage = 0
                    }

                    NavItem {
                        icon: "σ"
                        label: "Dispersión"
                        active: root.currentPage === 1
                        expanded: root.sidebarExpanded
                        onActivated: root.currentPage = 1
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            // Divisor sidebar / contenido
            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: Theme.divider
            }

            // ── Área de contenido ─────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                FrecuenciasPage {
                    anchors.fill: parent
                    visible: root.currentPage === 0
                }

                DispersionPage {
                    anchors.fill: parent
                    visible: root.currentPage === 1
                }
            }
        }
    }

    // ── Componente NavItem ────────────────────────────────────────────────
    component NavItem: Rectangle {
        id: navItem

        property string icon: ""
        property string label: ""
        property bool active: false
        property bool expanded: true

        signal activated

        Layout.fillWidth: true
        implicitHeight: 44
        color: active ? Theme.accent_subtle : (navHover.containsMouse ? Theme.divider : "transparent")

        // Barra de acento izquierda
        Rectangle {
            width: 3
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            color: navItem.active ? Theme.accent : "transparent"
            radius: 2
        }

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        HoverHandler {
            id: navHover
        }
        TapHandler {
            onTapped: navItem.activated()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 13
            anchors.rightMargin: 8
            spacing: 10

            Text {
                text: navItem.icon
                color: navItem.active ? Theme.accent : Theme.muted_text
                font.pixelSize: 14
                font.bold: navItem.active
                Layout.minimumWidth: 20
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: navItem.label
                color: navItem.active ? Theme.primary_text : Theme.muted_text
                font.pixelSize: 13
                font.bold: navItem.active
                visible: navItem.expanded
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        ToolTip.visible: (navItem.expanded === false) && (navHover.containsMouse === true)
        ToolTip.text: navItem.label
        ToolTip.delay: 400
    }
}
