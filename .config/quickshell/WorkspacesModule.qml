import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    Theme { id: theme }

    width: parent.width
    implicitHeight: capsule.height

    property var rawTags: []
    property var visibleTags: {
        let list = rawTags.filter(t => t.is_active || t.client_count > 0)
        return list.length > 0 ? list : [{ index: 1, is_active: true, client_count: 0 }]
    }

    property int activeIndex: {
        for (let i = 0; i < visibleTags.length; i++) {
            if (visibleTags[i].is_active) return i
        }
        return 0
    }

    // Persistent stream watcher for mangoWC tags
    Process {
        id: tagWatcher
        command: ["mmsg", "watch", "all-tags"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    let obj = JSON.parse(data.trim())
                    if (obj && obj.all_tags && obj.all_tags.length > 0) {
                        root.rawTags = obj.all_tags[0].tags
                    }
                } catch(e) {}
            }
        }
    }

    // Command runner for workspace dispatch
    Process {
        id: tagDispatcher
    }

    // Nền tối gộp chung hình viên thuốc (Capsule / Pill bo tròn hoàn hảo)
    Rectangle {
        id: capsule
        width: 38
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property int padding: 3
        readonly property int itemSize: 32
        readonly property int spacing: 4

        height: padding * 2 + root.visibleTags.length * itemSize + Math.max(0, root.visibleTags.length - 1) * spacing
        radius: width / 2
        color: theme.bgDark

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // Tọa độ mục tiêu cho Active Indicator
        property int currentTargetY: padding + root.activeIndex * (itemSize + spacing)
        property bool movingDown: true

        onCurrentTargetYChanged: {
            movingDown = currentTargetY >= indicator.topY
        }

        // Active Indicator với hiệu ứng Stretch & Contract (Cursor Trail kiểu Kitty)
        Item {
            id: indicator
            width: capsule.itemSize
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.activeIndex >= 0

            property real topY: capsule.currentTargetY
            property real bottomY: capsule.currentTargetY + capsule.itemSize

            Behavior on topY {
                NumberAnimation {
                    duration: capsule.movingDown ? 340 : 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on bottomY {
                NumberAnimation {
                    duration: capsule.movingDown ? 200 : 340
                    easing.type: Easing.OutCubic
                }
            }

            y: topY
            height: Math.max(capsule.itemSize, bottomY - topY)

            // Khối màu viên thuốc co giãn đàn hồi
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: theme.accent
                opacity: 0.95
            }
        }

        // Danh sách các số workspace nằm nổi bên trên
        Column {
            id: itemsColumn
            anchors.horizontalCenter: parent.horizontalCenter
            y: capsule.padding
            spacing: capsule.spacing

            Repeater {
                model: root.visibleTags

                Item {
                    id: tagItem
                    width: capsule.itemSize
                    height: capsule.itemSize

                    readonly property bool isActive: modelData.is_active
                    readonly property bool hasClients: modelData.client_count > 0

                    // Hover highlight mờ nhẹ
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: theme.bgHover
                        opacity: (mouseArea.containsMouse && !tagItem.isActive) ? 0.8 : 0.0
                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.index.toString()
                        font.family: theme.fontMono
                        font.pixelSize: 13
                        font.bold: true
                        color: tagItem.isActive ? theme.bgDark : (tagItem.hasClients ? theme.fg : theme.fgMuted)

                        Behavior on color {
                            ColorAnimation { duration: 180 }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            tagDispatcher.exec(["mmsg", "dispatch", "view," + modelData.index + ",0"])
                        }
                    }
                }
            }
        }
    }
}
