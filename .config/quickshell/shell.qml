import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Theme { id: theme }

    PanelWindow {
        id: bar

        anchors {
            top: true
            bottom: true
            left: true
        }
        implicitWidth: 50
        color: "transparent"

        // Nền thanh bar bo cong mềm mại 2 góc ngoài mép phải
        Rectangle {
            anchors.fill: parent
            color: theme.bg
            topLeftRadius: 0
            bottomLeftRadius: 0
            topRightRadius: 18
            bottomRightRadius: 18
        }

        ColumnLayout {
            anchors {
                fill: parent
                topMargin: 10
                bottomMargin: 10
                leftMargin: 5
                rightMargin: 5
            }
            spacing: 8

            // 1. Module trên cùng: Giờ & Ngày
            ClockModule {
                Layout.alignment: Qt.AlignHCenter
            }

            // 2. Module Workspaces (mangoWC Tags)
            WorkspacesModule {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
            }

            // Khoảng trống giãn cách tự do đẩy module điều khiển xuống đáy
            Item {
                Layout.fillHeight: true
            }

            // 3. Cụm điều khiển hệ thống gộp chung (Độ sáng, Âm thanh, Pin & Power Profile)
            ControlsCapsule {
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
