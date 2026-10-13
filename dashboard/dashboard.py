import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Slot, Signal, Property, QTimer, QUrl

# Ensure parent directory is in sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from config import (
    STATE_FILE,
    INTRO_VIDEO_PATH,
    load_settings,
    save_settings
)
from core.state_manager import (
    read_state,
    write_state,
    update_state,
    log_activity,
    enqueue_command,
    clear_activity
)
from commands import execute_command


class DashboardBridge(QObject):
    stateUpdated = Signal()
    settingsChanged = Signal()

    def __init__(self):
        super().__init__()
        self._state_data = read_state()
        self._settings = load_settings()

    @Slot(str)
    def executeCommand(self, cmd_text):
        """Execute a PC or assistant command directly from UI."""
        print(f"🖥️ UI Triggered Command: {cmd_text}")
        log_activity(f"UI Command: {cmd_text}", "command")

        # Attempt immediate local execution
        handled = execute_command(cmd_text)
        if not handled:
            # Enqueue for assistant
            enqueue_command(cmd_text)

    @Slot(str, float)
    def updateSetting(self, key, value):
        """Update and persist a user setting."""
        print(f"⚙️ Setting updated: {key} = {value}")
        self._settings[key] = value
        save_settings(self._settings)
        log_activity(f"Setting changed: {key}", "system")

    @Slot(result="QVariantMap")
    def getSettings(self):
        """Return persisted settings dictionary."""
        self._settings = load_settings()
        return self._settings

    @Slot()
    def clearLogs(self):
        """Clear activity history."""
        clear_activity()

    @Slot()
    def requestSleep(self):
        """Request assistant to enter sleep mode."""
        update_state(state="SLEEPING")
        log_activity("Sleep requested via UI", "system")

    @Slot()
    def requestWake(self):
        """Request assistant to wake up."""
        update_state(state="LISTENING")
        log_activity("Wake requested via UI", "system")


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("J.A.R.V.I.S.")
    app.setOrganizationName("StarkIndustries")

    engine = QQmlApplicationEngine()

    bridge = DashboardBridge()
    engine.rootContext().setContextProperty("bridge", bridge)
    engine.rootContext().setContextProperty(
        "introVideoSource",
        QUrl.fromLocalFile(str(INTRO_VIDEO_PATH)).toString()
    )

    qml_file = Path(__file__).parent / "main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        print("❌ Error: Could not load main.qml")
        sys.exit(-1)

    root = engine.rootObjects()[0]

    def sync_dashboard():
        try:
            data = read_state()
            root.setProperty("jarvisState", data.get("state", "SLEEPING"))
            root.setProperty("userMessage", data.get("user_text", ""))
            root.setProperty("jarvisMessage", data.get("jarvis_text", ""))

            # Update lists and telemetry
            root.setProperty("historyList", data.get("history", []))
            root.setProperty("activityList", data.get("activity", []))
            root.setProperty("telemetry", data.get("telemetry", {}))
            root.setProperty("services", data.get("services", {}))
        except Exception as e:
            print(f"Sync error: {e}")

    timer = QTimer()
    timer.timeout.connect(sync_dashboard)
    timer.start(250)

    # Initial sync
    sync_dashboard()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()