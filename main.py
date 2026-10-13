import sys
import time
import requests
import pyttsx3

from config import (
    OLLAMA_URL,
    OLLAMA_MODEL,
    OLLAMA_TIMEOUT,
    INTRO_STARTUP_GRACE,
    INTRO_POST_SILENCE,
    load_settings
)
from commands import handle_pc_command, execute_command
from core.state_manager import (
    update_state,
    log_activity,
    record_conversation,
    pop_command,
    is_intro_active
)
from core.audio_pipeline import (
    get_whisper_model,
    calibrate_ambient_noise,
    record_audio_stream,
    transcribe_audio,
    is_wake_word_detected,
    cleanup_audio_file
)

# ==========================================
# TEXT TO SPEECH INITIALIZATION
# ==========================================

settings = load_settings()
engine = pyttsx3.init()
engine.setProperty("rate", settings.get("voice_rate", 175))
engine.setProperty("volume", settings.get("voice_volume", 1.0))


def apply_tts_settings():
    """Apply any updated settings to pyttsx3 engine."""
    current_settings = load_settings()
    try:
        engine.setProperty("rate", current_settings.get("voice_rate", 175))
        engine.setProperty("volume", current_settings.get("voice_volume", 1.0))
    except Exception as e:
        print(f"TTS setting update error: {e}")


def speak(text):
    """Speak text aloud and sync state with dashboard."""
    if not text:
        return

    print(f"\n🤖 JARVIS: {text}")

    # Sync state and record to conversation history
    update_state(
        state="SPEAKING",
        jarvis_text=text
    )
    record_conversation("JARVIS", text)

    apply_tts_settings()

    try:
        engine.say(text)
        engine.runAndWait()
    except Exception as e:
        print(f"TTS error: {e}")

    # Return to listening state after speaking
    update_state(state="LISTENING")


# ==========================================
# ASK LOCAL AI (OLLAMA)
# ==========================================

def ask_jarvis(question):
    """Query local Ollama instance with llama3.2:3b."""
    print(f"\n🧠 Consulting Ollama ({OLLAMA_MODEL})...")
    update_state(
        state="THINKING",
        user_text=question,
        jarvis_text="Thinking..."
    )

    prompt = f"""You are JARVIS, a highly capable personal AI assistant inspired by Tony Stark's AI.
You are talking to your creator/boss.
Answer naturally, accurately, and concisely.
Your reply will be spoken aloud via text-to-speech, so avoid markdown formatting, asterisks, bullet points, or code blocks unless explicitly requested.

User: {question}
JARVIS:"""

    try:
        response = requests.post(
            OLLAMA_URL,
            json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False
            },
            timeout=OLLAMA_TIMEOUT
        )
        response.raise_for_status()
        data = response.json()
        reply = data.get("response", "").strip()

        # Clean any leading/trailing quotes or markdown
        reply = reply.replace("**", "").replace("*", "")
        log_activity("AI Response Generated", "ai")
        return reply

    except requests.exceptions.ConnectionError:
        log_activity("Ollama connection failed", "system")
        return "I cannot connect to my local AI brain. Please make sure Ollama is running."

    except requests.exceptions.Timeout:
        log_activity("Ollama query timed out", "system")
        return "My neural network is taking longer than expected to respond. Please try again, boss."

    except Exception as error:
        print(f"❌ Ollama error: {error}")
        log_activity(f"Ollama error: {error}", "system")
        return "I encountered an error while processing that request, boss."


# ==========================================
# COMMAND CLASSIFICATION HELPERS
# ==========================================

def is_sleep_command(command):
    cleaned = command.lower().strip().replace("-", " ")
    cleaned = " ".join(cleaned.split())

    sleep_phrases = [
        "go to sleep",
        "go sleep",
        "sleep",
        "sleep jarvis",
        "stop listening",
        "standby",
        "enter sleep mode"
    ]
    return any(p == cleaned or cleaned.startswith(p) for p in sleep_phrases)


def is_exit_command(command):
    cleaned = command.lower().strip().replace("-", " ")
    cleaned = " ".join(cleaned.split())

    exit_phrases = [
        "goodbye",
        "good bye",
        "exit",
        "quit",
        "turn off jarvis",
        "stop jarvis",
        "power off jarvis",
        "shutdown jarvis"
    ]
    return any(p in cleaned for p in exit_phrases)


# ==========================================
# WAKE WORD LISTENER
# ==========================================

def wait_for_wake_word():
    """Wait for 'Jarvis' wake word detection with optimized pipeline."""
    update_state(
        state="SLEEPING",
        jarvis_text="Standing by. Say 'Jarvis' to wake me."
    )

    print("\n🟢 JARVIS is in Standby / Sleep mode.")
    print("   Say 'Jarvis' to wake me.")

    while True:
        # Check if UI sent an immediate wake or command
        pending_ui_cmd = pop_command()
        if pending_ui_cmd:
            print(f"⚡ Processing UI command: {pending_ui_cmd}")
            update_state(state="LISTENING")
            execute_command(pending_ui_cmd, speak)
            return True

        # Short 3.5-second recording window for wake word
        recorded = record_audio_stream(
            max_seconds=3.5,
            silence_duration=0.8
        )

        if not recorded:
            continue

        text = transcribe_audio()
        if not text:
            continue

        print(f"👂 Standby heard: \"{text}\"")

        if is_wake_word_detected(text):
            print("✨ Wake word verified!")
            log_activity("Wake word 'Jarvis' detected", "voice")
            update_state(state="LISTENING")
            cleanup_audio_file()
            return True

        cleanup_audio_file()


