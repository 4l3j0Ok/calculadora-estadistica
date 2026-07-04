pragma Singleton

import QtQuick

// Todos los colores se derivan del SystemPalette del sistema (KDE/Plasma).
// Cambiar el esquema de colores en Plasma cambia automáticamente todos los
// colores de la aplicación.
QtObject {
    id: theme

    // ── Paleta del sistema ────────────────────────────────────────────────
    readonly property SystemPalette _active: SystemPalette {
        colorGroup: SystemPalette.Active
    }
    readonly property SystemPalette _disabled: SystemPalette {
        colorGroup: SystemPalette.Disabled
    }

    // ── Fondos ────────────────────────────────────────────────────────────
    // Fondo principal de la ventana
    readonly property color window_background:  _active.window
    // Panel secundario (izquierdo): alternateBase suele ser levemente más oscuro/claro
    readonly property color panel_background:   _active.alternateBase
    // Sidebar: un paso más profundo que la ventana
    readonly property color sidebar_background: Qt.darker(_active.window, 1.12)

    // ── Barra de navegación / acento ──────────────────────────────────────
    readonly property color nav_background:     _active.highlight
    readonly property color nav_text:           _active.highlightedText

    // ── Texto ─────────────────────────────────────────────────────────────
    readonly property color primary_text:       _active.windowText
    // Texto secundario: windowText al 50% de opacidad
    readonly property color muted_text:         Qt.rgba(
                                                    _active.windowText.r,
                                                    _active.windowText.g,
                                                    _active.windowText.b,
                                                    0.45
                                                )
    // Placeholder en inputs: más tenue aún
    readonly property color placeholder_text:   Qt.rgba(
                                                    _active.windowText.r,
                                                    _active.windowText.g,
                                                    _active.windowText.b,
                                                    0.30
                                                )
    readonly property color disabled_text:      _disabled.windowText

    // ── Inputs ────────────────────────────────────────────────────────────
    readonly property color input_background:   _active.base
    readonly property color input_text:         _active.text

    // ── Bordes ────────────────────────────────────────────────────────────
    readonly property color border_color:       Qt.rgba(
                                                    _active.windowText.r,
                                                    _active.windowText.g,
                                                    _active.windowText.b,
                                                    0.15
                                                )
    readonly property color border_focus:       _active.highlight
    readonly property color divider:            Qt.rgba(
                                                    _active.windowText.r,
                                                    _active.windowText.g,
                                                    _active.windowText.b,
                                                    0.10
                                                )

    // ── Botones ───────────────────────────────────────────────────────────
    readonly property color button_background:  _active.button
    readonly property color button_text:        _active.buttonText

    // ── Acento (highlight del sistema) ────────────────────────────────────
    readonly property color accent:             _active.highlight
    readonly property color accent_text:        _active.highlightedText
    // Acento tenue: fondo de botones de acción secundarios
    readonly property color accent_subtle:      Qt.rgba(
                                                    _active.highlight.r,
                                                    _active.highlight.g,
                                                    _active.highlight.b,
                                                    0.15
                                                )
    // Hover del acento
    readonly property color accent_hover:       Qt.rgba(
                                                    _active.highlight.r,
                                                    _active.highlight.g,
                                                    _active.highlight.b,
                                                    0.25
                                                )

    // ── Tabla ─────────────────────────────────────────────────────────────
    readonly property color table_header_bg:    _active.highlight
    readonly property color table_header_text:  _active.highlightedText
    // Divisor de sección en la tabla (línea debajo del header)
    readonly property color table_divider:      Qt.darker(_active.highlight, 1.3)
    readonly property color table_row_base:     _active.base
    // alternateBase suele ser casi idéntico a base en muchos temas de Plasma,
    // por lo que las bandas no se distinguen. Se mezcla base con windowText
    // a baja opacidad para garantizar contraste visible en cualquier paleta.
    readonly property color table_row_alt:      Qt.tint(
                                                    _active.base,
                                                    Qt.rgba(
                                                        _active.windowText.r,
                                                        _active.windowText.g,
                                                        _active.windowText.b,
                                                        0.06
                                                    )
                                                )
    readonly property color table_cell_text:    _active.text
    // Fila de totales: versión oscurecida del acento
    readonly property color table_totals_bg:    Qt.rgba(
                                                    _active.highlight.r,
                                                    _active.highlight.g,
                                                    _active.highlight.b,
                                                    0.18
                                                )
    readonly property color table_totals_text:  Qt.lighter(_active.highlight, 1.4)

    // ── Semánticos ────────────────────────────────────────────────────────
    // Error / destructivo: rojo que funciona en temas claros y oscuros
    readonly property color error_color:        "#c0392b"
    readonly property color destructive_bg:     Qt.rgba(0.75, 0.12, 0.12, 0.20)
    readonly property color destructive_hover:  Qt.rgba(0.75, 0.12, 0.12, 0.38)
    readonly property color destructive_border: Qt.rgba(0.75, 0.20, 0.20, 0.55)
    readonly property color error_text:         Qt.lighter("#c0392b", 1.3)
}
