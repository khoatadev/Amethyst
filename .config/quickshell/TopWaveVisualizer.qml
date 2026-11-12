import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var cavaService
    Theme { id: theme }

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        left: 50 // Chừa chỗ cho thanh Quickshell dọc mép trái
    }

    implicitHeight: 110
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

        // Thuật toán Monotone Cubic Spline (Fritsch-Carlson)
        // Đảm bảo đường cong mượt mà tuyệt đối và KHÓA CHẶT phần gốc tại baseY,
        // triệt tiêu 100% hiện tượng overshoot (nảy gốc khi âm lượng tăng cao).
        function drawMonotoneSpline(ctx, points, baseY) {
            let n = points.length
            if (n < 2) return

            // 1. Tính delta và độ dốc (slopes) giữa các điểm kề nhau
            let dx = new Array(n - 1)
            let dy = new Array(n - 1)
            let slopes = new Array(n - 1)

            for (let i = 0; i < n - 1; i++) {
                dx[i] = points[i + 1].x - points[i].x
                dy[i] = points[i + 1].y - points[i].y
                slopes[i] = dx[i] !== 0 ? dy[i] / dx[i] : 0
            }

            // 2. Tính tiếp tuyến (tangents) tại từng điểm
            let tangents = new Array(n)
            tangents[0] = slopes[0]
            tangents[n - 1] = slopes[n - 2]

            for (let i = 1; i < n - 1; i++) {
                // Nếu đổi chiều độ dốc (đỉnh/đáy sóng) hoặc vùng bằng phẳng -> tiếp tuyến bằng 0
                if (slopes[i - 1] * slopes[i] <= 0) {
                    tangents[i] = 0
                } else {
                    tangents[i] = (slopes[i - 1] + slopes[i]) / 2.0
                }
            }

            // 3. Chuẩn hóa Fritsch-Carlson chống overshoot
            for (let i = 0; i < n - 1; i++) {
                if (slopes[i] === 0) {
                    tangents[i] = 0
                    tangents[i + 1] = 0
                } else {
                    let a = tangents[i] / slopes[i]
                    let b = tangents[i + 1] / slopes[i]
                    let d = a * a + b * b
                    if (d > 9) {
                        let tau = 3.0 / Math.sqrt(d)
                        tangents[i] = tau * a * slopes[i]
                        tangents[i + 1] = tau * b * slopes[i]
                    }
                }
            }

            // 4. Vẽ Bézier spline với điểm điều khiển luôn bị neo chặt (>= baseY)
            ctx.moveTo(points[0].x, points[0].y)
            for (let i = 0; i < n - 1; i++) {
                let cp1x = points[i].x + dx[i] / 3.0
                let cp1y = Math.max(baseY, points[i].y + tangents[i] * dx[i] / 3.0)

                let cp2x = points[i + 1].x - dx[i] / 3.0
                let cp2y = Math.max(baseY, points[i + 1].y - tangents[i + 1] * dx[i] / 3.0)

                ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, points[i + 1].x, points[i + 1].y)
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

            let step = w / (count - 1)
            let maxAmp = h - 14
            let baseY = 2 // Mép gốc áp sát mép trên cùng màn hình

            // 1. Tạo tập điểm cho lớp sóng chính (Front wave)
            let frontPoints = new Array(count)
            // 2. Tạo tập điểm cho lớp sóng phụ (Back wave mềm mại phía sau)
            let backPoints = new Array(count)

            for (let i = 0; i < count; i++) {
                let v = values[i] || 0
                let amp = (v / 100.0) * maxAmp
                let x = i * step

                frontPoints[i] = {
                    x: x,
                    y: baseY + amp
                }

                // Sóng phụ mượt hơn bằng cách nội suy lân cận
                let prevV = i > 0 ? (values[i - 1] || 0) : v
                let nextV = i < count - 1 ? (values[i + 1] || 0) : v
                let smoothedV = (prevV + v * 2 + nextV) / 4.0
                backPoints[i] = {
                    x: x,
                    y: baseY + (smoothedV / 100.0) * (maxAmp * 0.75)
                }
            }

            // --- Vẽ lớp sóng phụ (Back Wave - Purple mờ) ---
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(backPoints[0].x, backPoints[0].y)
            drawMonotoneSpline(ctx, backPoints, baseY)
            ctx.lineTo(w, 0)
            ctx.closePath()

            let backGrad = ctx.createLinearGradient(0, 0, 0, h)
            backGrad.addColorStop(0.0, "rgba(192, 153, 255, 0.22)")
            backGrad.addColorStop(0.6, "rgba(192, 153, 255, 0.08)")
            backGrad.addColorStop(1.0, "rgba(192, 153, 255, 0.0)")
            ctx.fillStyle = backGrad
            ctx.fill()

            // --- Vẽ lớp sóng chính (Front Wave - Tokyo Accent Blue Gradient) ---
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(frontPoints[0].x, frontPoints[0].y)
            drawMonotoneSpline(ctx, frontPoints, baseY)
            ctx.lineTo(w, 0)
            ctx.closePath()

            let frontGrad = ctx.createLinearGradient(0, 0, 0, h)
            frontGrad.addColorStop(0.0, "rgba(130, 170, 255, 0.38)")
            frontGrad.addColorStop(0.5, "rgba(192, 153, 255, 0.18)")
            frontGrad.addColorStop(1.0, "rgba(34, 36, 54, 0.0)")
            ctx.fillStyle = frontGrad
            ctx.fill()

            // --- Vẽ đường viền đỉnh sóng phát sáng (Wave Crest Stroke) ---
            ctx.beginPath()
            drawMonotoneSpline(ctx, frontPoints, baseY)
            let strokeGrad = ctx.createLinearGradient(0, 0, w, 0)
            strokeGrad.addColorStop(0.0, "#82aaff")
            strokeGrad.addColorStop(0.5, "#c099ff")
            strokeGrad.addColorStop(1.0, "#82aaff")
            ctx.strokeStyle = strokeGrad
            ctx.lineWidth = 2.2
            ctx.stroke()
        }
    }
}
