import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Networking

// =============================================================================
// Wifi Menu — "Wifi Island" mọc ra từ mép trái màn hình, ngang cụm Controls
// - Cửa sổ full-screen overlay như WallpaperMenu: đảo đen mọc từ mép trái,
//   căn giữa chiều cao màn hình, bo hai góc phải + góc lõm nối vào bar
// - Danh sách mạng quét live qua Quickshell.Networking (NetworkManager):
//   icon sóng theo cường độ, khóa cho mạng có mật khẩu, chấm xanh pulse +
//   viền active cho mạng đang dùng
// - Mạng đã lưu (known) kết nối 1 click; mạng lạ có mật khẩu mở ô nhập
//   password ngay dưới dòng đó — Enter để connectWithPsk()
// - Pill bật/tắt wifi ở header (Networking.wifiEnabled)
// =============================================================================

PanelWindow {
    id: root

    property var theme
    property bool isOpen: false

    // Y tâm cụm Controls trên màn hình — đảo mọc ra đúng kế cạnh capsule
    // (shell.qml cập nhật giá trị này mỗi lần trước khi mở)
    property real anchorY: 0

    // ---- Thông số giao diện ----
    readonly property int headerHeight: 48
    readonly property int rowHeight: 44
    readonly property int maxRows: 9
    readonly property int listPadding: 8
    readonly property int menuWidth: 380
    readonly property int cornerRadius: 24     // bo hai góc phải
    // Nền đảo khớp màu bar (Tokyo Night) thay vì đen thuần
    readonly property color islandColor: theme ? theme.bgDark : "#1e2030"
    readonly property string fontFamily: theme ? theme.fontMono : "ComicShannsMono Nerd Font"

    // ---- Kích thước đảo hiện tại (được animate) ----
    property real islandW: 0
    property real islandH: 380

    readonly property real listTargetHeight: {
        if (!wifiDevice || !wifiDevice.networks) return 48;
        let n = sortedNetworks.length;
        if (n === 0) return 48;
        return Math.min(n, maxRows) * rowHeight + listPadding * 2;
    }
    readonly property real targetH: headerHeight + listTargetHeight + 22
    readonly property real targetW: isOpen ? menuWidth : 0

    onTargetHChanged: islandH = targetH
    onTargetWChanged: islandW = targetW

    // Spring nảy nhẹ khi phình ra, co gọn mượt khi đóng
    Behavior on islandH {
        NumberAnimation {
            duration: root.isOpen ? 520 : 300
            easing.type: root.isOpen ? Easing.OutBack : Easing.InOutCubic
            easing.overshoot: 1.1
        }
    }
    Behavior on islandW {
        NumberAnimation {
            duration: root.isOpen ? 560 : 320
            easing.type: root.isOpen ? Easing.OutBack : Easing.InOutCubic
            easing.overshoot: 0.6
        }
    }

    visible: isOpen || islandW > 0.5
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "wifimenu"
    exclusionMode: ExclusionMode.Ignore

    // Full-screen overlay như WallpaperMenu — đảo bên trong tự anchor
    anchors { top: true; bottom: true; left: true; right: true }

    // =========================================================================
    // Dữ liệu wifi qua Quickshell.Networking (NetworkManager backend)
    // =========================================================================

    // Lấy thiết bị wifi đầu tiên từ Networking.devices
    readonly property var wifiDevice: {
        let devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i] && devs[i].type === DeviceType.Wifi) return devs[i];
        }
        return null;
    }

    // Bật scanner khi menu mở để quét live (tắt khi đóng để tiết kiệm pin)
    onIsOpenChanged: {
        if (wifiDevice) wifiDevice.scannerEnabled = isOpen;
        if (isOpen) {
            refreshNetworks();
            Qt.callLater(() => keyHandler.forceActiveFocus());
        }
    }

    // Sắp xếp: đang kết nối lên đầu, rồi theo tín hiệu giảm dần
    // Lưu ý: signalStrength của NM trả về thang 0.0–1.0
    property var sortedNetworks: []

    function refreshNetworks() {
        if (!wifiDevice || !wifiDevice.networks) {
            sortedNetworks = [];
            return;
        }
        let nets = wifiDevice.networks.values.slice();
        nets.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            return b.signalStrength - a.signalStrength;
        });
        sortedNetworks = nets;
    }

    // Cập nhật lại khi danh sách mạng hoặc trạng thái kết nối thay đổi
    Connections {
        target: wifiDevice ? wifiDevice.networks : null
        function onValuesChanged() { refreshNetworks(); }
    }
    Connections {
        target: wifiDevice
        function onConnectedChanged() { refreshNetworks(); }
    }

    Component.onCompleted: refreshNetworks()

    // Mạng đang chờ nhập password (object WifiNetwork)
    property var pendingNetwork: null
    // Password đang gõ (bind 2 chiều với ô nhập trong delegate)
    property string pendingPassword: ""

    // Đóng menu khi click ra ngoài
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // =========================================================================
    // Kết nối / ngắt kết nối
    // =========================================================================

    function requestConnect(net) {
        if (net.known || net.security === WifiSecurityType.Open) {
            net.connect();
        } else {
            // Mạng lạ có mật khẩu → mở ô nhập password
            pendingNetwork = net;
        }
    }

    function submitPassword() {
        if (pendingNetwork && pendingPassword.length > 0) {
            pendingNetwork.connectWithPsk(pendingPassword);
        }
        pendingNetwork = null;
        pendingPassword = "";
    }

    function cancelPassword() {
        pendingNetwork = null;
        pendingPassword = "";
    }

    function open() {
        isOpen = true;
    }

    function close() {
        isOpen = false;
        cancelPassword();
    }

    function toggle() {
        isOpen ? close() : open();
    }

    // =========================================================================
    // Icon sóng theo cường độ tín hiệu (Nerd Font)
    // signalStrength của NetworkManager trả về thang 0.0–1.0
    // =========================================================================
    function signalIcon(strength) {
        if (strength >= 0.80) return "󰤨";
        if (strength >= 0.60) return "󰤥";
        if (strength >= 0.40) return "󰤢";
        if (strength >= 0.20) return "󰤟";
        return "󰤯";
    }

    // =========================================================================
    // Đảo (Island) mọc từ mép phải của bar (x = barWidth), kế cạnh cụm
    // Controls — không shadow, nhìn như mọc thẳng ra từ thân bar
    // =========================================================================
    Item {
        id: islandRoot
        // Đảo bắt đầu ngay sau mép bar 54px, căn giữa theo Y tâm capsule
        readonly property int barWidth: 54
        x: barWidth
        y: root.anchorY > 0 ? root.anchorY - height / 2 : 0
        width: Math.max(0, root.islandW)
        height: Math.max(0, root.islandH)

        // Thân đảo: cạnh trái phẳng dính sát mép phải bar, chỉ bo 2 góc phải
        // (không kéo dài sang trái — không đè lên capsule trong bar)
        Rectangle {
            id: island
            x: 0
            y: 0
            width: parent.width
            height: parent.height
            radius: root.cornerRadius
            color: root.islandColor

            MouseArea { anchors.fill: parent }
        }

        // ---------------- Nội dung đảo ----------------
        Item {
            id: content
            anchors.fill: parent
            clip: true
            opacity: Math.max(0, Math.min(1, (root.islandW - 100) / 160))

            // ---------- Header: tiêu đề + pill bật/tắt wifi ----------
            Item {
                id: header
                anchors.top: parent.top
                anchors.topMargin: 12
                width: parent.width
                height: root.headerHeight

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰤨  wi-fi"
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    color: root.theme ? root.theme.fg : "#c8d3f5"
                }

                // Pill bật/tắt wifi (Networking.wifiEnabled)
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    width: pillText.implicitWidth + 34
                    height: 28
                    radius: 14
                    color: Networking.wifiEnabled
                           ? Qt.rgba(1, 1, 1, 0.10)
                           : Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: Networking.wifiEnabled
                                   ? (root.theme ? root.theme.borderActive : "#82aaff")
                                   : (root.theme ? root.theme.borderHover : "#444a73")

                    // Chấm trạng thái
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8; height: 8
                        radius: 4
                        color: Networking.wifiEnabled
                               ? (root.theme ? root.theme.green : "#c3e88d")
                               : (root.theme ? root.theme.fgSubtle : "#545c7e")
                    }

                    Text {
                        id: pillText
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: Networking.wifiEnabled ? "on" : "off"
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        color: Networking.wifiEnabled
                               ? (root.theme ? root.theme.fg : "#c8d3f5")
                               : (root.theme ? root.theme.fgMuted : "#828bb8")
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            // ---------- Danh sách mạng ----------
            ListView {
                id: networkList
                anchors.top: header.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 2
                implicitHeight: contentHeight
                model: root.sortedNetworks.length

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Item {
                    id: netRow
                    required property int index
                    readonly property var net: root.sortedNetworks[netRow.index] || null
                    readonly property bool isCurrent: net ? net.connected : false
                    readonly property bool isPending: net && root.pendingNetwork === net
                    property bool hovered: false

                    width: networkList.width
                    height: root.rowHeight + (isPending ? 40 : 0)

                    // Nền dòng: hover + đang kết nối
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: netRow.isCurrent
                               ? Qt.rgba(1, 1, 1, 0.06)
                               : (netRow.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                        border.width: 1
                        border.color: netRow.isCurrent
                                      ? (root.theme ? root.theme.borderActive : "#82aaff")
                                      : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: netRow.hovered = hovered
                        onClicked: {
                            if (!netRow.net) return;
                            if (netRow.isCurrent) {
                                // Đang dùng → click lần nữa để ngắt
                                netRow.net.disconnect();
                            } else {
                                root.requestConnect(netRow.net);
                            }
                        }
                    }

                    // Icon sóng theo cường độ
                    Text {
                        id: signalIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: netRow.net ? root.signalIcon(netRow.net.signalStrength) : ""
                        font.family: root.fontFamily
                        font.pixelSize: 16
                        color: netRow.isCurrent
                               ? (root.theme ? root.theme.accent : "#82aaff")
                               : (root.theme ? root.theme.fg : "#c8d3f5")
                    }

                    // Tên mạng
                    Text {
                        anchors.left: signalIcon.right
                        anchors.leftMargin: 12
                        anchors.right: lockIcon.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: netRow.net ? netRow.net.name : ""
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        color: netRow.isCurrent
                               ? (root.theme ? root.theme.fg : "#c8d3f5")
                               : (root.theme ? root.theme.fgMuted : "#828bb8")
                        elide: Text.ElideRight
                    }

                    // Khóa cho mạng có mật khẩu
                    Text {
                        id: lockIcon
                        anchors.right: parent.right
                        anchors.rightMargin: netRow.isCurrent ? 40 : 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰌾"
                        visible: netRow.net && netRow.net.security !== WifiSecurityType.Open
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        color: root.theme ? root.theme.fgSubtle : "#545c7e"
                    }

                    // Chấm xanh pulse: mạng đang dùng
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10; height: 10
                        radius: 5
                        visible: netRow.isCurrent
                        color: root.theme ? root.theme.green : "#c3e88d"
                        border.width: 2
                        border.color: Qt.rgba(0, 0, 0, 0.4)

                        SequentialAnimation on scale {
                            running: netRow.isCurrent
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 1.5; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.5; to: 1; duration: 900; easing.type: Easing.InOutSine }
                        }
                    }

                    // Ô nhập password cho mạng lạ (mở dưới dòng)
                    Rectangle {
                        id: passwordBox
                        visible: netRow.isPending
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: signalIcon.bottom
                        anchors.topMargin: 6
                        height: 32
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: root.theme ? root.theme.borderActive : "#82aaff"

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.margins: 8
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            color: root.theme ? root.theme.fg : "#c8d3f5"
                            echoMode: TextInput.Password
                            clip: true
                            passwordCharacter: "•"
                            text: root.pendingPassword
                            onTextEdited: root.pendingPassword = text

                            onAccepted: root.submitPassword()
                            Keys.onEscapePressed: (event) => {
                                root.cancelPassword();
                                event.accepted = true;
                            }

                            // Tự focus khi ô password hiện ra
                            onVisibleChanged: {
                                if (visible) passwordInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Dòng trống khi không có mạng / wifi tắt
            Text {
                anchors.centerIn: networkList
                visible: root.sortedNetworks.length === 0
                text: Networking.wifiEnabled ? "đang quét..." : "wifi đang tắt"
                font.family: root.fontFamily
                font.pixelSize: 12
                color: root.theme ? root.theme.fgSubtle : "#545c7e"
            }

            // ---------- Bắt phím khi menu mở ----------
            Item {
                id: keyHandler
                anchors.fill: parent
                focus: false

                Keys.onEscapePressed: (event) => {
                    if (root.pendingNetwork) {
                        root.cancelPassword();
                    } else {
                        root.close();
                    }
                    event.accepted = true;
                }
            }
        }
    }
}
