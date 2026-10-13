# J.A.R.V.I.S. — Personal Local AI Voice Assistant

A local, private, and fully autonomous voice assistant with an Iron Man-inspired cinematic HUD dashboard, powered by **faster-whisper**, **Ollama (`llama3.2:3b`)**, **pyttsx3**, and **PySide6 / Qt Quick**.

---

## 🌟 Key Features

* **Cinematic Startup Sequence**: Authentic Iron Man Arc Reactor boot sequence with high-resolution video and audio, transitioning directly into the holographic desktop HUD.
* **Rock-Solid Voice & Wake Word Recognition**:
  * Dual-phase wake engine matching `"Jarvis"` with punctuation stripping, normalization, and phonetic fault-tolerance (resolves mishearings like *"Charis"*).
  * **Pre-Roll Audio Ring Buffer**: 400ms rolling acoustic buffer preserves the initial syllable of speech, preventing clipped phrases.
  * **Adaptive Noise Floor Calibration**: Dynamically measures ambient room sound to set optimal speech thresholds.
* **Continuous Active Conversation**: Say `"Jarvis"` once to wake; speak subsequent commands freely without repeating the wake word until you say `"go to sleep"`.
* **100% Local AI Brain**: Powered by local Ollama running `llama3.2:3b` with GPU/CPU acceleration.
* **Real PC Hardware & App Control**:
  * Applications: Chrome, Visual Studio Code, Notepad, Calculator, File Explorer.
  * Web & Media: Direct Google search, YouTube search, URL opening.
  * System Control: Screenshots to desktop, system volume up/down/mute, workstation locking, sleep/restart/shutdown.
* **Interactive HUD Dashboard**:
  * **Iron Man Arc Reactor**: Real-time animated reactor core with multi-stage states (*LISTENING*, *THINKING*, *SPEAKING*, *SLEEPING*, *OFFLINE*).
  * **Real Conversation History**: Scrollable chat panel displaying historical interactions with timestamps.
  * **Command Center**: Categorized clickable command launcher with instantaneous execution feedback.
  * **Real Hardware Telemetry**: Live CPU load, RAM usage, NVIDIA RTX 3050 GPU utilization, VRAM stats, and GPU core temperature.
  * **Event Activity Log**: Chronological audit trail of wake-word events, executed commands, and AI queries.
  * **Dynamic Settings**: Live voice speech rate, volume, and wake sensitivity.

---

## 🏗️ Project Architecture

```
jarvis/
├── main.py                     # Main assistant voice loop, wake word & LLM engine
├── commands.py                 # Windows PC automation and application controller
├── config.py                   # Central system configuration and settings persistence
├── dashboard_state.json        # Atomic inter-process state & telemetry bus
├── settings.json               # Persisted user preferences
├── requirements.txt            # Python dependencies
├── README.md                   # Documentation
│
├── core/
│   ├── __init__.py
│   ├── audio_pipeline.py       # Pre-roll recording, VAD & faster-whisper transcription
│   ├── state_manager.py        # Safe atomic state & event logging
│   └── system_info.py          # Real-time CPU/RAM/GPU telemetry & service health
│
├── dashboard/
│   ├── dashboard.py            # PySide6 application runtime & Python-QML Bridge
│   ├── main.qml                # Multi-view Iron Man HUD interface & intro video player
│   └── components/
│       ├── JarvisCore.qml      # Segmented Arc Reactor & HUD reticle component
│       └── StartupAnimation.qml# Ambient reactor animation
│
└── assets/
    ├── intro.mp4               # Cinematic startup sequence video & audio
    └── frame_*.png             # HUD design reference frames
```

---

## 💻 Hardware & System Requirements

* **Operating System**: Windows 10 / Windows 11 (64-bit)
* **Processor**: Intel Core i7-12650H (or equivalent modern multi-core CPU)
* **Memory**: 16 GB RAM recommended
* **Graphics**: NVIDIA GeForce RTX 3050 Laptop GPU (4 GB VRAM) or equivalent
* **Local Software**: [Ollama for Windows](https://ollama.com/)

---

## 🚀 Setup & Installation

### 1. Set Up Python Virtual Environment
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2. Configure Local Ollama AI Model
Ensure Ollama is running and pull the lightweight 3B model:
```powershell
ollama pull llama3.2:3b
ollama serve
```

---

## 🎙️ How to Run J.A.R.V.I.S.

You can run the Dashboard HUD and the Voice Assistant in parallel:

### Start the Cinematic Dashboard:
```powershell
.\venv\Scripts\python.exe dashboard\dashboard.py
```
* The cinematic intro video will play on launch. Press `ESC` or click `SKIP INTRO` at any time to transition directly into the HUD.

### Start the Voice Assistant Engine:
```powershell
.\venv\Scripts\python.exe main.py
```

---

## 🗣️ Supported Voice Commands

| Category | Sample Spoken Commands |
| :--- | :--- |
| **Wake & Sleep** | `"Jarvis"`, `"Go to sleep"`, `"Standby"`, `"Goodbye"` |
| **Web & Search** | `"Open Chrome"`, `"Open YouTube"`, `"Search YouTube for Python tutorials"`, `"Search Google for quantum computing"` |
| **Applications** | `"Open VS Code"`, `"Open Notepad"`, `"Open Calculator"`, `"Open File Explorer"` |
| **System** | `"What time is it?"`, `"System information"`, `"Take a screenshot"`, `"Lock PC"` |
| **Audio** | `"Volume up"`, `"Volume down"`, `"Mute"` |
| **General AI** | Ask any general question: *"Explain general relativity in two sentences"*, *"Help me write a Python function"*, etc. |

---

## 🛠️ Troubleshooting

1. **"Charis" or misrecognized wake word:**
   The upgraded `core/audio_pipeline.py` includes a 400ms pre-roll buffer, speech priming via `initial_prompt`, and phonetic/distance matching to eliminate misrecognized wake words.
2. **Ollama unreachable:**
   Verify `ollama serve` is running in the background or launch the Ollama Windows tray app.
3. **Microphone permission:**
   Ensure microphone access is enabled in Windows Settings -> Privacy & Security -> Microphone.
