import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
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

                        Row {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 13
                            spacing: 8

                            Item {
                                width: 20
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: sidebarToggleIcon
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: root.sidebarExpanded ? "qrc:/assets/close-sidebar.svg" : "qrc:/assets/open-sidebar.svg"
                                    sourceSize: Qt.size(16, 16)
                                    fillMode: Image.PreserveAspectFit
                                    visible: false
                                }

                                MultiEffect {
                                    anchors.fill: sidebarToggleIcon
                                    source: sidebarToggleIcon
                                    colorization: 1.0
                                    colorizationColor: Theme.muted_text
                                    brightness: 1.0
                                }
                            }
                            Text {
                                text: "Menú"
                                color: Theme.muted_text
                                font.pixelSize: 12
                                visible: root.sidebarExpanded
                                height: 16
                                verticalAlignment: Text.AlignVCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.divider
                    }

                    NavItem {
                        iconSource: "qrc:/assets/chart-historgram.svg"
                        label: "Frecuencias"
                        active: root.currentPage === 0
                        expanded: root.sidebarExpanded
                        onActivated: root.currentPage = 0
                    }

                    NavItem {
                        iconSource: "qrc:/assets/chart-scatter.svg"
                        label: "Dispersión"
                        active: root.currentPage === 1
                        expanded: root.sidebarExpanded
                        onActivated: root.currentPage = 1
                    }

                    NavItem {
                        iconSource: "qrc:/assets/formula.svg"
                        label: "Fórmulas"
                        active: root.currentPage === 2
                        expanded: root.sidebarExpanded
                        onActivated: root.currentPage = 2
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.divider
                    }

                    NavItem {
                        iconSource: "qrc:/assets/info.svg"
                        label: "Acerca de"
                        active: root.currentPage === 3
                        expanded: root.sidebarExpanded
                        onActivated: root.currentPage = 3
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
                    id: frecuenciasPage
                    anchors.fill: parent
                    visible: root.currentPage === 0
                    onToastRequested: (message, error) => toast.show(message, error)
                }

                DispersionPage {
                    id: dispersionPage
                    anchors.fill: parent
                    visible: root.currentPage === 1
                    onToastRequested: (message, error) => toast.show(message, error)
                }

                FormulasPage {
                    id: formulasPage
                    anchors.fill: parent
                    visible: root.currentPage === 2
                }

                AcercaPage {
                    anchors.fill: parent
                    visible: root.currentPage === 3
                }
            }
        }
    }

    Toast {
        id: toast
    }

    // ── Componente NavItem ────────────────────────────────────────────────
    component NavItem: Rectangle {
        id: navItem

        property string iconSource: ""
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

        Row {
            id: navRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 13
            anchors.rightMargin: 8
            spacing: 10

            Item {
                id: navIconWrap
                width: 20
                height: 16
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: navIconImg
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: navItem.iconSource
                    sourceSize: Qt.size(16, 16)
                    fillMode: Image.PreserveAspectFit
                    visible: false
                }

                MultiEffect {
                    anchors.fill: navIconImg
                    source: navIconImg
                    colorization: 1.0
                    colorizationColor: navItem.active ? Theme.accent : Theme.muted_text
                    brightness: 1.0
                }
            }

            Text {
                text: navItem.label
                color: navItem.active ? Theme.primary_text : Theme.muted_text
                font.pixelSize: 13
                font.bold: navItem.active
                visible: navItem.expanded
                width: navRow.width - navIconWrap.width - navRow.spacing
                height: navIconWrap.height
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
            }
        }

        ToolTip.visible: (navItem.expanded === false) && (navHover.containsMouse === true)
        ToolTip.text: navItem.label
        ToolTip.delay: 400
    }
}
