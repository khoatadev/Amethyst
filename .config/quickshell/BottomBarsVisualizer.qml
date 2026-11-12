import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var cavaService
    Theme { id: theme }

    anchors {
        bottom: true
        left: true
        right: true
    }
    margins {
        left: 50 // Chừa chỗ cho thanh Quickshell dọc mép trái
    }

    implicitHeight: 100
    color: "transparent"
    aboveWindows: false

    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Threaded

        Connections {
            target: root.cavaService
            function onValuesChanged() {
                canvas.requestPaint()
            }
        }

        onPaint: {
            let ctx = getContext("2d")
            let w = width
            let h = height
            ctx.clearRect(0, 0, w, h)

            let values = root.cavaService ? root.cavaService.values : []
            let count = values ? values.length : 0
            if (count === 0) return

            let spacing = 4
            let totalSpacing = (count - 1) * spacing
            let barWidth = Math.max(2, (w - totalSpacing) / count)
            let maxBarHeight = h - 10

            // Tạo gradient chung từ đáy lên đỉnh thanh chữ nhật
            let barGrad = ctx.createLinearGradient(0, h, 0, 10)
            barGrad.addColorStop(0.0, "#82aaff")      // Tokyo Accent Blue ở đáy
            barGrad.addColorStop(0.7, "#c099ff")      // Purple chuyển tiếp
            barGrad.addColorStop(1.0, "#ff757f")      // Đỉnh cao chạm đỏ/hồng cá tính

            for (let i = 0; i < count; i++) {
                let v = values[i] || 0
                let barHeight = Math.max(3, (v / 100.0) * maxBarHeight)
                let x = i * (barWidth + spacing)
                let y = h - barHeight

                // Thân cột chữ nhật cổ điển
                ctx.fillStyle = barGrad
                ctx.fillRect(x, y, barWidth, barHeight)

                // Đỉnh nắp sáng (Cap highlight) tạo độ sắc sảo cho visualizer
                if (barHeight > 4) {
                    ctx.fillStyle = "#c8d3f5"
                    ctx.fillRect(x, y, barWidth, 2)
                }
            }
        }
    }
}
