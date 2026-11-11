import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    Theme { id: theme }

    width: 40
    height: col.implicitHeight + 12
    radius: 10
    color: mouseArea.containsMouse ? theme.bgHover : theme.bgDark

    Behavior on color { ColorAnimation { duration: 150 } }

    property int brightness: 75

    // Read initial & updated brightness
    Process {
        id: brightReader
        command: ["brightnessctl", "-m"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(',')
                if (parts.length >= 4) {
                    let pct = parseInt(parts[3].replace('%', ''))
                    if (!isNaN(pct)) {
                        root.brightness = pct
                    }
                }
            }
        }
    }

    Process {
        id: brightSetter
    }

    Timer {
        id: refreshTimer
        interval: 80
        repeat: false
        onTriggered: {
            brightReader.running = false
            brightReader.running = true
        }
    }

    // Periodic sync
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            brightReader.running = false
            brightReader.running = true
        }
    }

    function step(amount) {
        brightSetter.exec(["brightnessctl", "set", amount])
        refreshTimer.restart()
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.brightness > 70 ? "󰃠" : (root.brightness > 30 ? "󰃟" : "󰃞")
            font.family: theme.fontMono
            font.pixelSize: 16
            color: theme.yellow
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.brightness + "%"
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
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                root.step("5%+")
            } else {
                root.step("5%-")
            }
        }
    }
}
