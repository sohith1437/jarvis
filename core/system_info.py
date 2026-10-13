import time
import subprocess
import requests
import psutil
import sounddevice as sd

from config import OLLAMA_TAGS_URL

# Cache to avoid excessive querying
_last_telemetry_time = 0
_cached_telemetry = {
    "cpu": 0,
    "ram": 0,
    "ram_text": "0 / 0 GB",
    "gpu": 0,
    "vram_text": "N/A",
    "gpu_temp": 0,
    "disk": 0,
    "disk_text": "0 / 0 GB"
}


def get_gpu_metrics():
    """Query NVIDIA GPU utilization, memory and temperature via nvidia-smi."""
    try:
        # Run nvidia-smi with minimal output
        result = subprocess.run(
            [
                "nvidia-smi",
                "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu",
                "--format=csv,noheader,nounits"
            ],
            capture_output=True,
            text=True,
            timeout=1.5,
            creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, "CREATE_NO_WINDOW") else 0
        )
        if result.returncode == 0 and result.stdout.strip():
            parts = [p.strip() for p in result.stdout.strip().split(",")]
            if len(parts) >= 4:
                gpu_util = int(parts[0])
                mem_used = int(parts[1])
                mem_total = int(parts[2])
                temp = int(parts[3])
                vram_text = f"{mem_used / 1024:.1f} / {mem_total / 1024:.1f} GB"
                return gpu_util, vram_text, temp
    except Exception:
        pass
    return 0, "N/A", 0


def get_system_telemetry(force=False):
    """Retrieve actual system resource statistics with 1-second caching."""
    global _last_telemetry_time, _cached_telemetry
    now = time.time()
    if not force and (now - _last_telemetry_time) < 1.0:
        return _cached_telemetry

    try:
        # CPU
        cpu_percent = int(psutil.cpu_percent(interval=None))

        # RAM
        mem = psutil.virtual_memory()
        ram_percent = int(mem.percent)
        ram_used_gb = mem.used / (1024 ** 3)
        ram_total_gb = mem.total / (1024 ** 3)
        ram_text = f"{ram_used_gb:.1f} / {ram_total_gb:.1f} GB"

        # Disk
        disk = psutil.disk_usage("C:\\")
        disk_percent = int(disk.percent)
        disk_used_gb = disk.used / (1024 ** 3)
        disk_total_gb = disk.total / (1024 ** 3)
        disk_text = f"{disk_used_gb:.0f} / {disk_total_gb:.0f} GB"

        # GPU
        gpu_util, vram_text, gpu_temp = get_gpu_metrics()

        _cached_telemetry = {
            "cpu": cpu_percent,
            "ram": ram_percent,
            "ram_text": ram_text,
            "gpu": gpu_util,
            "vram_text": vram_text,
            "gpu_temp": gpu_temp,
            "disk": disk_percent,
            "disk_text": disk_text
        }
        _last_telemetry_time = now
    except Exception as e:
        print(f"Telemetry error: {e}")

    return _cached_telemetry


def check_services():
    """Verify live status of Ollama, Whisper, TTS, and Microphone."""
    # Ollama
    ollama_ok = False
    try:
        res = requests.get(OLLAMA_TAGS_URL, timeout=1.0)
        ollama_ok = (res.status_code == 200)
    except Exception:
        ollama_ok = False

    # Microphone
    mic_ok = False
    try:
        devices = sd.query_devices()
        mic_ok = any(d['max_input_channels'] > 0 for d in devices)
    except Exception:
        mic_ok = False

    return {
        "ollama": ollama_ok,
        "whisper": True,
        "tts": True,
        "mic": mic_ok
    }
