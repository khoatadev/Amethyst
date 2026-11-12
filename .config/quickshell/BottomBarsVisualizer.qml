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

    // Cao hơn chút cho mirror reflection bên dưới đường chân thanh
    implicitHeight: 118
    color: "transparent"
    aboveWindows: false

    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore

    // Vùng vẽ thanh chính (phía trên), phần còn lại cho reflection
    readonly property real barAreaHeight: 92
    readonly property real reflectRatio: 0.26   // chiều cao phản chiếu so với thanh
    readonly property real groundGap: 2         // khe hở giữa thanh và bóng phản chiếu

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Threaded

        Connections {
            target: root.cavaService
            function onBarsChanged() {
                canvas.requestPaint()
            }
            function onPeaksChanged() {
                canvas.requestPaint()
            }
        }

        // alpha của màu hex + alpha (0..1)
        function withAlpha(hex, a) {
            return Qt.rgba((parseInt(hex.substring(1, 3), 16)) / 255,
                           (parseInt(hex.substring(3, 5), 16)) / 255,
                           (parseInt(hex.substring(5, 7), 16)) / 255, a)
        }

        onPaint: {
            let ctx = getContext("2d")
            let w = width
            let h = height
            ctx.clearRect(0, 0, w, h)

            let svc = root.cavaService
            let bars = svc ? svc.bars : null
            let peaks = svc ? svc.peaks : null
            let count = bars ? bars.length : 0
            if (count === 0) return

            let areaH = root.barAreaHeight
            let spacing = 5
            let totalSpacing = (count - 1) * spacing
            let barWidth = Math.max(2, (w - totalSpacing) / count)
            let maxBarHeight = areaH - 8

            // Gradient thân cột: Tokyo Night — xanh đậm đáy, tím giữa, hồng đỏ đỉnh
            let barGrad = ctx.createLinearGradient(0, areaH, 0, areaH - maxBarHeight)
            barGrad.addColorStop(0.00, withAlpha("#4d6fff", 0.55)) // chân thanh lùi vào nền
            barGrad.addColorStop(0.25, "#82aaff")
            barGrad.addColorStop(0.70, "#c099ff")
            barGrad.addColorStop(1.00, "#ff757f")

            // Gradient cho phần phản chiếu (top->bottom), mờ dần vào nền
            let refGrad = ctx.createLinearGradient(0, areaH, 0, h)
            refGrad.addColorStop(0.0, withAlpha("#82aaff", 0.28))
            refGrad.addColorStop(0.5, withAlpha("#7a5fb0", 0.10))
            refGrad.addColorStop(1.0, withAlpha("#7a5fb0", 0.0))

            for (let i = 0; i < count; i++) {
                let v = Math.min(100, Math.max(0, bars[i] || 0))
                let x = i * (barWidth + spacing)
                let barHeight = Math.max(2.5, (v / 100.0) * maxBarHeight)
                let y = areaH - barHeight

                // --- Glow nhè nhẹ quanh đỉnh thanh khi nhạc lớn ---
                if (v > 35) {
                    let glowA = Math.min(0.35, (v - 35) / 100)
                    ctx.fillStyle = withAlpha(v > 70 ? "#ff757f" : "#c099ff", glowA)
                    ctx.fillRect(x - 1.5, y - 3, barWidth + 3, 5)
                }

                // --- Thân cột bo nhẹ đầu trên (rounded top) ---
                ctx.fillStyle = barGrad
                let r = Math.min(barWidth / 2, 2.5)
                ctx.beginPath()
                ctx.moveTo(x, areaH)
                ctx.lineTo(x, y + r)
                ctx.arcTo(x, y, x + r, y, r)
                ctx.lineTo(x + barWidth - r, y)
                ctx.arcTo(x + barWidth, y, x + barWidth, y + r, r)
                ctx.lineTo(x + barWidth, areaH)
                ctx.closePath()
                ctx.fill()

                // --- Nắp đỉnh sáng: peak cap rời thân, trôi xuống chậm ---
                let pv = Math.min(100, Math.max(0, peaks ? peaks[i] || 0 : v))
                if (pv > 2) {
                    let capY = areaH - Math.max(2.5, (pv / 100.0) * maxBarHeight) - 5
                    let capA = 0.55 + 0.45 * (pv / 100.0)
                    ctx.fillStyle = withAlpha("#e6e9fc", capA)
                    ctx.fillRect(x, capY, barWidth, 2.5)
                }

                // --- Reflection: bản sao thu nhỏ, mờ dần, dồn về đáy ---
                let reflH = barHeight * root.reflectRatio
                if (reflH > 1) {
                    ctx.fillStyle = refGrad
                    ctx.fillRect(x, areaH + root.groundGap, barWidth, reflH)
                }
            }

            // Đường "sàn" mảnh chạy ngang chân thanh, sáng lên khi có âm thanh
            let audio = svc ? svc.hasAudio : false
            let energy = 0
            for (let i = 0; i < count; i++) energy += (bars[i] || 0)
            energy = energy / (count * 100) // 0..1
            ctx.fillStyle = withAlpha("#82aaff", 0.10 + 0.28 * (audio ? energy : 0))
            ctx.fillRect(0, areaH + 0.5, w, 1)
        }
    }
}
