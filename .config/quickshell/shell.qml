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

    // Menu chọn wallpaper (island gallery + transition awww)
    WallpaperMenu {
        id: wallpaperMenu
        theme: theme
    }

    // Menu chọn wifi (island mọc từ mép bar trái, quét qua NetworkManager)
    WifiMenu {
        id: wifiMenu
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

    // Handler IPC cho menu wallpaper (gọi từ phím tắt SUPER+W)
    IpcHandler {
        target: "wallpaper"

        function toggle() {
            wallpaperMenu.toggle();
        }

        function open() {
            wallpaperMenu.open();
        }

        function close() {
            wallpaperMenu.close();
        }
    }

    // Handler IPC cho menu wifi (gọi từ phím tắt mangoWC hoặc script)
    IpcHandler {
        target: "wifi"

        function toggle() {
            wifiMenu.toggle();
        }

        function open() {
            wifiMenu.open();
        }

        function close() {
            wifiMenu.close();
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
        implicitWidth: 54
        color: "transparent"

        // Nền bar: gradient dọc tinh tế bgDark -> bg
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: theme.bgDark }
                GradientStop { position: 0.5; color: theme.bg }
                GradientStop { position: 1.0; color: theme.bgDark }
            }
        }

        // Subtle divider separating the vertical bar from desktop windows
        // Viền mờ dần ở 2 đầu (gradient alpha) để mềm mại hơn.
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: 1
            z: 10
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.15; color: theme.borderHover }
                GradientStop { position: 0.85; color: theme.borderHover }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors {
                fill: parent
                topMargin: 12
                bottomMargin: 12
                leftMargin: 6
                rightMargin: 6
            }
            spacing: 10

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

            // 3. Cụm điều khiển hệ thống gộp chung (Wifi, Độ sáng, Âm thanh, Pin & Power Profile)
            ControlsCapsule {
                Layout.alignment: Qt.AlignHCenter

                // Click nút wifi trên capsule → mở menu wifi
                onWifiClicked: wifiMenu.open()
            }
        }
    }
}
