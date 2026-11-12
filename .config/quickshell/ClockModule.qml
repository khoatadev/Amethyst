import QtQuick
import Quickshell

Rectangle {
    id: root

    Theme { id: theme }

    width: 42
    height: col.implicitHeight + 16
    radius: width / 2
    color: theme.bgDark
    border.width: 1
    border.color: hover.containsMouse ? theme.borderHover : "transparent"

    // Hover scale
    scale: hover.containsMouse ? 1.04 : 1.0
    Behavior on scale {
        NumberAnimation { duration: theme.durFast; easing.type: Easing.OutCubic }
    }
    Behavior on border.color {
        ColorAnimation { duration: theme.durFast }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 1

        // Hour
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "hh")
            font.family: theme.fontMono
            font.pixelSize: 15
            font.bold: true
            color: theme.accent

            Behavior on color { ColorAnimation { duration: theme.durFast } }
        }

        // Minute
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "mm")
            font.family: theme.fontMono
            font.pixelSize: 15
            font.bold: true
            color: theme.fg
        }

        // Divider
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 24
            height: 5

            Rectangle {
                anchors.centerIn: parent
                width: 22
                height: 1
                color: theme.border

                // Nhịp thở nhẹ để khối giờ trông "sống"
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.35; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.35; to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                }
            }
        }

        // Weekday (ddd)
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "ddd")
            font.family: theme.fontMono
            font.pixelSize: 8
            color: theme.fgSubtle
        }

        // Date (DD/MM)
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dd/MM")
            font.family: theme.fontMono
            font.pixelSize: 9
            font.bold: true
            color: theme.fgMuted
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }
}
