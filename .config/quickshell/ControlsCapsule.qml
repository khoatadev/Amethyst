import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Networking

Rectangle {
    id: root

    Theme { id: theme }

    // Click nút wifi trên capsule → shell.qml bắt signal này để mở WifiMenu
    signal wifiClicked()

    width: 42
    height: col.implicitHeight + 16
    radius: width / 2
    color: theme.bgDark
    border.width: 1
    border.color: theme.border

    // -------------------------------------------------------------
    // Wifi Logic — trạng thái wifi qua Quickshell.Networking (NM)
    // -------------------------------------------------------------
    property var wifiDevice: {
        let devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i] && devs[i].type === DeviceType.Wifi) return devs[i];
        }
        return null;
    }

    // Trạng thái kết nối lấy từ device (đáng tin hơn từng network object —
    // network.connected không luôn bắn notify khi NM active connection đổi)
    readonly property bool wifiConnected: wifiDevice
        ? (wifiDevice.connected || wifiDevice.state === ConnectionState.Connected)
        : false

    // Mạng đang kết nối (để lấy mức sóng) — cập nhật thủ công qua refresh,
    // binding var không tự đánh lại khi property của phần tử trong list đổi
    property var currentNetwork: null

    function refreshWifiState() {
        let net = null
        if (wifiDevice && wifiDevice.networks) {
            let nets = wifiDevice.networks.values
            for (let i = 0; i < nets.length; i++) {
                if (nets[i] && nets[i].connected) { net = nets[i]; break }
            }
        }
        currentNetwork = net
    }

    Connections {
        target: wifiDevice
        function onConnectedChanged() { root.refreshWifiState() }
        function onStateChanged() { root.refreshWifiState() }
    }
    Connections {
        target: wifiDevice ? wifiDevice.networks : null
        function onValuesChanged() { root.refreshWifiState() }
    }
    Component.onCompleted: refreshWifiState()

    // Cường độ sóng hiện tại (0.0–1.0 như NM trả về; 0 nếu không có network)
    readonly property real wifiSignal: currentNetwork ? currentNetwork.signalStrength : 0

    // Icon đổi theo trạng thái + mức sóng (Nerd Font, sóng thang 0.0–1.0)
    function wifiIcon() {
        if (!Networking.wifiEnabled) return "󰤭";
        if (!root.wifiConnected) return "󰤭";
        if (root.wifiSignal >= 0.80) return "󰤨";
        if (root.wifiSignal >= 0.60) return "󰤥";
        if (root.wifiSignal >= 0.40) return "󰤢";
        if (root.wifiSignal >= 0.20) return "󰤟";
        return "󰤯";
    }

    // Tâm capsule trên màn hình — để shell neo menu wifi mọc ra kế cạnh
    function getScreenY() {
        return root.mapToItem(null, root.width / 2, root.height / 2).y
    }

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
    // Low battery state
    // -------------------------------------------------------------
    readonly property bool lowBattery: batteryPct < 20 && !isCharging

    // -------------------------------------------------------------
    // UI Layout
    // -------------------------------------------------------------
    Column {
        id: col
        anchors.centerIn: parent
        spacing: 4

        // 0. Wifi — mọc lên trên cụm brightness, click mở WifiMenu
        Item {
            id: wifiBtn
            width: 34
            height: 36
            anchors.horizontalCenter: parent.horizontalCenter

            property real iconScale: 1.0
            property color ringColor: theme.accent
            property real ringValue: root.wifiSignal   // thang 0.0–1.0

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.bgHover
                opacity: wifiMouse.containsMouse ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: theme.durFast } }
            }

            // Vòng cung tín hiệu sóng (hiện khi hover)
            Canvas {
                id: wifiRing
                anchors.fill: parent
                opacity: wifiMouse.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.reset()
                    let cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - 2
                    ctx.strokeStyle = theme.border
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.stroke()
                    if (wifiBtn.ringValue > 0) {
                        ctx.strokeStyle = wifiBtn.ringColor
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        let start = -Math.PI / 2
                        ctx.arc(cx, cy, r, start, start + Math.PI * 2 * wifiBtn.ringValue)
                        ctx.stroke()
                    }
                }
                Connections {
                    target: wifiBtn
                    function onRingValueChanged() { wifiRing.requestPaint() }
                }
            }

            // Ripple khi click
            RippleEffect {
                id: wifiRipple
                anchors.fill: parent
                clip: true
                rippleColor: theme.accentGlow
            }

            Column {
                anchors.centerIn: parent
                spacing: 2
                scale: wifiBtn.iconScale
                Behavior on scale {
                    NumberAnimation { duration: theme.durMed; easing.type: Easing.OutBack }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.wifiIcon()
                    font.family: theme.fontMono
                    font.pixelSize: 16
                    color: root.wifiConnected ? theme.accent : theme.fgMuted
                    Behavior on color { ColorAnimation { duration: theme.durFast } }
                }
            }

            // Bounce khi trạng thái kết nối / sóng đổi
            Connections {
                target: root
                function onWifiSignalChanged() {
                    wifiBtn.iconScale = 1.12
                    wifiBounceAnim.restart()
                }
                function onWifiConnectedChanged() {
                    wifiBtn.iconScale = 1.12
                    wifiBounceAnim.restart()
                }
            }
            NumberAnimation {
                id: wifiBounceAnim
                target: wifiBtn
                property: "iconScale"
                to: 1.0
                duration: 250
                easing.type: Easing.OutBack
            }

            MouseArea {
                id: wifiMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    wifiRipple.trigger(wifiMouse)
                    root.wifiClicked()
                }
            }
        }

        // Divider
        Rectangle {
            width: 22
            height: 1
            color: theme.borderHover
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.8
        }

        // 1. Độ sáng (Brightness)
        Item {
            id: brightBtn
            width: 34
            height: 36
            anchors.horizontalCenter: parent.horizontalCenter

            property real iconScale: 1.0
            property color ringColor: theme.yellow
            property real ringValue: root.brightness / 100

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.bgHover
                opacity: brightMouse.containsMouse ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: theme.durFast } }
            }

            // Vòng cung tiến độ (hiện khi hover)
            Canvas {
                id: brightRing
                anchors.fill: parent
                opacity: brightMouse.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.reset()
                    let cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - 2
                    ctx.strokeStyle = theme.border
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.stroke()
                    if (brightBtn.ringValue > 0) {
                        ctx.strokeStyle = brightBtn.ringColor
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        let start = -Math.PI / 2
                        ctx.arc(cx, cy, r, start, start + Math.PI * 2 * brightBtn.ringValue)
                        ctx.stroke()
                    }
                }
                Connections {
                    target: brightBtn
                    function onRingValueChanged() { brightRing.requestPaint() }
                }
            }

            // Ripple khi click
            RippleEffect {
                id: brightRipple
                anchors.fill: parent
                clip: true
                rippleColor: theme.glowYellow
            }

            Column {
                anchors.centerIn: parent
                spacing: 2
                scale: brightBtn.iconScale
                Behavior on scale {
                    NumberAnimation { duration: theme.durMed; easing.type: Easing.OutBack }
                }

                Text {
                    id: brightIcon
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

            // Bounce khi giá trị đổi
            Connections {
                target: root
                function onBrightnessChanged() {
                    brightBtn.iconScale = 1.12
                    brightBounceAnim.restart()
                }
            }
            NumberAnimation {
                id: brightBounceAnim
                target: brightBtn
                property: "iconScale"
                to: 1.0
                duration: 250
                easing.type: Easing.OutBack
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
                onClicked: brightRipple.trigger(brightMouse)
            }
        }

        // Divider
        Rectangle {
            width: 22
            height: 1
            color: theme.borderHover
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.8
        }

        // 2. Âm thanh (Audio)
        Item {
            id: audioBtn
            width: 34
            height: 36
            anchors.horizontalCenter: parent.horizontalCenter

            property real iconScale: 1.0
            property real ringValue: root.volume / 100

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.bgHover
                opacity: audioMouse.containsMouse ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: theme.durFast } }
            }

            // Glow đỏ pulse khi mute
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.glowRed
                visible: root.isMuted
                SequentialAnimation on opacity {
                    running: root.isMuted
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.3; to: 0.7; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.7; to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                }
            }

            Canvas {
                id: audioRing
                anchors.fill: parent
                opacity: audioMouse.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.reset()
                    let cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - 2
                    ctx.strokeStyle = theme.border
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.stroke()
                    if (audioBtn.ringValue > 0) {
                        ctx.strokeStyle = root.isMuted ? theme.red : theme.accent
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        let start = -Math.PI / 2
                        ctx.arc(cx, cy, r, start, start + Math.PI * 2 * audioBtn.ringValue)
                        ctx.stroke()
                    }
                }
                Connections {
                    target: audioBtn
                    function onRingValueChanged() { audioRing.requestPaint() }
                }
            }

            RippleEffect {
                id: audioRipple
                anchors.fill: parent
                clip: true
                rippleColor: theme.accentGlow
            }

            Column {
                anchors.centerIn: parent
                spacing: 2
                scale: audioBtn.iconScale
                Behavior on scale {
                    NumberAnimation { duration: theme.durMed; easing.type: Easing.OutBack }
                }

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
                    Behavior on color { ColorAnimation { duration: theme.durFast } }
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

            Connections {
                target: root
                function onVolumeChanged() {
                    audioBtn.iconScale = 1.12
                    audioBounceAnim.restart()
                }
                function onIsMutedChanged() {
                    audioBtn.iconScale = 1.12
                    audioBounceAnim.restart()
                }
            }
            NumberAnimation {
                id: audioBounceAnim
                target: audioBtn
                property: "iconScale"
                to: 1.0
                duration: 250
                easing.type: Easing.OutBack
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
                onClicked: {
                    audioRipple.trigger(audioMouse)
                    root.toggleMute()
                }
            }
        }

        // Divider
        Rectangle {
            width: 22
            height: 1
            color: theme.borderHover
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.8
        }

        // 3. Pin & Power Profile
        Item {
            id: batBtn
            width: 34
            height: 36
            anchors.horizontalCenter: parent.horizontalCenter

            property real iconScale: 1.0
            property real ringValue: root.batteryPct / 100

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.bgHover
                opacity: batMouse.containsMouse ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: theme.durFast } }
            }

            // Glow đỏ pulse khi pin yếu
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.glowRed
                visible: root.lowBattery
                SequentialAnimation on opacity {
                    running: root.lowBattery
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.3; to: 0.7; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.7; to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                }
            }

            Canvas {
                id: batRing
                anchors.fill: parent
                opacity: batMouse.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                onPaint: {
                    let ctx = getContext("2d")
                    ctx.reset()
                    let cx = width / 2, cy = height / 2, r = Math.min(width, height) / 2 - 2
                    ctx.strokeStyle = theme.border
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.stroke()
                    if (batBtn.ringValue > 0) {
                        ctx.strokeStyle = root.isCharging ? theme.green : (root.batteryPct > 20 ? root.getProfileColor() : theme.red)
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        let start = -Math.PI / 2
                        ctx.arc(cx, cy, r, start, start + Math.PI * 2 * batBtn.ringValue)
                        ctx.stroke()
                    }
                }
                Connections {
                    target: batBtn
                    function onRingValueChanged() { batRing.requestPaint() }
                }
            }

            RippleEffect {
                id: batRipple
                anchors.fill: parent
                clip: true
                rippleColor: theme.accentGlow
            }

            Column {
                anchors.centerIn: parent
                spacing: 2
                scale: batBtn.iconScale
                Behavior on scale {
                    NumberAnimation { duration: theme.durMed; easing.type: Easing.OutBack }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.getProfileIcon()
                    font.family: theme.fontMono
                    font.pixelSize: 16
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

            Connections {
                target: root
                function onBatteryPctChanged() {
                    batBtn.iconScale = 1.12
                    batBounceAnim.restart()
                }
                function onCurrentProfileChanged() {
                    batBtn.iconScale = 1.12
                    batBounceAnim.restart()
                }
            }
            NumberAnimation {
                id: batBounceAnim
                target: batBtn
                property: "iconScale"
                to: 1.0
                duration: 250
                easing.type: Easing.OutBack
            }

            MouseArea {
                id: batMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    batRipple.trigger(batMouse)
                    root.cycleProfile()
                }
            }
        }
    }
}
