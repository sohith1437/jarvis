import os
import json
import tempfile
from datetime import datetime
from config import STATE_FILE
from core.system_info import get_system_telemetry, check_services

MAX_HISTORY = 60
MAX_ACTIVITY = 60


def get_default_state():
    return {
        "state": "SLEEPING",
        "user_text": "",
        "jarvis_text": "JARVIS is ready, boss.",
        "history": [],
        "activity": [
            {
                "time": datetime.now().strftime("%H:%M:%S"),
                "event": "JARVIS System Initialized",
                "type": "system"
            }
        ],
        "telemetry": get_system_telemetry(force=True),
        "services": check_services(),
        "command_queue": []
    }


def read_state():
    """Safely read dashboard state from JSON file."""
    if not STATE_FILE.exists():
        initial = get_default_state()
        write_state(initial)
        return initial

    try:
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            # Ensure essential keys exist
            if "history" not in data:
                data["history"] = []
            if "activity" not in data:
                data["activity"] = []
            if "telemetry" not in data:
                data["telemetry"] = get_system_telemetry()
            if "services" not in data:
                data["services"] = check_services()
            if "command_queue" not in data:
                data["command_queue"] = []
            return data
    except Exception:
        return get_default_state()


def write_state(data):
    """Atomically write dashboard state to avoid read/write collisions."""
    try:
        dir_name = STATE_FILE.parent
        with tempfile.NamedTemporaryFile("w", dir=dir_name, delete=False, encoding="utf-8") as tf:
            json.dump(data, tf, indent=2, ensure_ascii=False)
            temp_name = tf.name
        # Atomic replace
        os.replace(temp_name, STATE_FILE)
        return True
    except Exception as e:
        print(f"Error writing state: {e}")
        return False


def update_state(state=None, user_text=None, jarvis_text=None, add_history=None, add_activity=None):
    """Update state fields and sync to disk."""
    data = read_state()
    if state is not None:
        data["state"] = state
    if user_text is not None:
        data["user_text"] = user_text
    if jarvis_text is not None:
        data["jarvis_text"] = jarvis_text

    if add_history:
        # role: 'YOU' or 'JARVIS', text: str
        now_time = datetime.now().strftime("%I:%M %p")
        data["history"].append({
            "role": add_history.get("role", "YOU"),
            "text": add_history.get("text", ""),
            "time": now_time
        })
        if len(data["history"]) > MAX_HISTORY:
            data["history"] = data["history"][-MAX_HISTORY:]

    if add_activity:
        now_time = datetime.now().strftime("%H:%M:%S")
        data["activity"].insert(0, {
            "time": now_time,
            "event": add_activity.get("event", ""),
            "type": add_activity.get("type", "system")
        })
        if len(data["activity"]) > MAX_ACTIVITY:
            data["activity"] = data["activity"][:MAX_ACTIVITY]

    # Update telemetry and services
    data["telemetry"] = get_system_telemetry()
    data["services"] = check_services()

    write_state(data)
    return data


def log_activity(event, event_type="system"):
    """Helper to log activity directly."""
    return update_state(add_activity={"event": event, "type": event_type})


def record_conversation(role, text):
    """Helper to record user/jarvis speech to history."""
    return update_state(add_history={"role": role, "text": text})


def enqueue_command(command_str):
    """Add a command triggered from the UI to the queue."""
    data = read_state()
    data["command_queue"].append(command_str)
    write_state(data)


def pop_command():
    """Pop the oldest queued UI command for execution."""
    data = read_state()
    if data.get("command_queue"):
        cmd = data["command_queue"].pop(0)
        write_state(data)
        return cmd
    return None


def clear_activity():
    """Clear activity logs."""
    data = read_state()
    data["activity"] = [{
        "time": datetime.now().strftime("%H:%M:%S"),
        "event": "Activity Log Cleared",
        "type": "system"
    }]
    write_state(data)
