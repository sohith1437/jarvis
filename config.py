import json
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parent
ASSETS_DIR = BASE_DIR / "assets"
STATE_FILE = BASE_DIR / "dashboard_state.json"
SETTINGS_FILE = BASE_DIR / "settings.json"
AUDIO_FILE = BASE_DIR / "jarvis_audio.wav"
INTRO_VIDEO_PATH = ASSETS_DIR / "intro.mp4"
INTRO_AUDIO_PATH = ASSETS_DIR / "intro_audio.wav"

# Dashboard <-> voice engine intro handshake (via dashboard_state.json "intro_active")
INTRO_STALE_SECONDS = 45     # An intro flag older than this is treated as stale (e.g. dashboard crashed)
INTRO_STARTUP_GRACE = 12.0   # How long main.py waits for the dashboard to announce its intro
INTRO_POST_SILENCE = 0.8     # Let the intro audio tail die out before calibrating the mic

# Audio & Recording
SAMPLE_RATE = 16000
CHUNK_DURATION = 0.1        # 100ms chunks
SILENCE_DURATION = 1.0      # 1.0s of continuous silence ends recording
MIN_RECORD_SECONDS = 0.5    # Minimum valid voice recording
MAX_RECORD_SECONDS = 12.0   # Maximum recording timeout
PRE_ROLL_SECONDS = 0.4      # Keep 400ms of audio before speech trigger so words like "Jarvis" are never clipped
POST_ROLL_SECONDS = 0.3     # Keep 300ms after silence trigger to prevent cutoffs

# Adaptive threshold defaults
DEFAULT_SPEECH_THRESHOLD = 0.014
DEFAULT_SILENCE_THRESHOLD = 0.009
THRESHOLD_FLOOR = 0.010     # Never calibrate below this (mic self-noise)
THRESHOLD_CEILING = 0.022   # Never calibrate above this, so normal speech can always cross it

# Whisper Configuration
WHISPER_MODEL = "base"
WHISPER_DEVICE = "cpu"
WHISPER_COMPUTE_TYPE = "int8"
WHISPER_INITIAL_PROMPT = (
    "Jarvis, J.A.R.V.I.S., open Chrome, VS Code, File Explorer, Notepad, "
    "YouTube, Google, search, system info, screenshot, volume, sleep, mute."
)

# Ollama Local AI
OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_TAGS_URL = "http://localhost:11434/api/tags"
OLLAMA_MODEL = "llama3.2:3b"
OLLAMA_TIMEOUT = 120

# TTS Defaults
DEFAULT_VOICE_RATE = 175
DEFAULT_VOICE_VOLUME = 1.0

# Wake Word List & Phonetic / Transcription Aliases
WAKE_WORDS = [
    "jarvis",
    "charis",
    "jervis",
    "javis",
    "chavis",
    "jarves",
    "travis",
    "darvis",
    "service"
]

DEFAULT_SETTINGS = {
    "voice_rate": DEFAULT_VOICE_RATE,
    "voice_volume": DEFAULT_VOICE_VOLUME,
    "speech_threshold": DEFAULT_SPEECH_THRESHOLD,
    "wake_word_sensitivity": "normal",
    "skip_intro_startup": False
}


def load_settings():
    if not SETTINGS_FILE.exists():
        save_settings(DEFAULT_SETTINGS)
        return dict(DEFAULT_SETTINGS)
    try:
        with open(SETTINGS_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            merged = dict(DEFAULT_SETTINGS)
            merged.update(data)
            return merged
    except Exception:
        return dict(DEFAULT_SETTINGS)


def save_settings(settings):
    try:
        with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
            json.dump(settings, f, indent=4)
        return True
    except Exception as e:
        print(f"Error saving settings: {e}")
        return False
