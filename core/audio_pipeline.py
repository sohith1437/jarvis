import os
import re
import collections
import numpy as np
import sounddevice as sd
from scipy.io.wavfile import write
from faster_whisper import WhisperModel

from config import (
    SAMPLE_RATE,
    CHUNK_DURATION,
    SILENCE_DURATION,
    MIN_RECORD_SECONDS,
    MAX_RECORD_SECONDS,
    PRE_ROLL_SECONDS,
    POST_ROLL_SECONDS,
    DEFAULT_SPEECH_THRESHOLD,
    DEFAULT_SILENCE_THRESHOLD,
    THRESHOLD_FLOOR,
    THRESHOLD_CEILING,
    AUDIO_FILE,
    WHISPER_MODEL,
    WHISPER_DEVICE,
    WHISPER_COMPUTE_TYPE,
    WHISPER_INITIAL_PROMPT,
    WAKE_WORDS
)

# Global Whisper instance
_whisper_instance = None
_ambient_noise_level = DEFAULT_SPEECH_THRESHOLD


def get_whisper_model():
    """Lazy load or return initialized faster-whisper model."""
    global _whisper_instance
    if _whisper_instance is None:
        print("🧠 Loading faster-whisper model...")
        _whisper_instance = WhisperModel(
            WHISPER_MODEL,
            device=WHISPER_DEVICE,
            compute_type=WHISPER_COMPUTE_TYPE
        )
        print("✅ faster-whisper model loaded successfully.")
    return _whisper_instance


def calibrate_ambient_noise():
    """
    Calibrate ambient noise level over ~1s to adaptively tune the speech threshold.
    Must be called while the room is quiet (i.e. AFTER the startup intro audio has ended).
    Uses the median of 100ms chunk levels so a single click or cough can't inflate it.
    """
    global _ambient_noise_level
    try:
        chunk_samples = int(SAMPLE_RATE * CHUNK_DURATION)
        sample_count = chunk_samples * 10
        recorded = sd.rec(
            sample_count,
            samplerate=SAMPLE_RATE,
            channels=1,
            dtype="float32"
        )
        sd.wait()
        chunks = recorded[:, 0].reshape(10, chunk_samples)
        chunk_levels = np.sqrt(np.mean(chunks ** 2, axis=1))
        rms = float(np.median(chunk_levels))
        # Threshold = baseline * 2.5, kept inside [THRESHOLD_FLOOR, THRESHOLD_CEILING]
        _ambient_noise_level = max(THRESHOLD_FLOOR, min(rms * 2.5, THRESHOLD_CEILING))
        print(f"🎙️ Ambient noise calibrated: baseline RMS={rms:.4f} -> threshold={_ambient_noise_level:.4f}")
    except Exception as e:
        print(f"⚠️ Ambient calibration fallback: {e}")
        _ambient_noise_level = DEFAULT_SPEECH_THRESHOLD
    return _ambient_noise_level


