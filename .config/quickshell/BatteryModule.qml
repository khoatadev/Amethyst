import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Rectangle {
    id: root

    Theme { id: theme }

    width: 40
    height: col.implicitHeight + 12
    radius: 10
    color: mouseArea.containsMouse ? theme.bgHover : theme.bgDark

    Behavior on color { ColorAnimation { duration: 150 } }

    property int percentage: 100
    property bool isCharging: false

    // UPower Service Connection
    Connections {
        target: UPower.displayDevice
        function onPercentageChanged() {
            if (UPower.displayDevice) {
                root.percentage = Math.round(UPower.displayDevice.percentage * 100)
            }
        }
        function onStateChanged() {
            if (UPower.displayDevice) {
                root.isCharging = (UPower.displayDevice.state === 1) // 1: Charging
            }
        }
    }

    // Direct sysfs reader as fallback/instant boot
    Process {
        id: batReader
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity 2>/dev/null; cat /sys/class/power_supply/BAT1/status 2>/dev/null"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n")
                if (lines.length >= 1) {
                    let pct = parseInt(lines[0])
                    if (!isNaN(pct)) root.percentage = pct
                }
                if (lines.length >= 2) {
                    let st = lines[1].toLowerCase()
                    root.isCharging = st.includes("charging")
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            batReader.running = false
            batReader.running = true
        }
    }

    function getBatteryIcon() {
        if (root.isCharging) return "󰂄"
        if (root.percentage >= 90) return "󰁹"
        if (root.percentage >= 70) return "󰂀"
        if (root.percentage >= 50) return "󰁾"
        if (root.percentage >= 30) return "󰁼"
        if (root.percentage >= 15) return "󰁺"
        return "󰂃"
    }

    function getBatteryColor() {
        if (root.isCharging || root.percentage > 30) return theme.green
        if (root.percentage > 15) return theme.yellow
        return theme.red
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.getBatteryIcon()
            font.family: theme.fontMono
            font.pixelSize: 16
            color: root.getBatteryColor()
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.percentage + "%"
            font.family: theme.fontMono
            font.pixelSize: 9
            font.bold: true
            color: theme.fg
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
