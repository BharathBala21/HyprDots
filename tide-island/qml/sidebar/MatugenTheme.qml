import QtQuick

QtObject {
    id: root

    // The raw themeColors object from DynamicIslandWindow
    property var colors: null

    // Helper properties with StyleTokens / default fallbacks
    readonly property color primary: colors && colors.primary !== undefined ? colors.primary : "#1793D1"
    readonly property color on_primary: colors && colors.on_primary !== undefined ? colors.on_primary : "#FFFFFF"
    readonly property color primary_container: colors && colors.primary_container !== undefined ? colors.primary_container : "#0E3A53"
    readonly property color on_primary_container: colors && colors.on_primary_container !== undefined ? colors.on_primary_container : "#D1E8FF"

    readonly property color secondary: colors && colors.secondary !== undefined ? colors.secondary : "#A5B4FC"
    readonly property color secondary_container: colors && colors.secondary_container !== undefined ? colors.secondary_container : "#312E81"
    readonly property color on_secondary: colors && colors.on_secondary !== undefined ? colors.on_secondary : "#E0E7FF"

    readonly property color background: colors && colors.background !== undefined ? colors.background : "#0F172A"
    readonly property color on_background: colors && colors.on_background !== undefined ? colors.on_background : "#F1F5F9"

    readonly property color surface: colors && colors.surface !== undefined ? colors.surface : "#1E293B"
    readonly property color surface_container: colors && colors.surface_container !== undefined ? colors.surface_container : "#0F172A"
    readonly property color on_surface: colors && colors.on_surface !== undefined ? colors.on_surface : "#F1F5F9"
    readonly property color on_surface_variant: colors && colors.on_surface_variant !== undefined ? colors.on_surface_variant : "#94A3B8"

    readonly property color outline: colors && colors.outline !== undefined ? colors.outline : "#475569"
    readonly property color outline_variant: colors && colors.outline_variant !== undefined ? colors.outline_variant : "#334155"

    readonly property color error: colors && colors.error !== undefined ? colors.error : "#EF4444"
    readonly property color error_container: colors && colors.error_container !== undefined ? colors.error_container : "#7F1D1D"
    readonly property color on_error: colors && colors.on_error !== undefined ? colors.on_error : "#FFFFFF"
}
