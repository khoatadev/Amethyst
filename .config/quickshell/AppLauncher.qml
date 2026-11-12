import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var theme
    property bool isOpen: false

    // animProgress biến thiên từ 0.0 -> 1.0 (mở) hoặc 1.0 -> 0.0 (đóng)
    property real animProgress: 0.0

    // Khi đóng hoàn tất (animProgress == 0 && !isOpen), ẩn window và nhả phím
    visible: isOpen || animProgress > 0.001

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "launcher"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // Hiệu ứng chuyển động nội suy hai đầu (In-Out Easing Interpolation)
    Behavior on animProgress {
        NumberAnimation {
            duration: 240
            easing.type: Easing.InOutCubic
        }
    }

    // Danh sách ứng dụng hệ thống
    property var allApps: []
    property var filteredApps: []
    property int selectedIndex: 0

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.refreshApps();
        }
    }

    Component.onCompleted: {
        root.refreshApps();
    }

    Timer {
        id: retryTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (root.allApps.length === 0) {
                root.refreshApps();
            }
        }
    }

    function refreshApps() {
        if (!DesktopEntries || !DesktopEntries.applications) return;
        let raw = DesktopEntries.applications.values || [];
        if (raw.length === 0) return;

        let list = [];
        for (let i = 0; i < raw.length; i++) {
            let app = raw[i];
            if (!app || app.noDisplay || !app.name || app.name.trim() === "") continue;
            list.push(app);
        }

        // Sắp xếp theo bảng chữ cái A-Z
        list.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));
        allApps = list;
        filterApps();
    }

    function filterApps() {
        let query = (searchInput.text || "").trim().toLowerCase();
        if (!query) {
            filteredApps = allApps;
        } else {
            let direct = [];
            let fuzzy = [];
            for (let i = 0; i < allApps.length; i++) {
                let app = allApps[i];
                let name = (app.name || "").toLowerCase();
                if (name.startsWith(query)) {
                    direct.push(app);
                } else if (name.includes(query)) {
                    fuzzy.push(app);
                }
            }
            filteredApps = direct.concat(fuzzy);
        }
        selectedIndex = 0;
        if (appsList) {
            appsList.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    function selectNext() {
        if (filteredApps.length === 0) return;
        selectedIndex = (selectedIndex + 1) % filteredApps.length;
        appsList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function selectPrevious() {
        if (filteredApps.length === 0) return;
        selectedIndex = (selectedIndex - 1 + filteredApps.length) % filteredApps.length;
        appsList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function launchSelected() {
        if (filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length) {
            let app = filteredApps[selectedIndex];
            if (app && typeof app.execute === "function") {
                app.execute();
            }
            root.close();
        }
    }

    function open() {
        if (allApps.length === 0) {
            refreshApps();
            if (allApps.length === 0) retryTimer.start();
        }
        isOpen = true;
        animProgress = 1.0;
        searchInput.text = "";
        filterApps();
        Qt.callLater(() => {
            searchInput.forceActiveFocus();
        });
    }

    function close() {
        isOpen = false;
        animProgress = 0.0;
    }

    function toggle() {
        if (isOpen) {
            close();
        } else {
            open();
        }
    }

    // 1. Lớp nền mờ (Backdrop Scrim) bao phủ toàn màn hình
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#0f101a"
        opacity: 0.55 * root.animProgress

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // 2. Thẻ Card nổi ở trung tâm với hiệu ứng Scale, Opacity & Translate Y nội suy hai đầu
    Rectangle {
        id: card
        width: 580
        anchors.horizontalCenter: parent.horizontalCenter
        y: (parent.height * 0.20) + ((1.0 - root.animProgress) * -20)

        scale: 0.94 + (0.06 * root.animProgress)
        opacity: root.animProgress

        radius: 14
        color: root.theme ? root.theme.bg : "#222436"
        border.width: 1
        border.color: searchInput.activeFocus ? (root.theme ? root.theme.borderHover : "#444a73") : (root.theme ? root.theme.border : "#2f334d")

        implicitHeight: cardLayout.implicitHeight

        // Chặn sự kiện click xuyên qua card xuống backdrop
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: cardLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            // Header: Thanh tìm kiếm ứng dụng
            Item {
                Layout.fillWidth: true
                implicitHeight: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    // Icon kính lúp tìm kiếm
                    Text {
                        text: ""
                        font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                        font.pixelSize: 15
                        color: root.theme ? root.theme.accent : "#82aaff"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Ô nhập văn bản tìm kiếm
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                            font.pixelSize: 13
                            color: root.theme ? root.theme.fg : "#c8d3f5"
                            selectionColor: root.theme ? root.theme.accent : "#82aaff"
                            selectedTextColor: root.theme ? root.theme.bg : "#222436"
                            clip: true

                            onTextChanged: {
                                root.filterApps();
                            }

                            Keys.onDownPressed: (event) => {
                                event.accepted = true;
                                root.selectNext();
                            }
                            Keys.onUpPressed: (event) => {
                                event.accepted = true;
                                root.selectPrevious();
                            }
                            Keys.onTabPressed: (event) => {
                                event.accepted = true;
                                root.selectNext();
                            }
                            Keys.onBacktabPressed: (event) => {
                                event.accepted = true;
                                root.selectPrevious();
                            }
                            Keys.onReturnPressed: (event) => {
                                event.accepted = true;
                                root.launchSelected();
                            }
                            Keys.onEnterPressed: (event) => {
                                event.accepted = true;
                                root.launchSelected();
                            }
                            Keys.onEscapePressed: (event) => {
                                event.accepted = true;
                                root.close();
                            }
                        }

                        // Placeholder hiển thị khi chưa gõ
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Tìm kiếm ứng dụng..."
                            font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                            font.pixelSize: 13
                            color: root.theme ? root.theme.fgSubtle : "#545c7e"
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                        }
                    }

                    // Badge hiển thị số lượng ứng dụng
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        radius: 6
                        color: root.theme ? root.theme.bgCard : "#262940"
                        border.color: root.theme ? root.theme.border : "#2f334d"
                        border.width: 1
                        implicitWidth: countText.implicitWidth + 14
                        implicitHeight: 22

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: root.filteredApps.length + " apps"
                            font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                            font.pixelSize: 10
                            color: root.theme ? root.theme.fgMuted : "#828bb8"
                        }
                    }
                }
            }

            // Đường kẻ ngăn cách mảnh
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: root.theme ? root.theme.border : "#2f334d"
            }

            // Danh sách ứng dụng dạng cuộn mượt
            Item {
                Layout.fillWidth: true
                implicitHeight: root.filteredApps.length > 0 ? Math.min(352, root.filteredApps.length * 44) : 90

                ListView {
                    id: appsList
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.filteredApps
                    currentIndex: root.selectedIndex

                    // Thanh highlight lướt mượt mà giữa các hàng bằng nội suy hai đầu
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 130
                    highlight: Item {
                        width: appsList.width
                        height: 44

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.topMargin: 2
                            anchors.bottomMargin: 2
                            radius: 8
                            color: root.theme ? root.theme.bgHover : "#2d3f76"
                            border.width: 1
                            border.color: root.theme ? root.theme.borderHover : "#444a73"
                        }
                    }

                    delegate: Item {
                        id: appItem
                        width: appsList.width
                        height: 44

                        readonly property bool isCurrent: index === root.selectedIndex

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            spacing: 14

                            // Icon ứng dụng
                            Item {
                                implicitWidth: 26
                                implicitHeight: 26
                                Layout.alignment: Qt.AlignVCenter

                                Image {
                                    id: iconImg
                                    anchors.fill: parent
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    source: (modelData && modelData.icon) ? Quickshell.iconPath(modelData.icon) : ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰀻"
                                    font.pixelSize: 18
                                    color: root.theme ? root.theme.accent : "#82aaff"
                                    visible: !iconImg.source || iconImg.status === Image.Error || iconImg.status === Image.Null
                                }
                            }

                            // Tên ứng dụng (gọn gàng, không có mô tả theo yêu cầu)
                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: modelData ? modelData.name : ""
                                font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                                font.pixelSize: 12
                                font.weight: appItem.isCurrent ? Font.DemiBold : Font.Normal
                                color: appItem.isCurrent ? "#ffffff" : (root.theme ? root.theme.fg : "#c8d3f5")
                                elide: Text.ElideRight
                            }

                            // Biểu tượng Enter nhỏ ở góc phải mục đang chọn
                            Rectangle {
                                visible: appItem.isCurrent
                                Layout.alignment: Qt.AlignVCenter
                                radius: 4
                                color: Qt.rgba(130/255, 170/255, 255/255, 0.15)
                                border.color: root.theme ? root.theme.borderHover : "#444a73"
                                border.width: 1
                                implicitWidth: enterLabel.implicitWidth + 10
                                implicitHeight: 20

                                Text {
                                    id: enterLabel
                                    anchors.centerIn: parent
                                    text: "↵ Enter"
                                    font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                                    font.pixelSize: 10
                                    color: root.theme ? root.theme.accent : "#82aaff"
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: {
                                if (root.selectedIndex !== index) {
                                    root.selectedIndex = index;
                                }
                            }
                            onClicked: {
                                root.selectedIndex = index;
                                root.launchSelected();
                            }
                        }
                    }
                }

                // Giao diện khi không có kết quả tìm kiếm
                Item {
                    anchors.fill: parent
                    visible: root.filteredApps.length === 0

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: ""
                            font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                            font.pixelSize: 16
                            color: root.theme ? root.theme.fgMuted : "#828bb8"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "Không tìm thấy ứng dụng phù hợp"
                            font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                            font.pixelSize: 12
                            color: root.theme ? root.theme.fgMuted : "#828bb8"
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }

            // Đường kẻ chân trang
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: root.theme ? root.theme.border : "#2f334d"
            }

            // Footer hướng dẫn phím tắt
            Item {
                Layout.fillWidth: true
                implicitHeight: 30

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: "↑↓ di chuyển  •  ↵ mở  •  Esc đóng"
                        font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                        font.pixelSize: 10
                        color: root.theme ? root.theme.fgSubtle : "#545c7e"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Quickshell Launcher"
                        font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                        font.pixelSize: 10
                        color: root.theme ? root.theme.fgSubtle : "#545c7e"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
