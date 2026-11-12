import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // =========================================================================
    // Cava service v2 — phục hồi động lực học (dynamics) cho visualizer
    // values  : giá trị thô 0..100 từ cava (giữ tương thích cũ)
    // bars    : giá trị đã làm mềm attack/release — thanh hiển thị thật
    // peaks   : đỉnh trôi của mỗi thanh, rơi tự do theo trọng lực
    // =========================================================================

    readonly property int barCount: 50
    property var values: []      // raw, 0..100
    property var bars: []        // smoothed, 0..100 — dùng để vẽ
    property var peaks: []       // peak caps, 0..100
    property var peakVel: []     // vận tốc rơi của peak (units/frame^2)
    property bool hasAudio: false

    // Tham số động lực học — chỉnh ở đây để đổi "cảm giác nảy"
    readonly property real attack: 0.55      // bar bám tín hiệu lên nhanh (punch)
    readonly property real release: 0.10     // bar rơi chậm, dẻo như lò xo
    readonly property real gravity: 0.55     // gia tốc rơi của peak cap
    readonly property real peakHoldMs: 380   // giữ peak đứng yên trước khi rơi

    Component.onCompleted: {
        let zeros = new Array(barCount).fill(0)
        values = zeros.slice()
        bars = zeros.slice()
        peaks = zeros.slice()
        peakVel = zeros.slice()
    }

    // Đếm thời gian giữ peak cho từng bar (ms kể từ lần chạm đỉnh)
    property var peakHold: new Array(barCount).fill(0)
    property double lastTs: 0

    // Xung đếp thời gian 60Hz tách khỏi luồng dữ liệu cava
    Timer {
        id: physTimer
        interval: 16
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = Date.now()
            let dt = root.lastTs === 0 ? 16 : Math.min(64, now - root.lastTs)
            root.lastTs = now

            let raw = root.values
            let sm = root.bars
            let pk = root.peaks
            let pv = root.peakVel
            let ph = root.peakHold
            if (!raw || raw.length !== root.barCount) return

            // Chuẩn hoá dt về đơn vị frame 60fps (1.0 = 16.67ms)
            let f = dt / 16.67

            for (let i = 0; i < root.barCount; i++) {
                let target = raw[i] || 0
                let cur = sm[i] || 0

                // --- Thanh chính: attack nhanh, release chậm (dao động dẻo) ---
                let k = target > cur ? root.attack : root.release
                // khung thời gian dt ảnh hưởng: a = 1 - (1 - k)^f
                let step = 1 - Math.pow(1 - k, f)
                cur = cur + (target - cur) * step
                sm[i] = cur

                // --- Peak cap: bám đỉnh, giữ, rồi rơi theo trọng lực ---
                if (cur >= pk[i]) {
                    pk[i] = cur
                    pv[i] = 0
                    ph[i] = 0
                } else {
                    ph[i] += dt
                    if (ph[i] > root.peakHoldMs) {
                        pv[i] += root.gravity * f
                        pk[i] = Math.max(cur, pk[i] - pv[i] * f)
                        if (pk[i] <= cur) {
                            pk[i] = cur
                            pv[i] = 0
                            ph[i] = 0
                        }
                    }
                }
            }

            // Thông báo visualizer vẽ lại (2 mảng đổi nội dung)
            root.barsChanged()
            root.peaksChanged()
        }
    }

    Process {
        id: cavaProc
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/cava.conf"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let trimmed = data.trim()
                if (!trimmed) return
                let parts = trimmed.split(';')
                if (parts.length >= root.barCount) {
                    let arr = new Array(root.barCount)
                    let active = false
                    for (let i = 0; i < root.barCount; i++) {
                        let val = parseInt(parts[i]) || 0
                        if (val > 0) active = true
                        arr[i] = val
                    }
                    root.values = arr
                    root.hasAudio = active
                }
            }
        }
    }
}
