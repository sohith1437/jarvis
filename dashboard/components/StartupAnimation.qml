import QtQuick

Item {
    id: root

    anchors.fill: parent

    property bool finished: false

    // =========================================================
    // BACKGROUND
    // =========================================================

    Rectangle {
        anchors.fill: parent
        color: "#010305"
    }

    // Very subtle blue atmosphere
    Rectangle {
        anchors.centerIn: parent

        width: 850
        height: 850

        radius: width / 2

        color: "#06303a"
        opacity: 0.08

        SequentialAnimation on opacity {
            running: true
            loops: Animation.Infinite

            NumberAnimation {
                from: 0.05
                to: 0.12
                duration: 1000
            }

            NumberAnimation {
                from: 0.12
                to: 0.05
                duration: 1000
            }
        }
    }


    // =========================================================
    // CENTRAL JARVIS REACTOR
    // =========================================================

    Item {
        id: reactor

        anchors.centerIn: parent

        width: 520
        height: 520

        opacity: 0
        scale: 0.05


        // =====================================================
        // ORGANIC ENERGY PETALS
        // =====================================================

        Repeater {
            model: 20

            Item {

                id: petal

                property real petalAngle: index * 18

                width: 115
                height: 190

                anchors.centerIn: parent

                rotation: petalAngle

                scale: 0.05

                opacity: 0


                Rectangle {

                    anchors.horizontalCenter: parent.horizontalCenter

                    y: 0

                    width: 76
                    height: 170

                    radius: 38

                    color: "transparent"

                    border.width: 2

                    border.color: "#38dff5"

                    opacity: 0.55

                    transformOrigin: Item.Bottom

                    scale: 0.7


                    // Soft inner glow
                    Rectangle {

                        anchors.centerIn: parent

                        width: 55
                        height: 135

                        radius: 28

                        color: "#1ccfe7"

                        opacity: 0.10
                    }
                }


                SequentialAnimation {

                    running: true

                    PauseAnimation {
                        duration: 650 + index * 20
                    }


                    ParallelAnimation {

                        NumberAnimation {

                            target: petal

                            property: "opacity"

                            from: 0

                            to: 1

                            duration: 350
                        }


                        NumberAnimation {

                            target: petal

                            property: "scale"

                            from: 0.05

                            to: 1

                            duration: 650

                            easing.type: Easing.OutBack
                        }
                    }
                }
            }
        }


        // =====================================================
        // ENERGY RING BEHIND REACTOR
        // =====================================================

        Rectangle {

            anchors.centerIn: parent

            width: 420
            height: 420

            radius: width / 2

            color: "transparent"

            border.width: 1

            border.color: "#21899b"

            opacity: 0


            RotationAnimation on rotation {

                running: true

                from: 0
                to: 360

                duration: 11000

                loops: Animation.Infinite
            }


            SequentialAnimation on opacity {

                running: true

                PauseAnimation {
                    duration: 1200
                }

                NumberAnimation {

                    from: 0
                    to: 0.7

                    duration: 700
                }
            }
        }


        // =====================================================
        // FIRST HUD RING
        // =====================================================

        Rectangle {

            anchors.centerIn: parent

            width: 360
            height: 360

            radius: width / 2

            color: "transparent"

            border.width: 2

            border.color: "#63eaff"

            opacity: 0


            RotationAnimation on rotation {

                running: true

                from: 360
                to: 0

                duration: 6500

                loops: Animation.Infinite
            }


            SequentialAnimation on opacity {

                running: true

                PauseAnimation {
                    duration: 1550
                }

                NumberAnimation {

                    from: 0
                    to: 0.85

                    duration: 500
                }
            }
        }


        // =====================================================
        // SECOND HUD RING
        // =====================================================

        Rectangle {

            anchors.centerIn: parent

            width: 315
            height: 315

            radius: width / 2

            color: "transparent"

            border.width: 1

            border.color: "#8df3ff"

            opacity: 0


            RotationAnimation on rotation {

                running: true

                from: 0
                to: 360

                duration: 4200

                loops: Animation.Infinite
            }


            SequentialAnimation on opacity {

                running: true

                PauseAnimation {
                    duration: 1800
                }

                NumberAnimation {

                    from: 0
                    to: 0.9

                    duration: 450
                }
            }
        }


        // =====================================================
        // REACTOR SEGMENTS
        // =====================================================

        Repeater {

            model: 16

            Rectangle {

                property real segmentAngle: index * 22.5

                width: 18
                height: 55

                radius: 5

                color: "#a9faff"

                opacity: 0

                anchors.centerIn: parent

                transform: Rotation {

                    origin.x: 9
                    origin.y: 115

                    angle: segmentAngle
                }

                y: -87


                SequentialAnimation on opacity {

                    running: true

                    PauseAnimation {
                        duration: 800 + index * 25
                    }

                    NumberAnimation {

                        from: 0
                        to: 0.95

                        duration: 300
                    }
                }
            }
        }


        // =====================================================
        // CORE GLOW
        // =====================================================

        Rectangle {

            id: coreGlow

            anchors.centerIn: parent

            width: 170
            height: 170

            radius: 85

            color: "#35eaff"

            opacity: 0.10

            scale: 0.5


            SequentialAnimation on scale {

                running: true

                PauseAnimation {
                    duration: 800
                }

                NumberAnimation {

                    from: 0.5
                    to: 1.0

                    duration: 700

                    easing.type: Easing.OutBack
                }

                SequentialAnimation {

                    loops: Animation.Infinite

                    NumberAnimation {
                        from: 0.96
                        to: 1.05
                        duration: 700
                    }

                    NumberAnimation {
                        from: 1.05
                        to: 0.96
                        duration: 700
                    }
                }
            }
        }


        // =====================================================
        // WHITE CORE
        // =====================================================

        Rectangle {

            id: core

            anchors.centerIn: parent

            width: 92
            height: 92

            radius: 46

            color: "#dfffff"

            opacity: 0

            scale: 0.3


            SequentialAnimation {

                running: true

                PauseAnimation {
                    duration: 700
                }

                ParallelAnimation {

                    NumberAnimation {

                        target: core

                        property: "opacity"

                        from: 0

                        to: 1

                        duration: 450
                    }

                    NumberAnimation {

                        target: core

                        property: "scale"

                        from: 0.3

                        to: 1

                        duration: 550

                        easing.type: Easing.OutBack
                    }
                }
            }
        }


        // =====================================================
        // CORE INNER BLUE
        // =====================================================

        Rectangle {

            anchors.centerIn: parent

            width: 55
            height: 55

            radius: 27.5

            color: "#ffffff"

            opacity: 0.85
        }
    }


    // =========================================================
    // HORIZONTAL LIGHT FLARE
    // =========================================================

    Rectangle {

        id: flare

        anchors.centerIn: parent

        width: 0
        height: 2

        color: "#7df5ff"

        opacity: 0.75


        NumberAnimation {

            target: flare

            property: "width"

            from: 0

            to: 900

            duration: 850

            easing.type: Easing.OutCubic
        }


        NumberAnimation {

            target: flare

            property: "opacity"

            from: 0

            to: 0.7

            duration: 300
        }
    }


    // =========================================================
    // TECHNICAL HUD
    // =========================================================

    Item {

        id: technicalHud

        anchors.fill: parent

        opacity: 0


        // -----------------------------------------------
        // LEFT TOP
        // -----------------------------------------------

        Text {

            x: 80
            y: 70

            text: "JARVIS CORE"

            color: "#52e8ff"

            font.pixelSize: 10

            font.family: "Consolas"

            font.letterSpacing: 2
        }


        Text {

            x: 80
            y: 91

            text: "CORE STATUS"

            color: "#789da5"

            font.pixelSize: 9

            font.family: "Consolas"
        }


        Text {

            x: 80
            y: 108

            text: "ONLINE"

            color: "#57f0b0"

            font.pixelSize: 10

            font.family: "Consolas"
        }


        // -----------------------------------------------
        // RIGHT TOP
        // -----------------------------------------------

        Text {

            anchors.right: parent.right

            anchors.rightMargin: 80

            y: 70

            text: "SYSTEM"

            color: "#52e8ff"

            font.pixelSize: 10

            font.family: "Consolas"

            font.letterSpacing: 2
        }


        Text {

            anchors.right: parent.right

            anchors.rightMargin: 80

            y: 91

            text: "NEURAL ENGINE"

            color: "#789da5"

            font.pixelSize: 9

            font.family: "Consolas"
        }


        Text {

            anchors.right: parent.right

            anchors.rightMargin: 80

            y: 108

            text: "ACTIVE"

            color: "#57f0b0"

            font.pixelSize: 10

            font.family: "Consolas"
        }


        // -----------------------------------------------
        // LEFT DATA
        // -----------------------------------------------

        Column {

            x: 85

            anchors.verticalCenter: parent.verticalCenter

            spacing: 6


            Text {
                text: "PROCESSING"
                color: "#4ad9ed"
                font.pixelSize: 9
                font.family: "Consolas"
            }

            Text {
                text: "AUDIO INPUT     100%"
                color: "#688f98"
                font.pixelSize: 9
                font.family: "Consolas"
            }

            Text {
                text: "NEURAL CORE     100%"
                color: "#688f98"
                font.pixelSize: 9
                font.family: "Consolas"
            }

            Text {
                text: "VOICE ENGINE    READY"
                color: "#688f98"
                font.pixelSize: 9
                font.family: "Consolas"
            }
        }


        // -----------------------------------------------
        // RIGHT DATA
        // -----------------------------------------------

        Column {

            anchors.right: parent.right

            anchors.rightMargin: 85

            anchors.verticalCenter: parent.verticalCenter

            spacing: 6


            Text {
                text: "SYSTEM ANALYSIS"
                color: "#4ad9ed"
                font.pixelSize: 9
                font.family: "Consolas"
            }

            Text {
                text: "WHISPER STT     READY"
                color: "#688f98"
                font.pixelSize: 9
                font.family: "Consolas"
            }

            Text {
                text: "OLLAMA AI       ONLINE"
                color: "#688f98"
                font.pixelSize: 9
                font.family: "Consolas"
            }

            Text {
                text: "PC CONTROL      READY"
                color: "#688f98"
                font.pixelSize: 9
                font.family: "Consolas"
            }
        }


        // -----------------------------------------------
        // SMALL CORNER MARKERS
        // -----------------------------------------------

        Rectangle {

            x: 40
            y: 40

            width: 80
            height: 1

            color: "#286c79"
        }


        Rectangle {

            anchors.right: parent.right

            anchors.rightMargin: 40

            y: 40

            width: 80

            height: 1

            color: "#286c79"
        }


        Rectangle {

            x: 40

            anchors.bottom: parent.bottom

            anchors.bottomMargin: 40

            width: 80

            height: 1

            color: "#286c79"
        }


        Rectangle {

            anchors.right: parent.right

            anchors.rightMargin: 40

            anchors.bottom: parent.bottom

            anchors.bottomMargin: 40

            width: 80

            height: 1

            color: "#286c79"
        }
    }


    // =========================================================
    // STARTUP TIMELINE
    // =========================================================

    SequentialAnimation {

        running: true


        // -----------------------------------------------------
        // 0.0 — BLACK
        // -----------------------------------------------------

        PauseAnimation {
            duration: 350
        }


        // -----------------------------------------------------
        // 0.35 — CORE IGNITION
        // -----------------------------------------------------

        ParallelAnimation {

            NumberAnimation {

                target: reactor

                property: "opacity"

                from: 0

                to: 1

                duration: 200
            }


            NumberAnimation {

                target: reactor

                property: "scale"

                from: 0.05

                to: 0.8

                duration: 650

                easing.type: Easing.OutBack
            }


            NumberAnimation {

                target: flare

                property: "opacity"

                from: 0

                to: 0.75

                duration: 300
            }
        }


        // -----------------------------------------------------
        // 1.0 — ENERGY FLOWER
        // -----------------------------------------------------

        PauseAnimation {
            duration: 450
        }


        // -----------------------------------------------------
        // 1.45 — HUD RINGS
        // -----------------------------------------------------

        ParallelAnimation {

            NumberAnimation {

                target: reactor

                property: "scale"

                from: 0.8

                to: 1.0

                duration: 650

                easing.type: Easing.OutCubic
            }


            NumberAnimation {

                target: technicalHud

                property: "opacity"

                from: 0

                to: 0.35

                duration: 500
            }
        }


        // -----------------------------------------------------
        // 2.1 — TECHNICAL DATA
        // -----------------------------------------------------

        PauseAnimation {
            duration: 500
        }


        NumberAnimation {

            target: technicalHud

            property: "opacity"

            from: 0.35

            to: 1

            duration: 700
        }


        // -----------------------------------------------------
        // 2.8 — HOLD / HUD BUILD
        // -----------------------------------------------------

        PauseAnimation {
            duration: 1500
        }


        // -----------------------------------------------------
        // 4.7 — FINAL REACTOR POWER
        // -----------------------------------------------------

        ParallelAnimation {

            NumberAnimation {

                target: coreGlow

                property: "opacity"

                from: 0.10

                to: 0.32

                duration: 300
            }


            NumberAnimation {

                target: reactor

                property: "scale"

                from: 1

                to: 1.05

                duration: 350
            }
        }


        // -----------------------------------------------------
        // 5.1 — COMPLETE
        // -----------------------------------------------------

        ScriptAction {

            script: {

                root.finished = true

            }
        }
    }
}