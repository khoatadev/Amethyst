import QtQuick

QtObject {
    id: root

    // =========================================================================
    // Tokyo Night Moon Theme Palette
    // =========================================================================

    // Backgrounds
    readonly property color bg: "#222436"
    readonly property color bgDark: "#1e2030"
    readonly property color bgCard: "#262940"
    readonly property color bgHover: "#2d3f76"

    // Borders
    readonly property color border: "#2f334d"
    readonly property color borderActive: "#82aaff"
    readonly property color borderHover: "#444a73"

    // Text & Foregrounds
    readonly property color fg: "#c8d3f5"
    readonly property color fgMuted: "#828bb8"
    readonly property color fgSubtle: "#545c7e"

    // Accent & Status Colors
    readonly property color accent: "#82aaff"     // Tokyo Blue
    readonly property color green: "#c3e88d"      // Battery / Good
    readonly property color yellow: "#ffc777"     // Brightness / Warn
    readonly property color orange: "#ff966c"     // Battery Mid
    readonly property color red: "#ff757f"        // Battery Low / Mute
    readonly property color purple: "#c099ff"     // Extra accent

    // Typography
    readonly property string fontMono: "ComicShannsMono Nerd Font"
}
