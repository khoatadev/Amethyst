import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var theme
    property bool isOpen: false

    // animProgress nội suy từ 0.0 -> 1.0 (mở) hoặc 1.0 -> 0.0 (đóng)
    property real animProgress: 0.0

    // Khi đóng hoàn tất, ẩn hẳn window và nhả bàn phím
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

    // Hiệu ứng mở/đóng thẻ card nội suy hai đầu (In-Out Easing)
    Behavior on animProgress {
        NumberAnimation {
            duration: 230
            easing.type: Easing.InOutCubic
        }
    }

    // =========================================================================
    // Dữ liệu ứng dụng & Tìm kiếm
    // =========================================================================
    property var allApps: []
    property var filteredApps: []
    property int selectedIndex: 0

    // =========================================================================
    // Hiệu ứng Kitty Cursor Trail (Leading & Trailing Edge Interpolation)
    // =========================================================================
    // mainY: Đầu dẫn đường di chuyển nhanh trước với đường cong InOutCubic
    // trailY: Vệt đuôi trôi theo sau với độ trễ êm ái
    property real mainY: 2
    property real trailY: 2

    Behavior on mainY {
        NumberAnimation {
            duration: 160
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on trailY {
        NumberAnimation {
            duration: 260
            easing.type: Easing.InOutCubic
        }
    }

    onSelectedIndexChanged: {
        updateCursorPosition();
    }

    function updateCursorPosition() {
        let target = selectedIndex * 42 + 2;
        mainY = target;
        trailY = target;
    }

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
        interval: 250
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
        mainY = 2;
        trailY = 2;
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
        selectedIndex = 0;
        mainY = 2;
        trailY = 2;
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

    // 1. Nền mờ tối giản đen tuyền toàn màn hình (Black Scrim Backdrop)
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#000000"
        opacity: 0.72 * root.animProgress

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // 2. Thẻ Card nổi ở trung tâm — Phong cách tối giản nền đen sâu thẳm
    Rectangle {
        id: card
        width: 540
        anchors.horizontalCenter: parent.horizontalCenter
        y: (parent.height * 0.22) + ((1.0 - root.animProgress) * -18)

        scale: 0.95 + (0.05 * root.animProgress)
        opacity: root.animProgress

        radius: 12
        color: "#050508" // Nền đen tuyền sâu thẳm, tinh tế
        border.width: 1
        border.color: searchInput.activeFocus ? "#2d334d" : "#161722"

        implicitHeight: cardLayout.implicitHeight

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: cardLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            // Header tìm kiếm tối giản (Clean Search Bar)
            Item {
                Layout.fillWidth: true
                implicitHeight: 48

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: ""
                        font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                        font.pixelSize: 14
                        color: "#82aaff"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                            font.pixelSize: 13
                            color: "#ffffff"
                            selectionColor: "#82aaff"
                            selectedTextColor: "#050508"
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

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Tìm kiếm ứng dụng..."
                            font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                            font.pixelSize: 13
                            color: "#3b4261"
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                        }
                    }
                }
            }

            // Đường chia hairline siêu mảnh tối giản
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: "#12131c"
            }

            // Danh sách ứng dụng có vệt Kitty Cursor Trail trượt mượt mà
            Item {
                Layout.fillWidth: true
                implicitHeight: root.filteredApps.length > 0 ? Math.min(336, root.filteredApps.length * 42 + 8) : 80
                clip: true

                // =============================================================
                // HIỆU ỨNG VỆT CON TRỎ KITTY (Kitty Cursor Trail)
                // Co dãn (Squash & Stretch) nội suy hai đầu khi trượt giữa các dòng
                // =============================================================
                Item {
                    id: cursorTrail
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    visible: root.filteredApps.length > 0

                    // Vị trí và chiều cao tự động co dãn theo độ trễ giữa mainY và trailY
                    y: Math.min(root.mainY, root.trailY) - appsList.contentY + 4
                    height: Math.abs(root.mainY - root.trailY) + 36

                    // 1. Thanh chọn chính (Dark Pill)
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "#141520"
                        border.width: 1
                        border.color: "#282a3c"
                    }

                    // 2. Vệt sáng sao băng bừng sáng khi di chuyển (Trail Glow)
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "#82aaff"
                        opacity: Math.min(0.25, Math.abs(root.mainY - root.trailY) / 50)
                    }
                }

                // Danh sách ứng dụng nằm phía trên con trỏ trượt
                ListView {
                    id: appsList
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.filteredApps
                    currentIndex: root.selectedIndex

                    // Tắt highlight mặc định của ListView để dùng hiệu ứng Kitty Cursor Trail bên dưới
                    highlight: null

                    delegate: Item {
                        id: appItem
                        width: appsList.width
                        height: 42

                        readonly property bool isCurrent: index === root.selectedIndex

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            // Icon ứng dụng
                            Item {
                                implicitWidth: 24
                                implicitHeight: 24
                                Layout.alignment: Qt.AlignVCenter

                                Image {
                                    id: iconImg
                                    anchors.fill: parent
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    opacity: appItem.isCurrent ? 1.0 : 0.75
                                    source: (modelData && modelData.icon) ? Quickshell.iconPath(modelData.icon) : ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰀻"
                                    font.pixelSize: 16
                                    color: "#82aaff"
                                    visible: !iconImg.source || iconImg.status === Image.Error || iconImg.status === Image.Null
                                }
                            }

                            // Tên ứng dụng (tối giản, không có mô tả)
                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: modelData ? modelData.name : ""
                                font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                                font.pixelSize: 12
                                font.weight: appItem.isCurrent ? Font.Medium : Font.Normal
                                color: appItem.isCurrent ? "#ffffff" : "#727796"
                                elide: Text.ElideRight
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

                // Trạng thái trống khi không tìm thấy ứng dụng
                Item {
                    anchors.fill: parent
                    visible: root.filteredApps.length === 0

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: ""
                            font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                            font.pixelSize: 14
                            color: "#414868"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "Không tìm thấy ứng dụng phù hợp"
                            font.family: root.theme ? root.theme.fontMono : "ComicShannsMono Nerd Font"
                            font.pixelSize: 12
                            color: "#414868"
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }

            // Khoảng trống chân trang tinh tế
            Item {
                Layout.fillWidth: true
                implicitHeight: 6
            }
        }
    }
}
