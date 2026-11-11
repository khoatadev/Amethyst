import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Rectangle {
    id: root

    Theme { id: theme }

    width: 38
    height: col.implicitHeight + 16
    radius: width / 2
    color: theme.bgDark

    // -------------------------------------------------------------
    // Brightness Logic
    // -------------------------------------------------------------
    property int brightness: 75

    Process {
        id: brightReader
        command: ["brightnessctl", "-m"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(',')
                if (parts.length >= 4) {
                    let pct = parseInt(parts[3].replace('%', ''))
                    if (!isNaN(pct)) root.brightness = pct
                }
            }
        }
    }

    Process { id: brightSetter }

    Timer {
        id: brightRefreshTimer
        interval: 80
        repeat: false
        onTriggered: {
            brightReader.running = false
            brightReader.running = true
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            brightReader.running = false
            brightReader.running = true
        }
    }

    function stepBrightness(amount) {
        brightSetter.exec(["brightnessctl", "set", amount])
        brightRefreshTimer.restart()
    }

    // -------------------------------------------------------------
    // Audio Logic
    // -------------------------------------------------------------
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

    Process { id: volSetter }

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

    function stepVolume(delta) {
        volSetter.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", delta])
        volRefreshTimer.restart()
    }

    function toggleMute() {
        volSetter.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        volRefreshTimer.restart()
    }

    // -------------------------------------------------------------
    // Battery & Power Profile Logic
    // -------------------------------------------------------------
    property int batteryPct: 100
    property bool isCharging: false
    property string currentProfile: "performance" // "performance" | "balanced" | "power-saver"

    Connections {
        target: UPower.displayDevice
        function onPercentageChanged() {
            if (UPower.displayDevice) {
                root.batteryPct = Math.round(UPower.displayDevice.percentage * 100)
            }
        }
        function onStateChanged() {
            if (UPower.displayDevice) {
                root.isCharging = (UPower.displayDevice.state === 1)
            }
        }
    }

    Process {
        id: batReader
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity 2>/dev/null; cat /sys/class/power_supply/BAT1/status 2>/dev/null"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n")
                if (lines.length >= 1) {
                    let pct = parseInt(lines[0])
                    if (!isNaN(pct)) root.batteryPct = pct
                }
                if (lines.length >= 2) {
                    root.isCharging = lines[1].toLowerCase().includes("charging")
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

    // Power Profile Reader & Setter
    Process {
        id: profileReader
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let p = data.trim()
                if (p) root.currentProfile = p
            }
        }
    }

    Process { id: profileSetter }

    // Listen for D-Bus changes on power profiles
    Process {
        id: profileDbusWatcher
        command: ["gdbus", "monitor", "--system", "--dest", "net.hadess.PowerProfiles"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                profileRefreshTimer.restart()
            }
        }
    }

    Timer {
        id: profileRefreshTimer
        interval: 100
        repeat: false
        onTriggered: {
            profileReader.running = false
            profileReader.running = true
        }
    }

    function cycleProfile() {
        let next = "balanced"
        if (root.currentProfile === "performance") next = "balanced"
        else if (root.currentProfile === "balanced") next = "power-saver"
        else next = "performance"

        root.currentProfile = next
        profileSetter.exec(["powerprofilesctl", "set", next])
        profileRefreshTimer.restart()
    }

    function getProfileIcon() {
        if (root.currentProfile === "performance") return "\uf135" // Rocket (tên lửa)
        if (root.currentProfile === "power-saver") return "\uf06c"  // Leaf (cái lá)
        return "\uf24e" // Scale (cái cân)
    }

    function getProfileColor() {
        if (root.currentProfile === "performance") return theme.red
        if (root.currentProfile === "power-saver") return theme.green
        return theme.accent
    }

    // -------------------------------------------------------------
    // UI Layout
    // -------------------------------------------------------------
    Column {
        id: col
        anchors.centerIn: parent
        spacing: 4

        // 1. Độ sáng (Brightness)
        Item {
            width: 32
            height: 34
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.bgHover
                opacity: brightMouse.containsMouse ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.brightness > 70 ? "󰃠" : (root.brightness > 30 ? "󰃟" : "󰃞")
                    font.family: theme.fontMono
                    font.pixelSize: 15
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
                id: brightMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) root.stepBrightness("5%+")
                    else root.stepBrightness("5%-")
                }
            }
        }

        // Divider
        Rectangle {
            width: 18
            height: 1
            color: theme.bg
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.8
        }

        // 2. Âm thanh (Audio)
        Item {
            width: 32
            height: 34
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.bgHover
                opacity: audioMouse.containsMouse ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (root.isMuted) return "󰝟"
                        if (root.volume > 50) return "󰕾"
                        if (root.volume > 0) return "󰖀"
                        return "󰕿"
                    }
                    font.family: theme.fontMono
                    font.pixelSize: 15
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
                id: audioMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) root.stepVolume("5%+")
                    else root.stepVolume("5%-")
                }
                onClicked: root.toggleMute()
            }
        }

        // Divider
        Rectangle {
            width: 18
            height: 1
            color: theme.bg
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.8
        }

        // 3. Pin & Power Profile
        Item {
            width: 32
            height: 34
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.bgHover
                opacity: batMouse.containsMouse ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.getProfileIcon()
                    font.family: theme.fontMono
                    font.pixelSize: 15
                    color: root.getProfileColor()

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.batteryPct + "%"
                    font.family: theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: root.isCharging ? theme.green : theme.fg
                }
            }

            MouseArea {
                id: batMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cycleProfile()
            }
        }
    }
}