def record_audio_stream(max_seconds=MAX_RECORD_SECONDS, speech_threshold=None, silence_duration=SILENCE_DURATION):
    """
    Advanced speech recording pipeline with:
    - Pre-roll ring buffer (0.4s preceding speech) to never truncate the first syllable
    - Adaptive speech/silence detection
    - Post-roll hangover to never truncate the trailing word
    """
    threshold = speech_threshold if speech_threshold is not None else _ambient_noise_level
    silence_threshold = max(0.006, threshold * 0.65)

    chunk_samples = int(SAMPLE_RATE * CHUNK_DURATION)
    max_chunks = int(max_seconds / CHUNK_DURATION)
    required_silence_chunks = int(silence_duration / CHUNK_DURATION)
    pre_roll_chunks_count = max(2, int(PRE_ROLL_SECONDS / CHUNK_DURATION))
    post_roll_chunks_count = max(1, int(POST_ROLL_SECONDS / CHUNK_DURATION))

    pre_roll_buffer = collections.deque(maxlen=pre_roll_chunks_count)
    speech_chunks = []
    post_roll_chunks = []

    speech_started = False
    silence_chunks = 0

    try:
        with sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=1,
            dtype="float32",
            blocksize=chunk_samples
        ) as stream:
            for _ in range(max_chunks):
                data, _ = stream.read(chunk_samples)
                audio_chunk = data[:, 0].copy()
                volume = float(np.sqrt(np.mean(audio_chunk ** 2)))

                if not speech_started:
                    pre_roll_buffer.append(audio_chunk)
                    if volume > threshold:
                        speech_started = True
                        print("🗣️ Voice detected...")
                        # Transfer all pre-roll audio so the first syllable is preserved
                        speech_chunks.extend(list(pre_roll_buffer))
                        silence_chunks = 0
                else:
                    speech_chunks.append(audio_chunk)

                    if volume < silence_threshold:
                        silence_chunks += 1
                        post_roll_chunks.append(audio_chunk)
                        if silence_chunks >= required_silence_chunks:
                            print("🔇 Speech concluded.")
                            break
                    else:
                        silence_chunks = 0
                        post_roll_chunks.clear()

    except Exception as error:
        print(f"❌ Microphone recording error: {error}")
        return False

    if not speech_started or not speech_chunks:
        return False

    # Concatenate all recorded chunks
    audio = np.concatenate(speech_chunks)
    duration = len(audio) / SAMPLE_RATE

    if duration < MIN_RECORD_SECONDS:
        return False

    # Save to standard 16-bit PCM WAV
    write(
        str(AUDIO_FILE),
        SAMPLE_RATE,
        (np.clip(audio, -1.0, 1.0) * 32767).astype(np.int16)
    )
    return True


def transcribe_audio():
    """Transcribe AUDIO_FILE using primed faster-whisper model."""
    if not AUDIO_FILE.exists():
        return ""

    try:
        model = get_whisper_model()
        segments, info = model.transcribe(
            str(AUDIO_FILE),
            language="en",
            beam_size=5,
            initial_prompt=WHISPER_INITIAL_PROMPT,
            vad_filter=True,
            vad_parameters={
                "min_silence_duration_ms": 400,
                "speech_pad_ms": 250
            },
            condition_on_previous_text=False
        )

        text_parts = [s.text.strip() for s in segments if s.text.strip()]
        full_text = " ".join(text_parts).strip()
        return full_text

    except Exception as error:
        print(f"❌ Whisper transcription error: {error}")
        return ""
    finally:
        cleanup_audio_file()


def cleanup_audio_file():
    """Remove temporary audio file safely."""
    try:
        if AUDIO_FILE.exists():
            os.remove(AUDIO_FILE)
    except Exception:
        pass


def levenshtein_distance(s1, s2):
    """Compute standard Levenshtein distance between two strings."""
    if len(s1) < len(s2):
        return levenshtein_distance(s2, s1)
    if len(s2) == 0:
        return len(s1)
    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row
    return previous_row[-1]


def is_wake_word_detected(text):
    """
    Robust Wake Word Detection:
    - Normalizes punctuation, lowercases
    - Direct exact substring matching
    - Direct alias matching (Charis, Jervis, etc.)
    - Levenshtein distance <= 1 for single-token queries
    """
    if not text:
        return False

    cleaned = re.sub(r"[^\w\s]", "", text.lower()).strip()
    words = cleaned.split()

    if not words:
        return False

    # 1. Direct match in text or words
    if "jarvis" in cleaned:
        return True

    # 2. Known alias check
    for alias in WAKE_WORDS:
        if alias in words or alias in cleaned:
            return True

    # 3. Fuzzy distance matching for any word against "jarvis"
    for word in words:
        if len(word) >= 4 and levenshtein_distance(word, "jarvis") <= 1:
            return True

    return False
