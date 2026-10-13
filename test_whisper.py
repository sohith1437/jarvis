import sounddevice as sd
import numpy as np
from scipy.io.wavfile import write
from faster_whisper import WhisperModel

SAMPLE_RATE = 16000
DURATION = 5
AUDIO_FILE = "test.wav"

print("Loading Whisper model...")

model = WhisperModel(
    "base",
    device="cpu",
    compute_type="int8"
)

print("Whisper loaded!")
print("\n🎤 Speak now...")

audio = sd.rec(
    int(DURATION * SAMPLE_RATE),
    samplerate=SAMPLE_RATE,
    channels=1,
    dtype="float32"
)

sd.wait()

audio = np.squeeze(audio)

write(
    AUDIO_FILE,
    SAMPLE_RATE,
    (audio * 32767).astype(np.int16)
)

print("Processing...")

segments, info = model.transcribe(
    AUDIO_FILE,
    language="en"
)

text = ""

for segment in segments:
    text += segment.text

print("\n📝 You said:")
print(text.strip())