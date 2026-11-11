import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: root

    Theme { id: theme }

    spacing: 6
    width: parent.width

    property var rawTags: []
    property var visibleTags: {
        let list = rawTags.filter(t => t.is_active || t.client_count > 0)
        return list.length > 0 ? list : [{ index: 1, is_active: true, client_count: 0 }]
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

    Repeater {
        model: root.visibleTags

        Rectangle {
            id: tagBtn
            width: 36
            height: 36
            radius: 8
            anchors.horizontalCenter: parent.horizontalCenter

            readonly property bool isActive: modelData.is_active
            readonly property bool hasClients: modelData.client_count > 0

            color: {
                if (tagBtn.isActive) return theme.accent
                if (mouseArea.containsMouse) return theme.bgHover
                return theme.bgDark
            }

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Text {
                anchors.centerIn: parent
                text: modelData.index.toString()
                font.family: theme.fontMono
                font.pixelSize: 13
                font.bold: true
                color: tagBtn.isActive ? theme.bgDark : theme.fg
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
