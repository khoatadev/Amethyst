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
        color: theme.bg

        // Subtle divider separating the vertical bar from desktop windows
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: 1
            color: theme.border
            z: 10
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

            // Khoảng trống giãn cách tự do đẩy các module điều khiển xuống đáy
            Item {
                Layout.fillHeight: true
            }

            // 3. Module Độ sáng
            BrightnessModule {
                Layout.alignment: Qt.AlignHCenter
            }

            // 4. Module Âm thanh
            AudioModule {
                Layout.alignment: Qt.AlignHCenter
            }

            // 5. Module Pin
            BatteryModule {
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
