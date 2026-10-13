import sys
from core.audio_pipeline import is_wake_word_detected
from core.system_info import get_system_telemetry, check_services
from core.state_manager import update_state, read_state, log_activity, record_conversation
from commands import execute_command
import main

print("--- TEST 1: WAKE WORD ACCURACY ---")
test_cases = [
    ("Jarvis", True),
    ("jarvis", True),
    ("JARVIS", True),
    ("Jarvis.", True),
    ("Charis", True),
    ("Chariss", True),
    ("jervis", True),
    ("hello jarvis", True),
    ("jarvis open chrome", True),
    ("open chrome", False),
    ("what is the time", False),
    ("random noise", False)
]
for phrase, expected in test_cases:
    res = is_wake_word_detected(phrase)
    assert res == expected, f"Failed on '{phrase}': got {res}, expected {expected}"
    print(f"  [OK] '{phrase}' -> {res}")

print("\n--- TEST 2: TELEMETRY & SERVICES ---")
telem = get_system_telemetry(force=True)
print(f"  [OK] CPU: {telem.get('cpu')}%")
print(f"  [OK] RAM: {telem.get('ram')}% ({telem.get('ram_text')})")
print(f"  [OK] GPU: {telem.get('gpu')}% ({telem.get('gpu_temp')}°C, VRAM: {telem.get('vram_text')})")
print(f"  [OK] DISK: {telem.get('disk')}% ({telem.get('disk_text')})")

serv = check_services()
print(f"  [OK] Services: Ollama={serv['ollama']}, Whisper={serv['whisper']}, TTS={serv['tts']}, Mic={serv['mic']}")

print("\n--- TEST 3: COMMANDS DISPATCHER ---")
handled = execute_command("what time is it")
print(f"  [OK] 'what time is it' handled: {handled}")
assert handled is True

handled_calc = execute_command("system information")
print(f"  [OK] 'system information' handled: {handled_calc}")
assert handled_calc is True

print("\n--- TEST 4: OLLAMA BRAIN ---")
reply = main.ask_jarvis("Say hello boss in 4 words")
print(f"  [OK] Ollama reply: {reply}")
assert len(reply) > 0

print("\n--- TEST 5: STATE & CONVERSATION HISTORY ---")
record_conversation("YOU", "What is the time?")
record_conversation("JARVIS", "It is 03:30 PM, boss.")
st = read_state()
print(f"  [OK] History entries in state: {len(st.get('history', []))}")
assert len(st.get('history', [])) >= 2

print("\n=== ALL CORE PIPELINE TESTS PASSED! ===")
