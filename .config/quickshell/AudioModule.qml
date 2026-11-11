import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    Theme { id: theme }

    width: 40
    height: col.implicitHeight + 12
    radius: 10
    color: mouseArea.containsMouse ? theme.bgCard : theme.bgDark
    border.color: mouseArea.containsMouse ? theme.borderHover : theme.border
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    property int volume: 25
    property bool isMuted: false

    Process {
        id: volReader
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let str = data.trim()
                root.isMuted = str.includes("[MUTED]")
                let match = str.match(/Volume:\s+([0-9.]+)/)
                if (match) {
                    root.volume = Math.round(parseFloat(match[1]) * 100)
                }
            }
        }
    }

    Process {
        id: volSetter
    }

    // Subscribe to PulseAudio/PipeWire events for instant hardware key sync
    Process {
        id: pactlListener
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.includes("sink") || data.includes("client")) {
                    volRefreshTimer.restart()
                }
            }
        }
    }

    Timer {
        id: volRefreshTimer
        interval: 80
        repeat: false
        onTriggered: {
            volReader.running = false
            volReader.running = true
        }
    }

    function changeVolume(delta) {
        volSetter.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", delta])
        volRefreshTimer.restart()
    }

    function toggleMute() {
        volSetter.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        volRefreshTimer.restart()
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                if (root.isMuted) return "󰝟"
                if (root.volume > 50) return "󰕾"
                if (root.volume > 0) return "󰖀"
                return "󰕿"
            }
            font.family: theme.fontMono
            font.pixelSize: 16
            color: root.isMuted ? theme.red : theme.accent
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.isMuted ? "Mute" : (root.volume + "%")
            font.family: theme.fontMono
            font.pixelSize: root.isMuted ? 8 : 9
            font.bold: true
            color: root.isMuted ? theme.red : theme.fg
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                root.changeVolume("5%+")
            } else {
                root.changeVolume("5%-")
            }
        }
        onClicked: {
            root.toggleMute()
        }
    }
}
