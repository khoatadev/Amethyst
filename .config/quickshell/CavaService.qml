import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property int barCount: 50
    property var values: []
    property bool hasAudio: false

    Component.onCompleted: {
        let initial = []
        for (let i = 0; i < barCount; i++) {
            initial.push(0)
        }
        values = initial
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