# ==========================================
# ACTIVE CONVERSATION MODE
# ==========================================

def conversation_mode():
    """Continuous conversation loop without needing repeated wake words."""
    print("\n🔵 JARVIS ACTIVE CONVERSATION")
    print("   Speak commands or questions naturally.")
    print("   Say 'go to sleep' to enter standby.")
    print("   Say 'goodbye' to go offline.")

    speak("Yes boss. I'm listening.")

    while True:
        # 1. Process any queued commands from Dashboard UI buttons first
        pending_cmd = pop_command()
        if pending_cmd:
            print(f"⚡ Executing dashboard command: {pending_cmd}")
            execute_command(pending_cmd, speak)
            continue

        # 2. Record voice command
        update_state(state="LISTENING")
        print("\n🎤 Listening for command...")

        recorded = record_audio_stream(
            max_seconds=12.0,
            silence_duration=1.0
        )

        if not recorded:
            continue

        update_state(state="THINKING")
        command = transcribe_audio()
        cleanup_audio_file()

        if not command:
            continue

        print(f"\n👤 You: {command}")
        update_state(
            state="THINKING",
            user_text=command
        )
        record_conversation("YOU", command)
        log_activity(f"Command received: '{command}'", "voice")

        command_lower = command.lower()

        # Check for Exit
        if is_exit_command(command_lower):
            speak("Goodbye boss. JARVIS is going offline.")
            update_state(
                state="OFFLINE",
                jarvis_text="JARVIS is offline."
            )
            log_activity("JARVIS went offline", "system")
            return "exit"

        # Check for Sleep
        if is_sleep_command(command_lower):
            speak("Going to sleep, boss.")
            update_state(
                state="SLEEPING",
                jarvis_text="Sleeping. Say 'Jarvis' to wake me."
            )
            log_activity("Entered Standby / Sleep mode", "system")
            return "sleep"

        # Check for PC Commands
        handled = handle_pc_command(command, speak)
        if handled:
            continue

        # Consult local LLM Brain
        ai_reply = ask_jarvis(command)
        speak(ai_reply)


# ==========================================
# STARTUP INTRO HANDSHAKE
# ==========================================

def wait_for_intro_to_finish():
    """
    Block until the dashboard's startup intro has finished or been skipped.

    The dashboard sets "intro_active" in dashboard_state.json. If the dashboard never
    announces an intro (not running, or intro skipped), we stop waiting after a short
    grace period. While waiting we preload the Whisper model so startup stays fast.
    """
    print("\n⏳ Waiting for dashboard intro to finish...")
    started = time.time()
    seen_intro = False
    model_loaded = False

    while True:
        active = is_intro_active()
        if active:
            seen_intro = True
        elif seen_intro:
            break  # Intro played and has now finished or been skipped
        elif time.time() - started > INTRO_STARTUP_GRACE:
            break  # Dashboard never announced an intro

        if not model_loaded:
            try:
                get_whisper_model()  # Preload while the intro plays (no mic or speaker use)
            except Exception as e:
                print(f"⚠️ Whisper preload failed: {e}")
            model_loaded = True
            continue

        time.sleep(0.2)

    # Let the tail of the intro audio die away so the mic calibrates in true silence
    time.sleep(INTRO_POST_SILENCE)
    print("✅ Intro finished. Starting voice engine.")


# ==========================================
# MAIN EXECUTION ENTRY POINT
# ==========================================

def main():
    print("\n" + "=" * 50)
    print("          J.A.R.V.I.S. SYSTEM START")
    print("     Personal Local AI Voice Assistant")
    print("=" * 50)

    # Stay completely silent (no speech, no mic calibration) while the dashboard intro plays
    wait_for_intro_to_finish()

    # Room is quiet now: calibrate the ambient noise floor
    calibrate_ambient_noise()

    update_state(
        state="SLEEPING",
        jarvis_text="JARVIS is online and ready, boss."
    )
    log_activity("JARVIS System Online", "system")

    speak("Hello boss. JARVIS is online.")

    try:
        while True:
            wait_for_wake_word()
            result = conversation_mode()

            if result == "exit":
                break

            if result == "sleep":
                update_state(state="SLEEPING")
                continue

    except KeyboardInterrupt:
        print("\n🛑 Shutdown requested by user.")
    finally:
        cleanup_audio_file()
        update_state(
            state="OFFLINE",
            jarvis_text="JARVIS session ended."
        )
        print("\n" + "=" * 50)
        print("         JARVIS SESSION CONCLUDED")
        print("=" * 50)


if __name__ == "__main__":
    main()