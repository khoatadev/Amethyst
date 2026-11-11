import QtQuick
import Quickshell

Rectangle {
    id: root

    Theme { id: theme }

    width: 40
    height: col.implicitHeight + 14
    radius: 10
    color: theme.bgDark
    border.color: theme.border
    border.width: 1

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
            font.pixelSize: 14
            font.bold: true
            color: theme.accent
        }

        // Minute
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "mm")
            font.family: theme.fontMono
            font.pixelSize: 14
            font.bold: true
            color: theme.fg
        }

        // Divider
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 22
            height: 5

            Rectangle {
                anchors.centerIn: parent
                width: 20
                height: 1
                color: theme.border
            }
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
}
