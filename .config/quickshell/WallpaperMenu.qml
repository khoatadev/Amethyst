import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// =============================================================================
// Wallpaper Menu — "Wallpaper Island" mọc lên từ mép dưới màn hình
// - Đồng bộ aesthetic với AppLauncher: đảo đen bo góc trên, góc lõm nối mép
//   dưới, spring nảy nhẹ khi mở, co gọn mượt khi đóng
// - Gallery thumbnail bay vào vị trí kiểu staggered (mỗi ảnh trễ 45ms, nảy
//   từ dưới lên bằng OutBack), hover phóng nhẹ + glow viền accent; ảnh đang
//   chọn to hơn hẳn + viền glow luôn hiện, và được cuộn vào giữa dải
// - Chọn ảnh: awww đổi wallpaper NGAY với --transition-type random ở 120fps
//   (mặc định 30fps) — transition bắt đầu từ đúng điểm click; menu đóng ngay
// - Wallpaper đang dùng có chấm xanh pulse ở góc; tên file chạy chữ mono
// =============================================================================

PanelWindow {
    id: root

    property var theme
    property bool isOpen: false

    // ---- Thư mục wallpaper ----
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string currentWallpaper: ""

    // ---- Thông số giao diện ----
    readonly property int openWidth: 880
    readonly property int closedWidth: 130
    readonly property int headerHeight: 48
    readonly property int thumbHeight: 210
    readonly property int thumbWidth: 336     // 16:10 khớp wallpaper 3840x2400
    readonly property int thumbGap: 18
    readonly property int bodyPadding: 20
    readonly property int cornerRadius: 24     // bo hai góc trên
    readonly property int filletRadius: 14     // góc lõm nối với mép màn hình
    readonly property color islandColor: "#000000"
    readonly property string fontFamily: theme ? theme.fontMono : "ComicShannsMono Nerd Font"

    // ---- Kích thước đảo hiện tại (được animate) ----
    property real islandW: closedWidth
    property real islandH: 0

    readonly property real targetH: isOpen ? contentHeight : 0
    readonly property real targetW: isOpen ? openWidth : closedWidth
    // header + gallery + dòng tên + đệm đáy
    readonly property real contentHeight: headerHeight + thumbHeight + 34 + bodyPadding

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

    visible: isOpen || islandH > 0.5
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "wallpapers"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; bottom: true; left: true; right: true }

    // =========================================================================
    // Dữ liệu wallpaper
    // =========================================================================
    property var wallpapers: []     // [{ path, name }]
    property int sel: 0

    // Quét thư mục wallpaper qua find + sort
    Process {
        id: scanProcess
        command: ["/bin/sh", "-c",
            "find '" + root.wallpaperDir + "' -maxdepth 1 -type f " +
            "\\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split("\n").filter(l => l.trim() !== "");
                root.wallpapers = lines.map(p => ({ path: p, name: p.split("/").pop() }));
                if (root.wallpapers.length > 0 && root.sel >= root.wallpapers.length)
                    root.sel = 0;
                queryProcess.running = true;
            }
        }
        stderr: StdioCollector {}
    }

    // Đọc wallpaper đang hiển thị từ awww query
    Process {
        id: queryProcess
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                let m = this.text.match(/image:\s*(\S+)/);
                if (m) root.currentWallpaper = m[1];
            }
        }
        stderr: StdioCollector {}
    }

    function refresh() {
        scanProcess.running = true;
    }

    // =========================================================================
    // Đổi wallpaper qua awww — transition ngẫu nhiên 120fps, từ điểm chọn
    // =========================================================================
    function applyWallpaper(path, origin) {
        // 120 fps (mặc định 30) để transition mượt không giật
        let cmd = "awww img '" + path + "' " +
                  "--transition-type random " +
                  "--transition-fps 120 " +
                  "--transition-duration 1.2";
        if (origin) {
            cmd += " --transition-pos " + Math.round(origin.x) + "," + Math.round(origin.y);
        }
        Quickshell.execDetached(["/bin/sh", "-c", cmd]);
        currentWallpaper = path;
    }

    // Click chọn wallpaper: awww chạy transition ngay lập tức rồi đóng menu
    function pickWallpaper(idx, origin) {
        if (wallpapers.length === 0) return;
        idx = ((idx % wallpapers.length) + wallpapers.length) % wallpapers.length;
        sel = idx;
        applyWallpaper(wallpapers[idx].path, origin);
        close();
    }

    // Tâm của thumbnail đang chọn — dùng làm tâm transition awww khi gõ phím
    function wallpaperCenterPoint() {
        for (let i = 0; i < strip.contentItem.children.length; i++) {
            let c = strip.contentItem.children[i];
            if (c.index === sel) {
                return c.mapToItem(
                    root.contentItem, c.width / 2, c.height / 2);
            }
        }
        return Qt.point(root.width / 2, root.height / 2);
    }

    function open() {
        refresh();
        isOpen = true;
        Qt.callLater(() => keyHandler.forceActiveFocus());
    }

    function close() {
        isOpen = false;
    }

    function toggle() {
        isOpen ? close() : open();
    }

    Component.onCompleted: refresh()

    // Click ra ngoài → đóng
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

        // Thân đảo: kéo dài xuống dưới mép màn hình bằng cornerRadius
        // để hai góc dưới bị giấu đi, chỉ còn hai góc trên được bo tròn
        Rectangle {
            id: island
            x: 0; y: 0
            width: parent.width
            height: parent.height + root.cornerRadius
            radius: Math.min(root.cornerRadius, (parent.height + root.cornerRadius) / 2)
            color: root.islandColor

            MouseArea { anchors.fill: parent }
        }

        // Góc lõm trái: nối mềm thân đảo với mép dưới màn hình
        Shape {
            id: filletLeft
            readonly property real r: Math.min(root.filletRadius, root.islandH)
            visible: r > 0.5
            x: -r
            y: parent.height - r
            width: r; height: r
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

        // Góc lõm phải: nối mềm thân đảo với mép dưới màn hình
        Shape {
            id: filletRight
            readonly property real r: Math.min(root.filletRadius, root.islandH)
            visible: r > 0.5
            x: parent.width
            y: parent.height - r
            width: r; height: r
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
            opacity: Math.max(0, Math.min(1, (root.islandH - 24) / 26))
                     * Math.max(0, Math.min(1, (root.islandW - 300) / 200))

            Item {
                id: inner
                width: root.openWidth
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom

                // ---------- Tiêu đề + số lượng ----------
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
                        text: "\uf03e  wallpapers"
                        font.family: root.fontFamily
                        font.pixelSize: 14
                        color: Qt.rgba(1, 1, 1, 0.9)
                    }

                    // Pill đếm số ảnh
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        width: countText.implicitWidth + 24
                        height: 28
                        radius: 14
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: root.wallpapers.length + " ảnh"
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            color: Qt.rgba(1, 1, 1, 0.6)
                        }
                    }
                }

                // ---------- Gallery: dải film cuộn ngang ----------
                ListView {
                    id: strip
                    anchors.top: header.bottom
                    anchors.topMargin: 8
                    anchors.bottom: nameBar.top
                    anchors.bottomMargin: 8
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.bodyPadding
                    anchors.rightMargin: root.bodyPadding
                    clip: true
                    orientation: ListView.Horizontal
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 8000
                    maximumFlickVelocity: 4000
                    spacing: root.thumbGap
                    model: root.wallpapers.length

                    // Header/footer bằng nửa khoảng trống hiển thị: cả ảnh
                    // đầu tiên lẫn ảnh cuối cùng đều cuộn được vào giữa dải
                    header: Item {
                        width: Math.max(0, (strip.width - root.thumbWidth) / 2)
                        height: 1
                        visible: false
                    }
                    footer: Item {
                        width: Math.max(0, (strip.width - root.thumbWidth) / 2)
                        height: 1
                        visible: false
                    }

                    // Cuộn mượt đưa ảnh được chọn vào giữa
                    // (delegate index 0 nằm sau header → cộng thêm headerW)
                    function ensureCentered(idx) {
                        if (count === 0) return;
                        let headerW = (width - root.thumbWidth) / 2;
                        let x = headerW + idx * (root.thumbWidth + root.thumbGap)
                                - width / 2 + root.thumbWidth / 2;
                        x = Math.max(0, Math.min(x, contentWidth - width));
                        if (contentWidth <= width) return;
                        scrollAnim.stop();
                        scrollAnim.to = x;
                        scrollAnim.start();
                    }

                    NumberAnimation {
                        id: scrollAnim
                        target: strip
                        property: "contentX"
                        duration: 280
                        easing.type: Easing.OutCubic
                    }

                    delegate: Item {
                        id: thumb
                        required property int index
                        readonly property var wp: root.wallpapers[thumb.index] || null
                        readonly property bool isCurrent: wp && wp.path === root.currentWallpaper
                                readonly property bool isSel: thumb.index === root.sel
                                property real hoverT: hoverHandler.hovered ? 1 : 0
                        // 0 → 1 khi đảo mở (Timer trễ index*45ms tạo stagger)
                        property real shown: 0

                        width: root.thumbWidth
                        height: root.thumbHeight

                        Behavior on hoverT { NumberAnimation { duration: 180 } }

                        // ---- Bay vào vị trí staggered khi đảo mở ----
                        // nảy từ dưới lên (OutBack), mờ → rõ
                        y: 56 * (1 - shown)
                        opacity: shown

                        Behavior on y {
                            NumberAnimation {
                                duration: 480
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.15
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
                        }

                        // Mỗi ảnh trễ nhau 45ms
                        Timer {
                            interval: 40 + thumb.index * 45
                            running: root.isOpen
                            repeat: false
                            onTriggered: thumb.shown = 1
                        }

                        // Ảnh đang chọn to hơn hẳn một chút, hover phóng nhẹ thêm
                        scale: 1 + hoverT * 0.05 + (isSel ? 0.08 : 0)
                        Behavior on scale {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        HoverHandler {
                            id: hoverHandler
                            onHoveredChanged: {
                                if (hovered) root.sel = thumb.index;
                            }
                        }

                        // Khung ảnh + bo góc
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: Qt.rgba(1, 1, 1, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.10 + thumb.hoverT * 0.12)
                        }

                        // Ảnh wallpaper bo góc bằng Rectangle clip
                        Rectangle {
                            id: imgFrame
                            anchors.fill: parent
                            anchors.margins: 5
                            radius: 11
                            clip: true
                            color: "transparent"

                            Image {
                                id: img
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: thumb.wp ? "file://" + thumb.wp.path : ""
                                sourceSize.width: 640
                                sourceSize.height: 400
                                asynchronous: true
                                mipmap: true

                                // Shimmer placeholder khi đang load
                                Rectangle {
                                    anchors.fill: parent
                                    visible: img.status !== Image.Ready
                                    color: Qt.rgba(1, 1, 1, 0.05)

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 60
                                        height: parent.height
                                        x: -80
                                        rotation: 15
                                        color: Qt.rgba(1, 1, 1, 0.07)

                                        SequentialAnimation on x {
                                            loops: Animation.Infinite
                                            NumberAnimation {
                                                from: -80; to: img.width + 80
                                                duration: 1300
                                                easing.type: Easing.InOutSine
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Viền glow accent: nổi rõ khi hover, nhẹ hơn khi được chọn
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border.width: 2
                            visible: thumb.hoverT > 0.02 || thumb.isSel
                            border.color: Qt.rgba(
                                root.theme ? root.theme.accent.r : 0.51,
                                root.theme ? root.theme.accent.g : 0.67,
                                root.theme ? root.theme.accent.b : 1.0,
                                Math.max(thumb.hoverT * 0.85, thumb.isSel ? 0.45 : 0)
                            )
                        }

                        // Chấm xanh pulse: wallpaper đang dùng
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: 11
                            anchors.leftMargin: 11
                            width: 10; height: 10
                            radius: 5
                            visible: thumb.isCurrent
                            color: root.theme ? root.theme.green : "#c3e88d"
                            border.width: 2
                            border.color: Qt.rgba(0, 0, 0, 0.4)
                            transformOrigin: Item.Center

                            SequentialAnimation on scale {
                                running: thumb.isCurrent
                                loops: Animation.Infinite
                                NumberAnimation { from: 1; to: 1.35; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.35; to: 1; duration: 900; easing.type: Easing.InOutSine }
                            }
                        }

                        // Tên file (đã lược hoá) dưới ảnh
                        Text {
                            anchors.top: parent.bottom
                            anchors.topMargin: 7
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (!thumb.wp) return "";
                                let n = thumb.wp.name;
                                n = n.replace(/\.(png|jpe?g|webp)$/i, "");
                                n = n.replace(/^wallhaven-/, "");
                                return n;
                            }
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            color: thumb.isSel ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(1, 1, 1, 0.35)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Click: chọn + hiệu ứng bay
                        MouseArea {
                            anchors.fill: parent
                            onClicked: (mouse) => {
                                let p = thumb.mapToItem(
                                    root.contentItem, thumb.width / 2, thumb.height / 2);
                                root.pickWallpaper(thumb.index, p);
                            }
                        }
                    }
                }

                // ---------- Dòng tên + hint phím ----------
                Item {
                    id: nameBar
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    width: parent.width
                    height: 30

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - hint.implicitWidth - 60
                        text: root.wallpapers.length > 0 && root.wallpapers[root.sel]
                              ? root.wallpapers[root.sel].name : ""
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        color: Qt.rgba(1, 1, 1, 0.4)
                        elide: Text.ElideMiddle
                    }

                    Text {
                        id: hint
                        anchors.right: parent.right
                        anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        text: "enter chọn · esc đóng"
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        color: Qt.rgba(1, 1, 1, 0.3)
                    }
                }

                // Bắt phím khi menu mở
                Item {
                    id: keyHandler
                    anchors.fill: parent
                    focus: false

                    Keys.onLeftPressed: (event) => {
                        if (root.wallpapers.length === 0) return;
                        root.sel = ((root.sel - 1) + root.wallpapers.length) % root.wallpapers.length;
                        strip.ensureCentered(root.sel);
                        event.accepted = true;
                    }
                    Keys.onRightPressed: (event) => {
                        if (root.wallpapers.length === 0) return;
                        root.sel = (root.sel + 1) % root.wallpapers.length;
                        strip.ensureCentered(root.sel);
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: (event) => {
                        root.pickWallpaper(root.sel, root.wallpaperCenterPoint());
                        event.accepted = true;
                    }
                    Keys.onEnterPressed: (event) => {
                        root.pickWallpaper(root.sel, root.wallpaperCenterPoint());
                        event.accepted = true;
                    }
                    Keys.onEscapePressed: (event) => {
                        root.close();
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
