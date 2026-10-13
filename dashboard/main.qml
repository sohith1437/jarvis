import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtMultimedia

import "components"

Window {
    id: window

    width: 1440
    height: 900
    minimumWidth: 1024
    minimumHeight: 700

    visible: true
    visibility: Window.Maximized
    color: "#020609"
    title: "J.A.R.V.I.S. — Personal AI Assistant"

    // State properties synced from Python bridge
    property string jarvisState: "SLEEPING"
    property string userMessage: ""
    property string jarvisMessage: "JARVIS is ready, boss."
    property var historyList: []
    property var activityList: []
    property var telemetry: ({
        "cpu": 0, "ram": 0, "ram_text": "0/0 GB",
        "gpu": 0, "vram_text": "N/A", "gpu_temp": 0,
        "disk": 0, "disk_text": "0/0 GB"
    })
    property var services: ({
        "ollama": true, "whisper": true, "tts": true, "mic": true
    })

    // Active navigation tab: 0=Assistant, 1=Commands, 2=System, 3=Activity, 4=Settings
    property int currentView: 0

    // Intro playback state
    property bool introActive: !skipIntro

    // =========================================================
    // BACKGROUND GRID & AMBIENT AURA
    // =========================================================

    Rectangle {
        anchors.fill: parent
        color: "#02070c"
    }

    Canvas {
        anchors.fill: parent
        opacity: 0.05
        onPaint: {
            var ctx = getContext("2d");
            ctx.strokeStyle = "#38dff5";
            ctx.lineWidth = 1;
            for (var x = 0; x < width; x += 40) {
                ctx.beginPath();
                ctx.moveTo(x, 0);
                ctx.lineTo(x, height);
                ctx.stroke();
            }
            for (var y = 0; y < height; y += 40) {
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
                ctx.stroke();
            }
        }
    }

    // =========================================================
    // MAIN APPLICATION DASHBOARD (Revealed after intro)
    // =========================================================

    Item {
        id: mainDashboard
        anchors.fill: parent
        opacity: window.introActive ? 0.0 : 1.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
        }

        // -----------------------------------------------------
        // TOP HEADER BAR
        // -----------------------------------------------------
        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 18
            height: 70
            color: "#051119"
            border.color: "#123746"
            border.width: 1
            radius: 10

            // Corner Accents (Iron Man HUD style)
            Rectangle { width: 8; height: 2; color: "#38dff5"; anchors.top: parent.top; anchors.left: parent.left }
            Rectangle { width: 2; height: 8; color: "#38dff5"; anchors.top: parent.top; anchors.left: parent.left }
            Rectangle { width: 8; height: 2; color: "#38dff5"; anchors.top: parent.top; anchors.right: parent.right }
            Rectangle { width: 2; height: 8; color: "#38dff5"; anchors.top: parent.top; anchors.right: parent.right }

            // Title & OS Badge
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Text {
                    text: "JARVIS OS"
                    color: "#5de8ff"
                    font.pixelSize: 22
                    font.bold: true
                    font.family: "Segoe UI"
                }

                Rectangle {
                    width: 1; height: 22; color: "#174152"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "PERSONAL AI VOICE SYSTEM"
                    color: "#5f7e8a"
                    font.pixelSize: 11
                    font.letterSpacing: 2
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Center Tab Navigation Buttons
            Row {
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: ["ASSISTANT", "COMMANDS", "SYSTEM", "ACTIVITY", "SETTINGS"]
                    delegate: Rectangle {
                        required property int index
                        required property string modelData
                        width: 110
                        height: 38
                        radius: 6
                        color: window.currentView === index ? "#0c2834" : "transparent"
                        border.color: window.currentView === index ? "#2cd5ee" : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: window.currentView === index ? "#5de8ff" : "#6c8994"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentView = index
                        }
                    }
                }
            }

            // Right Status Badge & Time
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                // Live Clock
                Text {
                    id: liveClock
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatTime(new Date(), "hh:mm:ss AP")
                    color: "#7798a4"
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "Consolas"

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: liveClock.text = Qt.formatTime(new Date(), "hh:mm:ss AP")
                    }
                }

                // System Online Pill
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 140
                    height: 32
                    radius: 16
                    color: window.jarvisState === "OFFLINE" ? "#190d0f" : "#071c18"
                    border.color: window.jarvisState === "OFFLINE" ? "#ff4d6d" : "#1c9e83"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: window.jarvisState === "OFFLINE" ? "#ff4d6d" : "#31e6b0"
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on opacity {
                                running: window.jarvisState !== "OFFLINE"
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                                NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                            }
                        }

                        Text {
                            text: window.jarvisState === "OFFLINE" ? "SYSTEM OFFLINE" : "SYSTEM ONLINE"
                            color: window.jarvisState === "OFFLINE" ? "#ff4d6d" : "#31e6b0"
                            font.pixelSize: 10
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // -----------------------------------------------------
        // LEFT SLIM NAVIGATION DOCK
        // -----------------------------------------------------
        Rectangle {
            id: leftDock
            anchors.left: parent.left
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: 18
            anchors.topMargin: 12
            anchors.bottomMargin: 18
            width: 72
            color: "#051016"
            border.color: "#12303a"
            border.width: 1
            radius: 10

            Column {
                anchors.top: parent.top
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Repeater {
                    model: [
                        { "icon": "🎙️", "tip": "Assistant", "idx": 0 },
                        { "icon": "⚡", "tip": "Commands",  "idx": 1 },
                        { "icon": "🖥️", "tip": "System",    "idx": 2 },
                        { "icon": "📋", "tip": "Activity",  "idx": 3 },
                        { "icon": "⚙️", "tip": "Settings",  "idx": 4 }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: 50
                        height: 50
                        radius: 8
                        color: window.currentView === modelData.idx ? "#0c2b37" : "transparent"
                        border.color: window.currentView === modelData.idx ? "#38dff5" : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.pixelSize: 20
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentView = modelData.idx
                        }
                    }
                }
            }

            // Sleep / Wake Quick Toggle at Bottom of Dock
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                width: 48
                height: 48
                radius: 24
                color: window.jarvisState === "SLEEPING" ? "#1a261a" : "#2a1515"
                border.color: window.jarvisState === "SLEEPING" ? "#31e6b0" : "#ffaa00"

                Text {
                    anchors.centerIn: parent
                    text: window.jarvisState === "SLEEPING" ? "⚡" : "🌙"
                    font.pixelSize: 18
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (window.jarvisState === "SLEEPING") {
                            bridge.requestWake();
                        } else {
                            bridge.requestSleep();
                        }
                    }
                }
            }
        }

        // -----------------------------------------------------
        // RIGHT LIVE CONVERSATION PANEL
        // -----------------------------------------------------
        Rectangle {
            id: rightPanel
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.rightMargin: 18
            anchors.topMargin: 12
            anchors.bottomMargin: 18
            width: 360
            color: "#051016"
            border.color: "#12303a"
            border.width: 1
            radius: 10

            // Header
            Item {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 16
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                height: 24

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "LIVE CONVERSATION"
                    color: "#5de8ff"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: window.historyList.length + " MESSAGES"
                    color: "#4d6b76"
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 48
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                height: 1
                color: "#13313d"
            }

            // Scrollable Conversation History
            ListView {
                id: chatView
                anchors.top: parent.top
                anchors.bottom: bottomInputBar.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                anchors.topMargin: 56
                clip: true
                spacing: 12
                model: window.historyList

                onCountChanged: {
                    Qt.callLater(function() {
                        chatView.positionViewAtEnd();
                    });
                }

                delegate: Column {
                    required property var modelData
                    width: chatView.width
                    spacing: 4

                    // Role Header
                    Row {
                        spacing: 8
                        Text {
                            text: modelData.role === "YOU" ? "👤 YOU" : "🤖 JARVIS"
                            color: modelData.role === "YOU" ? "#38dff5" : "#31e6b0"
                            font.pixelSize: 10
                            font.bold: true
                        }
                        Text {
                            text: modelData.time || ""
                            color: "#46626e"
                            font.pixelSize: 9
                        }
                    }

                    // Message Bubble
                    Rectangle {
                        width: Math.min(parent.width, msgText.implicitWidth + 24)
                        height: msgText.implicitHeight + 16
                        radius: 8
                        color: modelData.role === "YOU" ? "#0b202a" : "#07201c"
                        border.color: modelData.role === "YOU" ? "#194a5c" : "#195045"
                        border.width: 1

                        Text {
                            id: msgText
                            anchors.fill: parent
                            anchors.margins: 10
                            text: modelData.text || ""
                            color: "#c9e2eb"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            // Bottom Quick Command Input Field
            Rectangle {
                id: bottomInputBar
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                height: 48
                color: "#071720"
                border.color: "#184554"
                radius: 8

                TextInput {
                    id: textCommandInput
                    anchors.left: parent.left
                    anchors.right: sendBtn.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    color: "#e0f6fc"
                    font.pixelSize: 12
                    clip: true
                    selectByMouse: true

                    Text {
                        anchors.fill: parent
                        text: "Type a command (e.g. open chrome)..."
                        color: "#4d6b76"
                        font.pixelSize: 12
                        visible: !textCommandInput.text && !textCommandInput.activeFocus
                    }

                    onAccepted: {
                        if (text.trim().length > 0) {
                            bridge.executeCommand(text.trim());
                            text = "";
                        }
                    }
                }

                Rectangle {
                    id: sendBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    radius: 6
                    color: "#0f3744"

                    Text {
                        anchors.centerIn: parent
                        text: "➤"
                        color: "#38dff5"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (textCommandInput.text.trim().length > 0) {
                                bridge.executeCommand(textCommandInput.text.trim());
                                textCommandInput.text = "";
                            }
                        }
                    }
                }
            }
        }

        // -----------------------------------------------------
        // CENTRAL CONTENT AREA (Stacked Views)
        // -----------------------------------------------------
        Item {
            id: centralArea
            anchors.left: leftDock.right
            anchors.right: rightPanel.left
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 12

            // =================================================
            // VIEW 0: PRIMARY ASSISTANT INTERFACE
            // =================================================
            Item {
                id: assistantView
                anchors.fill: parent
                visible: window.currentView === 0

                // Central JARVIS Arc Reactor
                JarvisCore {
                    id: jarvisCoreUnit
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    state: window.jarvisState
                }

                // Dynamic Status Subtitle
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: jarvisCoreUnit.bottom
                    anchors.topMargin: 10
                    text: {
                        if (window.jarvisState === "LISTENING") return "Listening for your voice command..."
                        if (window.jarvisState === "THINKING") return "Processing with local neural network..."
                        if (window.jarvisState === "SPEAKING") return "JARVIS is speaking..."
                        if (window.jarvisState === "SLEEPING") return "Standby. Say 'Jarvis' to wake me."
                        return "JARVIS is offline."
                    }
                    color: "#7497a4"
                    font.pixelSize: 13
                    font.bold: true
                }

                // Quick Commands Action Ribbon
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: telemetryStrip.top
                    anchors.bottomMargin: 16
                    width: parent.width - 32
                    height: 110
                    color: "#05131b"
                    border.color: "#123746"
                    radius: 10

                    Text {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 12
                        text: "QUICK COMMANDS"
                        color: "#5de8ff"
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    Row {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        Repeater {
                            model: [
                                { "title": "Open Chrome", "cmd": "open chrome", "icon": "🌐" },
                                { "title": "System Info", "cmd": "system information", "icon": "🖥️" },
                                { "title": "Screenshot",  "cmd": "screenshot", "icon": "📸" },
                                { "title": "Volume Up",   "cmd": "volume up", "icon": "🔊" },
                                { "title": "Mute Audio",  "cmd": "mute", "icon": "🔇" },
                                { "title": "Lock PC",     "cmd": "lock pc", "icon": "🔒" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                width: (parent.parent.width - 70) / 6
                                height: 50
                                radius: 6
                                color: clickArea.pressed ? "#083a48" : "#091e28"
                                border.color: "#164556"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: modelData.icon; font.pixelSize: 13 }
                                    Text {
                                        text: modelData.title
                                        color: "#8bc2d1"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: clickArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: bridge.executeCommand(modelData.cmd)
                                }
                            }
                        }
                    }
                }

                // Bottom Real-time Telemetry Strip
                Rectangle {
                    id: telemetryStrip
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 32
                    height: 60
                    color: "#05131b"
                    border.color: "#123746"
                    radius: 8

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10

                        // CPU
                        Item {
                            width: parent.width / 4; height: parent.height
                            Column {
                                anchors.centerIn: parent
                                Text { text: "CPU USAGE"; color: "#4f727f"; font.pixelSize: 9; font.bold: true }
                                Text { text: (window.telemetry.cpu || 0) + "%"; color: "#38dff5"; font.pixelSize: 14; font.bold: true }
                            }
                        }
                        // RAM
                        Item {
                            width: parent.width / 4; height: parent.height
                            Column {
                                anchors.centerIn: parent
                                Text { text: "RAM USAGE"; color: "#4f727f"; font.pixelSize: 9; font.bold: true }
                                Text { text: window.telemetry.ram_text || "0 GB"; color: "#38dff5"; font.pixelSize: 14; font.bold: true }
                            }
                        }
                        // GPU
                        Item {
                            width: parent.width / 4; height: parent.height
                            Column {
                                anchors.centerIn: parent
                                Text { text: "RTX 3050 GPU"; color: "#4f727f"; font.pixelSize: 9; font.bold: true }
                                Text { text: (window.telemetry.gpu || 0) + "% (" + (window.telemetry.gpu_temp || 0) + "°C)"; color: "#31e6b0"; font.pixelSize: 14; font.bold: true }
                            }
                        }
                        // VRAM
                        Item {
                            width: parent.width / 4; height: parent.height
                            Column {
                                anchors.centerIn: parent
                                Text { text: "GPU VRAM"; color: "#4f727f"; font.pixelSize: 9; font.bold: true }
                                Text { text: window.telemetry.vram_text || "N/A"; color: "#31e6b0"; font.pixelSize: 14; font.bold: true }
                            }
                        }
                    }
                }
            }

            // =================================================
            // VIEW 1: COMMAND CENTER
            // =================================================
            ScrollView {
                anchors.fill: parent
                visible: window.currentView === 1
                clip: true

                Column {
                    width: parent.width - 20
                    spacing: 18

                    Text {
                        text: "COMMAND CENTER"
                        color: "#5de8ff"
                        font.pixelSize: 18
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    // Section 1: Applications
                    Text { text: "APPLICATIONS"; color: "#7497a4"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 }
                    Grid {
                        columns: 3
                        spacing: 12
                        width: parent.width

                        Repeater {
                            model: [
                                { "title": "Google Chrome", "cmd": "open chrome", "desc": "Launch web browser" },
                                { "title": "VS Code", "cmd": "open vs code", "desc": "Launch code editor" },
                                { "title": "Notepad", "cmd": "open notepad", "desc": "Open text editor" },
                                { "title": "Calculator", "cmd": "open calculator", "desc": "Open system calculator" },
                                { "title": "File Explorer", "cmd": "open file explorer", "desc": "Browse local files" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: (parent.width - 24) / 3
                                height: 70
                                radius: 8
                                color: "#071822"
                                border.color: "#154252"

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: modelData.title; color: "#5de8ff"; font.pixelSize: 12; font.bold: true }
                                    Text { text: modelData.desc; color: "#6a8894"; font.pixelSize: 10 }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: bridge.executeCommand(modelData.cmd)
                                }
                            }
                        }
                    }

                    // Section 2: Web & Search
                    Text { text: "WEB & SEARCH"; color: "#7497a4"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 }
                    Grid {
                        columns: 3
                        spacing: 12
                        width: parent.width

                        Repeater {
                            model: [
                                { "title": "Open YouTube", "cmd": "open youtube", "desc": "Launch YouTube home" },
                                { "title": "Open Google", "cmd": "open google", "desc": "Launch Google search" },
                                { "title": "Search YouTube: Python", "cmd": "search youtube for Python tutorials", "desc": "Execute sample search" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: (parent.width - 24) / 3
                                height: 70
                                radius: 8
                                color: "#071822"
                                border.color: "#154252"

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: modelData.title; color: "#5de8ff"; font.pixelSize: 12; font.bold: true }
                                    Text { text: modelData.desc; color: "#6a8894"; font.pixelSize: 10 }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: bridge.executeCommand(modelData.cmd)
                                }
                            }
                        }
                    }

                    // Section 3: System Controls
                    Text { text: "SYSTEM CONTROLS"; color: "#7497a4"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 }
                    Grid {
                        columns: 3
                        spacing: 12
                        width: parent.width

                        Repeater {
                            model: [
                                { "title": "System Info", "cmd": "system information", "desc": "OS, CPU & Specs" },
                                { "title": "Screenshot", "cmd": "screenshot", "desc": "Save to Desktop" },
                                { "title": "Volume Up", "cmd": "volume up", "desc": "Increase master volume" },
                                { "title": "Volume Down", "cmd": "volume down", "desc": "Decrease master volume" },
                                { "title": "Mute Audio", "cmd": "mute", "desc": "Toggle audio mute" },
                                { "title": "Lock PC", "cmd": "lock pc", "desc": "Secure workstation" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: (parent.width - 24) / 3
                                height: 70
                                radius: 8
                                color: "#071822"
                                border.color: "#154252"

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: modelData.title; color: "#5de8ff"; font.pixelSize: 12; font.bold: true }
                                    Text { text: modelData.desc; color: "#6a8894"; font.pixelSize: 10 }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: bridge.executeCommand(modelData.cmd)
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // VIEW 2: SYSTEM TELEMETRY
            // =================================================
            ScrollView {
                anchors.fill: parent
                visible: window.currentView === 2
                clip: true

                Column {
                    width: parent.width - 20
                    spacing: 20

                    Text {
                        text: "LIVE SYSTEM TELEMETRY"
                        color: "#5de8ff"
                        font.pixelSize: 18
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    // Metrics Grid
                    Grid {
                        columns: 3
                        spacing: 16
                        width: parent.width

                        // CPU Box
                        Rectangle {
                            width: (parent.width - 32) / 3
                            height: 120
                            radius: 8
                            color: "#06151f"
                            border.color: "#143f50"

                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "INTEL CORE i7-12650H"; color: "#547987"; font.pixelSize: 10; font.bold: true }
                                Text { text: (window.telemetry.cpu || 0) + "%"; color: "#38dff5"; font.pixelSize: 28; font.bold: true }
                                Text { text: "Processor Load"; color: "#7fa3b0"; font.pixelSize: 11 }
                            }
                        }

                        // RAM Box
                        Rectangle {
                            width: (parent.width - 32) / 3
                            height: 120
                            radius: 8
                            color: "#06151f"
                            border.color: "#143f50"

                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "SYSTEM MEMORY"; color: "#547987"; font.pixelSize: 10; font.bold: true }
                                Text { text: (window.telemetry.ram || 0) + "%"; color: "#38dff5"; font.pixelSize: 28; font.bold: true }
                                Text { text: window.telemetry.ram_text || "16 GB Total"; color: "#7fa3b0"; font.pixelSize: 11 }
                            }
                        }

                        // GPU Box
                        Rectangle {
                            width: (parent.width - 32) / 3
                            height: 120
                            radius: 8
                            color: "#06151f"
                            border.color: "#143f50"

                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "NVIDIA RTX 3050 LAPTOP"; color: "#547987"; font.pixelSize: 10; font.bold: true }
                                Text { text: (window.telemetry.gpu || 0) + "%"; color: "#31e6b0"; font.pixelSize: 28; font.bold: true }
                                Text { text: "Temp: " + (window.telemetry.gpu_temp || 0) + "°C | VRAM: " + (window.telemetry.vram_text || "N/A"); color: "#7fa3b0"; font.pixelSize: 11 }
                            }
                        }
                    }

                    // Services Status Panel
                    Rectangle {
                        width: parent.width
                        height: 140
                        radius: 8
                        color: "#06151f"
                        border.color: "#143f50"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Text { text: "LOCAL SERVICES HEALTH"; color: "#5de8ff"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 2 }

                            Row {
                                spacing: 24

                                // Ollama
                                Row {
                                    spacing: 8
                                    Rectangle { width: 10; height: 10; radius: 5; color: window.services.ollama ? "#31e6b0" : "#ff4d6d"; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "OLLAMA (llama3.2:3b): " + (window.services.ollama ? "ONLINE" : "UNREACHABLE"); color: "#c1dfe9"; font.pixelSize: 12 }
                                }

                                // Whisper
                                Row {
                                    spacing: 8
                                    Rectangle { width: 10; height: 10; radius: 5; color: "#31e6b0"; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "WHISPER: READY (CPU int8)"; color: "#c1dfe9"; font.pixelSize: 12 }
                                }

                                // TTS
                                Row {
                                    spacing: 8
                                    Rectangle { width: 10; height: 10; radius: 5; color: "#31e6b0"; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "PYTTSX3: READY"; color: "#c1dfe9"; font.pixelSize: 12 }
                                }

                                // Mic
                                Row {
                                    spacing: 8
                                    Rectangle { width: 10; height: 10; radius: 5; color: window.services.mic ? "#31e6b0" : "#ffaa00"; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "MIC ARRAY: " + (window.services.mic ? "CONNECTED" : "NOT DETECTED"); color: "#c1dfe9"; font.pixelSize: 12 }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // VIEW 3: RECENT ACTIVITY LOG
            // =================================================
            Item {
                anchors.fill: parent
                visible: window.currentView === 3

                Item {
                    id: activityHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "RECENT SYSTEM ACTIVITY"
                        color: "#5de8ff"
                        font.pixelSize: 18
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 120
                        height: 30
                        radius: 6
                        color: "#0a2632"
                        border.color: "#1a576d"

                        Text {
                            anchors.centerIn: parent
                            text: "CLEAR LOG"
                            color: "#38dff5"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bridge.clearLogs()
                        }
                    }
                }

                ListView {
                    anchors.top: activityHeader.bottom
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 12
                    clip: true
                    spacing: 8
                    model: window.activityList

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 44
                        radius: 6
                        color: "#06131c"
                        border.color: "#102c38"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 16

                            Text {
                                text: modelData.time || ""
                                color: "#4f727f"
                                font.pixelSize: 11
                                font.family: "Consolas"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 60
                                height: 20
                                radius: 4
                                color: modelData.type === "voice" ? "#0b2c37" : (modelData.type === "command" ? "#072b22" : "#241830")
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.type || "INFO").toUpperCase()
                                    color: modelData.type === "voice" ? "#38dff5" : (modelData.type === "command" ? "#31e6b0" : "#d39eff")
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            Text {
                                text: modelData.event || ""
                                color: "#d0eaf2"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // =================================================
            // VIEW 4: SETTINGS
            // =================================================
            Item {
                anchors.fill: parent
                visible: window.currentView === 4

                Column {
                    width: parent.width - 40
                    spacing: 24

                    Text {
                        text: "SYSTEM SETTINGS"
                        color: "#5de8ff"
                        font.pixelSize: 18
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    // Speech Rate Slider
                    Rectangle {
                        width: parent.width
                        height: 70
                        radius: 8
                        color: "#06151f"
                        border.color: "#143f50"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 24

                            Column {
                                width: 200
                                spacing: 4
                                Text { text: "VOICE SPEECH RATE"; color: "#5de8ff"; font.pixelSize: 11; font.bold: true }
                                Text { text: "Current: " + Math.round(voiceRateSlider.value) + " WPM"; color: "#6a8894"; font.pixelSize: 10 }
                            }

                            Slider {
                                id: voiceRateSlider
                                from: 120
                                to: 240
                                value: 175
                                stepSize: 5
                                width: 300
                                anchors.verticalCenter: parent.verticalCenter
                                onValueChanged: bridge.updateSetting("voice_rate", value)
                            }
                        }
                    }

                    // Voice Volume Slider
                    Rectangle {
                        width: parent.width
                        height: 70
                        radius: 8
                        color: "#06151f"
                        border.color: "#143f50"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 24

                            Column {
                                width: 200
                                spacing: 4
                                Text { text: "VOICE VOLUME"; color: "#5de8ff"; font.pixelSize: 11; font.bold: true }
                                Text { text: "Current: " + Math.round(volumeSlider.value * 100) + "%"; color: "#6a8894"; font.pixelSize: 10 }
                            }

                            Slider {
                                id: volumeSlider
                                from: 0.1
                                to: 1.0
                                value: 1.0
                                stepSize: 0.05
                                width: 300
                                anchors.verticalCenter: parent.verticalCenter
                                onValueChanged: bridge.updateSetting("voice_volume", value)
                            }
                        }
                    }

                    // Wake Word Sensitivity
                    Rectangle {
                        width: parent.width
                        height: 70
                        radius: 8
                        color: "#06151f"
                        border.color: "#143f50"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 24

                            Column {
                                width: 200
                                spacing: 4
                                Text { text: "WAKE WORD DETECTION"; color: "#5de8ff"; font.pixelSize: 11; font.bold: true }
                                Text { text: "Tuned for 'Jarvis' + Pre-roll"; color: "#6a8894"; font.pixelSize: 10 }
                            }

                            Text {
                                text: "ADAPTIVE NOISE CANCELING ACTIVE";
                                color: "#31e6b0";
                                font.pixelSize: 12;
                                font.bold: true;
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // STARTUP INTRO OVERLAY
    // Crisp vector animation (renders at native resolution, no video
    // scaling blur, no watermark) + the original intro voice track.
    // Ends when BOTH the animation and the audio have finished, or on skip.
    // =========================================================

    function endIntro() {
        if (!window.introActive)
            return;
        introPlayer.stop();
        window.introActive = false;
        // Tell main.py the intro is over so it can calibrate the mic and greet
        bridge.setIntroActive(false);
    }

    Item {
        id: introOverlay
        anchors.fill: parent
        visible: window.introActive

        property bool audioDone: false
        property bool animDone: introAnimation.finished

        function checkDone() {
            if (audioDone && animDone)
                window.endIntro();
        }

        onAudioDoneChanged: checkDone()
        onAnimDoneChanged: checkDone()

        Rectangle {
            anchors.fill: parent
            color: "#010305"
        }

        StartupAnimation {
            id: introAnimation
        }

        MediaPlayer {
            id: introPlayer
            source: introAudioSource
            audioOutput: AudioOutput {
                volume: 1.0
            }

            Component.onCompleted: {
                if (window.introActive)
                    introPlayer.play();
            }

            onMediaStatusChanged: {
                if (introPlayer.mediaStatus === MediaPlayer.EndOfMedia)
                    introOverlay.audioDone = true;
            }

            onErrorOccurred: function(error, errorString) {
                console.log("Intro audio playback notice:", errorString);
                // Never block startup on a missing or broken audio track
                introOverlay.audioDone = true;
            }
        }

        // Safety net: never keep the voice engine waiting longer than this
        Timer {
            interval: 16000
            running: window.introActive
            repeat: false
            onTriggered: window.endIntro()
        }

        // Top-Right Skip Intro Button
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 25
            width: 130
            height: 38
            radius: 19
            color: "#122028"
            border.color: "#38dff5"
            border.width: 1
            opacity: 0.85

            Row {
                anchors.centerIn: parent
                spacing: 8
                Text { text: "SKIP INTRO"; color: "#5de8ff"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
                Text { text: "\u25B6"; color: "#5de8ff"; font.pixelSize: 10 }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: window.endIntro()
            }
        }

        // Keyboard Shortcut to Skip (ESC / Space)
        Item {
            focus: true
            Keys.onEscapePressed: window.endIntro()
            Keys.onSpacePressed: window.endIntro()
        }
    }
}
