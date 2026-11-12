import QtQuick

// RippleEffect — hiệu ứng gợn sóng tại vị trí click.
// Cách dùng: đặt như 1 Item phủ lên nút (anchors.fill: parent, clip: true),
// và gọi ripple.trigger(mouse) bên trong MouseArea.onClicked.
Item {
    id: root

    property color rippleColor: "#82aaff"
    property real maxScale: 2.4
    property int rippleDuration: 420

    // Tạo 1 gợn sóng tại vị trí con trỏ chuột (mouse là MouseArea đang bắt sự kiện)
    function trigger(mouse) {
        let px = mouse ? mouse.mouseX : width / 2
        let py = mouse ? mouse.mouseY : height / 2
        spawn(px, py)
    }

    function spawn(px, py) {
        let r = Math.max(width, height)
        let comp = rippleComponent
        let obj = comp.createObject(root, {
            "x": px - r / 2,
            "y": py - r / 2,
            "width": r,
            "height": r,
            "color": root.rippleColor
        })
        if (obj) obj.start()
    }

    Component {
        id: rippleComponent

        Rectangle {
            id: circle
            radius: width / 2
            opacity: 0
            scale: 0.1
            transformOrigin: Item.Center

            property real targetScale: root.maxScale

            function start() {
                anim.start()
            }

            NumberAnimation {
                id: anim
                target: circle
                property: "scale"
                from: 0.1
                to: circle.targetScale
                duration: root.rippleDuration
                easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                running: true
                NumberAnimation {
                    target: circle
                    property: "opacity"
                    from: 0.55
                    to: 0.0
                    duration: root.rippleDuration
                    easing.type: Easing.OutQuad
                }
                ScriptAction { script: circle.destroy() }
            }
        }
    }
}
