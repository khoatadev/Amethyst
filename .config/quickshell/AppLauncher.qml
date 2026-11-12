import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

// =============================================================================
// App Launcher kiểu Dynamic Island mọc lên từ mép dưới màn hình
// - Ấn Super+D: một viên nhỏ mọc lên từ giữa mép dưới rồi phình to thành launcher
//   (spring nảy nhẹ), đóng thì co lại và biến mất vào mép dưới màn hình
// - Đảo dính liền mép dưới, hai góc dưới hoà vào viền bằng góc lõm, bo hai góc trên
// - Thanh chọn màu trắng, trượt theo kiểu "cursor trail" của kitty:
//   cạnh dẫn đầu (theo hướng di chuyển) chạy nhanh, cạnh đuôi đuổi theo chậm hơn
//   nên thanh bị kéo dãn ra rồi co lại khi tới nơi
// =============================================================================
PanelWindow {
    id: root

    property var theme
    property bool isOpen: false

    // ---- Thông số giao diện ----
    readonly property int openWidth: 600
    readonly property int closedWidth: 130
    readonly property int searchHeight: 54
    readonly property int rowHeight: 42
    readonly property int maxRows: 8
    readonly property int listPadding: 8
    readonly property int cornerRadius: 24     // bo hai góc dưới
    readonly property int filletRadius: 14     // góc lõm nối với mép màn hình
    readonly property color islandColor: "#000000"
    readonly property string fontFamily: theme ? theme.fontMono : "ComicShannsMono Nerd Font"

    // ---- Thông số cursor trail (mô phỏng cursor_trail_decay 0.1 0.4 của kitty) ----
    readonly property int trailFast: 110       // cạnh dẫn đầu
    readonly property int trailSlow: 320       // cạnh đuôi

    // ---- Kích thước đảo hiện tại (được animate) ----
    property real islandW: closedWidth
    property real islandH: 0

    readonly property real resultsTargetHeight: {
        if (!showResults) return 0;
        if (filteredApps.length === 0) return 48;
        return Math.min(filteredApps.length, maxRows) * rowHeight + listPadding * 2;
    }
    readonly property real targetH: isOpen ? searchHeight + resultsTargetHeight : 0
    readonly property real targetW: isOpen ? openWidth : closedWidth

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
            easing.overshoot: 0.9
        }
    }

    visible: isOpen || islandH > 0.5
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "launcher"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // =========================================================================
    // Dữ liệu & tìm kiếm
    // =========================================================================
    property var allApps: []
    property var filteredApps: []
    property bool showResults: false
    property int sel: 0

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.refreshApps();
        }
    }

    Component.onCompleted: refreshApps()

    function refreshApps() {
        if (!DesktopEntries || !DesktopEntries.applications) return;
        let raw = DesktopEntries.applications.values || [];
        let list = [];
        for (let i = 0; i < raw.length; i++) {
            let app = raw[i];
            if (!app || app.noDisplay || !app.name || app.name.trim() === "") continue;
            list.push(app);
        }
        list.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" }));
        allApps = list;
        if (showResults) filterApps();
    }

    // Chấm điểm: khớp đầu tên > khớp đầu từ > chứa chuỗi > khớp mờ theo thứ tự ký tự
    function score(name, q) {
        if (name.startsWith(q)) return 400 - name.length;
        let words = name.split(/[\s\-_.]+/);
        for (let w of words) {
            if (w.startsWith(q)) return 300 - name.length;
        }
        if (name.includes(q)) return 200 - name.length;
        let j = 0;
        for (let i = 0; i < name.length && j < q.length; i++) {
            if (name[i] === q[j]) j++;
        }
        return j === q.length ? 100 - name.length : -1;
    }

    function filterApps() {
        let q = searchInput.text.trim().toLowerCase();
        if (q === "") {
            // Giữ danh sách cũ để nội dung không biến mất đột ngột khi thu lại
            showResults = false;
            return;
        }
        let scored = [];
        for (let app of allApps) {
            let s = score(app.name.toLowerCase(), q);
            if (s >= 0) scored.push({ app: app, s: s });
        }
        scored.sort((a, b) => b.s - a.s);
        filteredApps = scored.map(x => x.app);
        showResults = true;
        appsList.contentY = 0;
        select(0, true);
    }

    // ---- Chọn mục + kích hoạt hiệu ứng trail ----
    function select(idx, instant) {
        let n = filteredApps.length;
        if (n === 0) return;
        idx = ((idx % n) + n) % n;
        let newTop = idx * rowHeight;
        trail.movingDown = newTop >= trail.topEdge;
        trail.instant = instant === true;
        sel = idx;
        trail.topEdge = newTop;
        trail.bottomEdge = newTop + rowHeight;
        trail.instant = false;
        ensureVisible(idx);
    }

    // Cuộn mượt để mục đang chọn luôn nằm trong khung
    function ensureVisible(idx) {
        let top = idx * rowHeight;
        let bottom = top + rowHeight;
        let target = appsList.contentY;
        if (top < target) target = top;
        else if (bottom > target + appsList.height) target = bottom - appsList.height;
        if (target === appsList.contentY) return;
        scrollAnim.stop();
        scrollAnim.to = target;
        scrollAnim.start();
    }

    function launchSelected() {
        if (!showResults || filteredApps.length === 0) return;
        let app = filteredApps[sel];
        if (app) app.execute();
        close();
    }

    function open() {
        if (allApps.length === 0) refreshApps();
        searchInput.text = "";
        showResults = false;
        isOpen = true;
        Qt.callLater(() => searchInput.forceActiveFocus());
    }

    function close() {
        isOpen = false;
    }

    function toggle() {
        isOpen ? close() : open();
    }

    // =========================================================================
    // Click ra ngoài để đóng
    // =========================================================================
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // =========================================================================
    // Đảo (Island) mọc từ mép dưới màn hình
    // =========================================================================
    Item {
        id: islandRoot
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: Math.max(0, root.islandW)
        height: Math.max(0, root.islandH)

        // Bóng đổ mềm phía trên đảo
        RectangularShadow {
            anchors.fill: island
            anchors.bottomMargin: root.cornerRadius
            radius: root.cornerRadius
            offset.y: -8
            blur: 36
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: Math.min(1, root.islandH / 40)
        }

        // Thân đảo: kéo xuống dưới mép màn hình một đoạn bằng bán kính
        // để hai góc dưới bị giấu đi, chỉ còn hai góc trên được bo tròn
        Rectangle {
            id: island
            x: 0
            y: 0
            width: parent.width
            height: parent.height + root.cornerRadius
            radius: Math.min(root.cornerRadius, (parent.height + root.cornerRadius) / 2)
            color: root.islandColor

            MouseArea {
                anchors.fill: parent
            }
        }

        // Góc lõm bên trái: nối mềm thân đảo với mép dưới màn hình
        Shape {
            id: filletLeft
            readonly property real r: Math.min(root.filletRadius, root.islandH)
            visible: r > 0.5
            x: -r
            y: parent.height - r
            width: r
            height: r
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.islandColor
                startX: 0; startY: filletLeft.r
                PathLine { x: filletLeft.r; y: filletLeft.r }
                PathLine { x: filletLeft.r; y: 0 }
                PathArc {
                    x: 0; y: filletLeft.r
                    radiusX: filletLeft.r; radiusY: filletLeft.r
                    direction: PathArc.Clockwise
                }
            }
        }

        // Góc lõm bên phải: nối mềm thân đảo với mép dưới màn hình
        Shape {
            id: filletRight
            readonly property real r: Math.min(root.filletRadius, root.islandH)
            visible: r > 0.5
            x: parent.width
            y: parent.height - r
            width: r
            height: r
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.islandColor
                startX: filletRight.r; startY: filletRight.r
                PathLine { x: 0; y: filletRight.r }
                PathLine { x: 0; y: 0 }
                PathArc {
                    x: filletRight.r; y: filletRight.r
                    radiusX: filletRight.r; radiusY: filletRight.r
                    direction: PathArc.Counterclockwise
                }
            }
        }

        // ---------------- Nội dung đảo ----------------
        Item {
            id: content
            anchors.fill: parent
            clip: true
            // Nội dung chỉ hiện dần khi đảo đã phình đủ lớn
            opacity: Math.max(0, Math.min(1, (root.islandH - 24) / 26))
                     * Math.max(0, Math.min(1, (root.islandW - 300) / 200))

            Item {
                id: inner
                width: root.openWidth
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom

                // ---------- Thanh tìm kiếm (cố định sát đáy màn hình) ----------
                Item {
                    id: searchBar
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: root.searchHeight

                    Text {
                        id: searchIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf002"
                        font.family: root.fontFamily
                        font.pixelSize: 16
                        color: Qt.rgba(1, 1, 1, 0.45)
                    }

                    TextInput {
                        id: searchInput
                        anchors.left: searchIcon.right
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: root.fontFamily
                        font.pixelSize: 16
                        color: "#ffffff"
                        selectionColor: Qt.rgba(1, 1, 1, 0.25)
                        selectedTextColor: "#ffffff"
                        clip: true

                        onTextChanged: root.filterApps()

                        Keys.onPressed: (event) => {
                            let ctrl = event.modifiers & Qt.ControlModifier;
                            switch (event.key) {
                            case Qt.Key_Down:
                            case Qt.Key_Tab:
                                root.select(root.sel + 1);
                                event.accepted = true;
                                break;
                            case Qt.Key_Up:
                            case Qt.Key_Backtab:
                                root.select(root.sel - 1);
                                event.accepted = true;
                                break;
                            case Qt.Key_J:
                            case Qt.Key_N:
                                if (ctrl) { root.select(root.sel + 1); event.accepted = true; }
                                break;
                            case Qt.Key_K:
                            case Qt.Key_P:
                                if (ctrl) { root.select(root.sel - 1); event.accepted = true; }
                                break;
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                root.launchSelected();
                                event.accepted = true;
                                break;
                            case Qt.Key_Escape:
                                // Esc lần đầu xoá chữ, lần sau mới đóng
                                if (searchInput.text !== "") searchInput.text = "";
                                else root.close();
                                event.accepted = true;
                                break;
                            }
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Tìm kiếm ứng dụng"
                            font: searchInput.font
                            color: Qt.rgba(1, 1, 1, 0.3)
                            visible: searchInput.text === "" && !searchInput.inputMethodComposing
                        }
                    }
                }

                // ---------- Danh sách kết quả (bung lên phía trên thanh tìm kiếm) ----------
                Item {
                    id: resultsArea
                    anchors.bottom: searchBar.top
                    width: parent.width
                    height: root.resultsTargetHeight

                    opacity: root.showResults ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: root.showResults ? 220 : 120 }
                    }

                    ListView {
                        id: appsList
                        anchors.fill: parent
                        anchors.margins: root.listPadding
                        clip: true
                        model: root.filteredApps
                        boundsBehavior: Flickable.StopAtBounds
                        highlightFollowsCurrentItem: false
                        currentIndex: -1

                        NumberAnimation {
                            id: scrollAnim
                            target: appsList
                            property: "contentY"
                            duration: 220
                            easing.type: Easing.OutCubic
                        }

                        // ---- Thanh chọn trắng với hiệu ứng cursor trail ----
                        // Gắn trực tiếp vào contentItem với z: -1 để nằm dưới chữ/icon
                        // và tự động cuộn đồng bộ cùng danh sách
                        Rectangle {
                            id: trail
                            parent: appsList.contentItem
                            property real topEdge: 0
                            property real bottomEdge: root.rowHeight
                            property bool movingDown: true
                            property bool instant: false

                            z: -1
                            x: 0
                            width: appsList.width
                            y: topEdge
                            height: Math.max(0, bottomEdge - topEdge)
                            radius: 10
                            color: "#ffffff"
                            visible: root.filteredApps.length > 0

                            Behavior on topEdge {
                                enabled: !trail.instant
                                NumberAnimation {
                                    duration: trail.movingDown ? root.trailSlow : root.trailFast
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on bottomEdge {
                                enabled: !trail.instant
                                NumberAnimation {
                                    duration: trail.movingDown ? root.trailFast : root.trailSlow
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === root.sel

                            z: 1
                            width: appsList.width
                            height: root.rowHeight

                            Image {
                                id: icon
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24
                                height: 24
                                sourceSize.width: 48
                                sourceSize.height: 48
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                mipmap: true
                                source: row.modelData && row.modelData.icon
                                        ? Quickshell.iconPath(row.modelData.icon, true)
                                        : ""
                            }

                            Text {
                                anchors.centerIn: icon
                                visible: icon.status !== Image.Ready
                                text: "\uf40e"
                                font.family: root.fontFamily
                                font.pixelSize: 16
                                color: row.selected ? "#000000" : Qt.rgba(1, 1, 1, 0.5)
                            }

                            Text {
                                anchors.left: icon.right
                                anchors.leftMargin: 14
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData ? row.modelData.name : ""
                                font.family: root.fontFamily
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                color: row.selected ? "#000000" : Qt.rgba(1, 1, 1, 0.62)
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onPositionChanged: {
                                    if (root.sel !== row.index) root.select(row.index);
                                }
                                onClicked: {
                                    root.select(row.index);
                                    root.launchSelected();
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.showResults && root.filteredApps.length === 0
                        text: "Không có kết quả"
                        font.family: root.fontFamily
                        font.pixelSize: 14
                        color: Qt.rgba(1, 1, 1, 0.35)
                    }
                }
            }
        }
    }
}
