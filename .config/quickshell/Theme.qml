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

    // =========================================================================
    // Glow variants (alpha ~0.3) — dùng cho hiệu ứng phát sáng / ripple
    // =========================================================================
    readonly property color accentGlow: Qt.rgba(0x82 / 255, 0xaa / 255, 0xff / 255, 0.35)
    readonly property color glowGreen: Qt.rgba(0xc3 / 255, 0xe8 / 255, 0x8d / 255, 0.30)
    readonly property color glowYellow: Qt.rgba(0xff / 255, 0xc7 / 255, 0x77 / 255, 0.30)
    readonly property color glowRed: Qt.rgba(0xff / 255, 0x75 / 255, 0x7f / 255, 0.30)
    readonly property color glowPurple: Qt.rgba(0xc0 / 255, 0x99 / 255, 0xff / 255, 0.30)

    // =========================================================================
    // Animation constants (ms)
    // =========================================================================
    readonly property int durFast: 150
    readonly property int durMed: 250
    readonly property int durSlow: 400

    // Typography
    readonly property string fontMono: "ComicShannsMono Nerd Font"
}
