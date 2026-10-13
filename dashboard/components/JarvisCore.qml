import QtQuick

Item {
    id: root

    width: 380
    height: 440

    property string state: "LISTENING"

    // Colors according to state
    readonly property color glowColor: {
        if (root.state === "THINKING") return "#b86cff"
        if (root.state === "SPEAKING") return "#31e6b0"
        if (root.state === "SLEEPING") return "#285868"
        if (root.state === "OFFLINE")  return "#25323a"
        return "#38dff5"
    }

    readonly property color coreColor: {
        if (root.state === "THINKING") return "#dfb0ff"
        if (root.state === "SPEAKING") return "#8affd8"
        if (root.state === "SLEEPING") return "#457b8b"
        if (root.state === "OFFLINE")  return "#3c4850"
        return "#c8f8ff"
    }

    // =========================================================
    // ARC REACTOR UNIT
    // =========================================================

    Item {
        id: reactor
        width: 320
        height: 320
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10

        // Soft outer ambient radial aura
        Rectangle {
            anchors.centerIn: parent
            width: 310
            height: 310
            radius: width / 2
            color: "transparent"
            border.color: root.glowColor
            border.width: 1
            opacity: root.state === "OFFLINE" ? 0.15 : 0.45

            SequentialAnimation on opacity {
                running: root.state !== "OFFLINE"
                loops: Animation.Infinite
                NumberAnimation { from: 0.3; to: 0.65; duration: root.state === "THINKING" ? 450 : 1200 }
                NumberAnimation { from: 0.65; to: 0.3; duration: root.state === "THINKING" ? 450 : 1200 }
            }
        }

        // Outer rotating tick ring (HUD Track)
        Item {
            anchors.fill: parent
            rotation: 0

            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: root.state === "THINKING" ? 5000 : 16000
                loops: Animation.Infinite
                running: root.state !== "OFFLINE"
            }

            Repeater {
                model: 24
                Rectangle {
                    required property int index
                    anchors.centerIn: parent
                    width: 2
                    height: index % 4 === 0 ? 12 : 6
                    color: root.glowColor
                    opacity: 0.7
                    transform: [
                        Translate { y: -145 },
                        Rotation { angle: index * 15 }
                    ]
                }
            }
        }

        // Secondary counter-rotating dashed ring
        Rectangle {
            anchors.centerIn: parent
            width: 260
            height: 260
            radius: width / 2
            color: "transparent"
            border.color: root.glowColor
            border.width: 1.5
            opacity: root.state === "OFFLINE" ? 0.2 : 0.65

            RotationAnimation on rotation {
                from: 360
                to: 0
                duration: root.state === "THINKING" ? 4000 : 12000
                loops: Animation.Infinite
                running: root.state !== "OFFLINE"
            }
        }

        // Inner Segmented Arc Reactor Coils (16 blocks)
        Item {
            id: coilRing
            anchors.centerIn: parent
            width: 210
            height: 210

            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: root.state === "THINKING" ? 3000 : 20000
                loops: Animation.Infinite
                running: root.state !== "OFFLINE"
            }

            Repeater {
                model: 16
                Rectangle {
                    required property int index
                    width: 14
                    height: 28
                    radius: 3
                    color: root.glowColor
                    anchors.centerIn: parent
                    opacity: root.state === "OFFLINE" ? 0.25 : 0.9

                    transform: [
                        Translate { y: -90 },
                        Rotation { angle: index * 22.5 }
                    ]

                    // Inner coil core highlight
                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 20
                        radius: 2
                        color: root.coreColor
                        opacity: 0.8
                    }
                }
            }
        }

        // Concentric Inner Housing
        Rectangle {
            anchors.centerIn: parent
            width: 130
            height: 130
            radius: width / 2
            color: "#05131b"
            border.color: root.glowColor
            border.width: 2
            opacity: 0.95
        }

        // Luminous Central Core
        Rectangle {
            id: innerLuminousCore
            anchors.centerIn: parent
            width: 85
            height: 85
            radius: width / 2
            color: root.glowColor
            opacity: root.state === "OFFLINE" ? 0.3 : 0.85
            scale: root.state === "SPEAKING" ? 1.12 : 1.0

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }

            // Central White-Hot Emitter
            Rectangle {
                anchors.centerIn: parent
                width: 48
                height: 48
                radius: width / 2
                color: root.coreColor

                // JARVIS "J" Emblem
                Text {
                    anchors.centerIn: parent
                    text: "J"
                    color: "#031017"
                    font.pixelSize: 26
                    font.bold: true
                    font.family: "Consolas"
                }
            }
        }
    }

    // =========================================================
    // HUD RETICLE / RADAR CIRCLE (from reference video)
    // =========================================================

    Item {
        id: hudReticle
        anchors.horizontalCenter: parent.horizontalCenter
        y: 335
        width: 180
        height: 70

        // Reticle ring
        Rectangle {
            anchors.centerIn: parent
            width: 60
            height: 60
            radius: 30
            color: "transparent"
            border.color: root.glowColor
            border.width: 1
            opacity: 0.4

            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: 10000
                loops: Animation.Infinite
                running: true
            }

            // Crosshair ticks
            Rectangle { anchors.centerIn: parent; width: 14; height: 1; color: root.glowColor }
            Rectangle { anchors.centerIn: parent; width: 1; height: 14; color: root.glowColor }
        }

        // State indicator text badge
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            text: root.state
            color: root.glowColor
            font.pixelSize: 13
            font.bold: true
            font.letterSpacing: 4
            font.family: "Segoe UI"
        }
    }
}