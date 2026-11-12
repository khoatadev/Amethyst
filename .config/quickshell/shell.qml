import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    Theme { id: theme }

    // Service chia sẻ dữ liệu âm thanh từ Cava
    CavaService { id: cavaService }

    // Trình khởi chạy ứng dụng (App Launcher) thay thế Rofi
    AppLauncher {
        id: appLauncher
        theme: theme
    }

    // Handler IPC lắng nghe tín hiệu gọi từ phím tắt mangoWC hoặc script
    IpcHandler {
        target: "launcher"

        function toggle() {
            appLauncher.toggle();
        }

        function open() {
            appLauncher.open();
        }

        function close() {
            appLauncher.close();
        }
    }

    // Visualizer sóng uốn lượn mềm mại ở mép trên cùng
    TopWaveVisualizer {
        cavaService: cavaService
    }

    // Visualizer thanh chữ nhật cổ điển ở mép dưới cùng
    BottomBarsVisualizer {
        cavaService: cavaService
    }

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
