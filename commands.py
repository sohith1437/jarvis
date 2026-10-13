import os
import subprocess
import webbrowser
from datetime import datetime
import platform

try:
    from core.state_manager import log_activity
except Exception:
    def log_activity(event, event_type="system"):
        pass


# ==========================================
# APP CONTROL
# ==========================================

APP_COMMANDS = {
    "chrome": "chrome",
    "google chrome": "chrome",
    "vs code": "code",
    "visual studio code": "code",
    "notepad": "notepad.exe",
    "calculator": "calc.exe",
}


def open_application(app, speak):

    program = APP_COMMANDS.get(app)

    if not program:
        return False

    speak(f"Opening {app}, boss.")

    try:
        if program in ["chrome", "code"]:
            subprocess.Popen(
                ["cmd", "/c", "start", "", program]
            )
        else:
            subprocess.Popen([program])

        return True

    except Exception as error:
        print(f"❌ Could not open {app}: {error}")
        speak(f"I couldn't open {app}, boss.")
        return True


# ==========================================
# CLOSE APPLICATION
# ==========================================

def close_application(app, speak):

    process_names = {
        "chrome": "chrome.exe",
        "google chrome": "chrome.exe",
        "vs code": "Code.exe",
        "visual studio code": "Code.exe",
        "notepad": "notepad.exe",
        "calculator": "CalculatorApp.exe",
    }

    process = process_names.get(app)

    if not process:
        return False

    speak(f"Closing {app}, boss.")

    try:

        subprocess.run(
            ["taskkill", "/F", "/IM", process],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

        return True

    except Exception as error:

        print(f"❌ Could not close {app}: {error}")

        return True


# ==========================================
# HANDLE PC COMMANDS
# ==========================================

def handle_pc_command(command, speak=None):

    if speak is None:
        speak = lambda text: print(f"🤖 JARVIS: {text}")

    command = command.lower().strip()

    # Normalize punctuation
    command = command.replace("-", " ")
    command = " ".join(command.split())


    # ==========================================
    # OPEN YOUTUBE + SEARCH
    # ==========================================

    if "youtube" in command and "search" in command:

        query = command

        if "search youtube for" in query:

            query = query.split(
                "search youtube for",
                1
            )[1].strip()

        elif "search for" in query:

            query = query.split(
                "search for",
                1
            )[1].strip()

        elif "search" in query:

            query = query.split(
                "search",
                1
            )[1].strip()

        query = query.replace(
            "on youtube",
            ""
        ).strip()

        query = query.replace(
            "and",
            "",
            1
        ).strip()

        if query:

            speak(
                f"Searching YouTube for {query}, boss."
            )

            url = (
                "https://www.youtube.com/results"
                "?search_query="
                + query.replace(" ", "+")
            )

            webbrowser.open(url)

            return True


    # ==========================================
    # OPEN YOUTUBE
    # ==========================================

    if "open youtube" in command:

        speak("Opening YouTube, boss.")

        webbrowser.open(
            "https://www.youtube.com"
        )

        return True


    # ==========================================
    # OPEN GOOGLE
    # ==========================================

    if "open google" in command:

        speak("Opening Google, boss.")

        webbrowser.open(
            "https://www.google.com"
        )

        return True


    # ==========================================
    # GOOGLE SEARCH
    # ==========================================

    if "search google for" in command:

        query = command.split(
            "search google for",
            1
        )[1].strip()

        if query:

            speak(
                f"Searching Google for {query}, boss."
            )

            url = (
                "https://www.google.com/search?q="
                + query.replace(" ", "+")
            )

            webbrowser.open(url)

            return True


    # ==========================================
    # YOUTUBE SEARCH
    # ==========================================

    if "search youtube for" in command:

        query = command.split(
            "search youtube for",
            1
        )[1].strip()

        if query:

            speak(
                f"Searching YouTube for {query}, boss."
            )

            url = (
                "https://www.youtube.com/results"
                "?search_query="
                + query.replace(" ", "+")
            )

            webbrowser.open(url)

            return True


    # ==========================================
    # GENERAL SEARCH
    # ==========================================

    if command.startswith("search for"):

        query = command.replace(
            "search for",
            "",
            1
        ).strip()

        if query:

            speak(
                f"Searching for {query}, boss."
            )

            url = (
                "https://www.google.com/search?q="
                + query.replace(" ", "+")
            )

            webbrowser.open(url)

            return True


    # ==========================================
    # OPEN APPLICATIONS
    # ==========================================

    open_phrases = [
        "open ",
        "launch ",
        "start ",
        "run "
    ]

    for phrase in open_phrases:

        if command.startswith(phrase):

            app = command[
                len(phrase):
            ].strip()

            if open_application(
                app,
                speak
            ):
                return True


    # ==========================================
    # SPECIAL OPEN COMMANDS
    # ==========================================

    if (
        "open file explorer" in command
        or
        "open explorer" in command
    ):

        speak(
            "Opening File Explorer, boss."
        )

        subprocess.Popen(
            ["explorer.exe"]
        )

        return True


    # ==========================================
    # CLOSE APPLICATIONS
    # ==========================================

    close_phrases = [
        "close ",
        "exit "
    ]

    for phrase in close_phrases:

        if command.startswith(phrase):

            app = command[
                len(phrase):
            ].strip()

            if close_application(
                app,
                speak
            ):
                return True


    # ==========================================
    # CLOSE SPECIAL APPS
    # ==========================================

    if "close file explorer" in command:

        speak(
            "Closing File Explorer, boss."
        )

        subprocess.run(
            [
                "taskkill",
                "/F",
                "/IM",
                "explorer.exe"
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

        return True


    # ==========================================
    # CURRENT TIME
    # ==========================================

    if (
        "what time is it" in command
        or
        "current time" in command
        or
        "tell me the time" in command
    ):

        current_time = datetime.now().strftime(
            "%I:%M %p"
        )

        speak(
            f"The current time is "
            f"{current_time}, boss."
        )

        return True


    # ==========================================
    # SYSTEM INFORMATION
    # ==========================================

    if (
        "system information" in command
        or
        "computer information" in command
        or
        "my system" in command
    ):

        system = platform.system()
        version = platform.version()
        processor = platform.processor()

        print()
        print("🖥️ SYSTEM INFORMATION")
        print("--------------------------------")
        print(
            f"Operating System: {system}"
        )
        print(
            f"Version: {version}"
        )
        print(
            f"Processor: {processor}"
        )
        print("--------------------------------")

        speak(
            f"You are running {system}."
        )

        return True


    # ==========================================
    # SCREENSHOT
    # ==========================================

    if (
        "take a screenshot" in command
        or
        "take screenshot" in command
        or
        command == "screenshot"
    ):

        speak(
            "Taking a screenshot, boss."
        )

        screenshot_path = os.path.join(
            os.path.expanduser("~"),
            "Desktop",
            "jarvis_screenshot.png"
        )

        try:

            from PIL import ImageGrab

            screenshot = ImageGrab.grab()

            screenshot.save(
                screenshot_path
            )

            speak(
                "Screenshot saved to your desktop."
            )

        except Exception as error:

            print(
                f"Screenshot error: {error}"
            )

            speak(
                "I couldn't take the screenshot."
            )

        return True


    # ==========================================
    # LOCK COMPUTER
    # ==========================================

    if (
        "lock computer" in command
        or
        "lock my computer" in command
        or
        "lock pc" in command
    ):

        speak(
            "Locking your computer, boss."
        )

        subprocess.run(
            [
                "rundll32.exe",
                "user32.dll",
                "LockWorkStation"
            ]
        )

        return True


    # ==========================================
    # SLEEP COMPUTER
    # ==========================================

    if (
        "sleep computer" in command
        or
        "sleep my computer" in command
        or
        "put computer to sleep" in command
    ):

        speak(
            "Putting the computer to sleep, boss."
        )

        subprocess.run(
            [
                "powershell",
                "-Command",
                "Start-Sleep -Seconds 1; "
                "Add-Type -AssemblyName System.Windows.Forms; "
                "[System.Windows.Forms.Application]::SetSuspendState("
                "'Suspend', $false, $false)"
            ]
        )

        return True


    # ==========================================
    # RESTART COMPUTER
    # ==========================================

    if (
        "restart computer" in command
        or
        "restart my computer" in command
        or
        "restart pc" in command
    ):

        speak(
            "Restarting the computer, boss."
        )

        subprocess.Popen(
            [
                "shutdown",
                "/r",
                "/t",
                "5"
            ]
        )

        return True


    # ==========================================
    # SHUTDOWN COMPUTER
    # ==========================================

    if (
        "shutdown computer" in command
        or
        "shutdown my computer" in command
        or
        "shutdown pc" in command
        or
        "shut down computer" in command
        or
        "shut down my computer" in command
        or
        "shut down pc" in command
    ):

        speak(
            "Shutting down the computer in five seconds, boss."
        )

        subprocess.Popen(
            [
                "shutdown",
                "/s",
                "/t",
                "5"
            ]
        )

        return True


    # ==========================================
    # VOLUME
    # ==========================================

    if (
        "volume up" in command
        or
        "increase volume" in command
        or
        "turn volume up" in command
    ):

        speak(
            "Increasing volume, boss."
        )

        for _ in range(5):

            subprocess.run(
                [
                    "powershell",
                    "-Command",
                    "(New-Object -ComObject WScript.Shell)"
                    ".SendKeys([char]175)"
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )

        return True


    if (
        "volume down" in command
        or
        "decrease volume" in command
        or
        "turn volume down" in command
    ):

        speak(
            "Decreasing volume, boss."
        )

        for _ in range(5):

            subprocess.run(
                [
                    "powershell",
                    "-Command",
                    "(New-Object -ComObject WScript.Shell)"
                    ".SendKeys([char]174)"
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )

        return True


    # ==========================================
    # MUTE
    # ==========================================

    if (
        "mute computer" in command
        or
        "mute pc" in command
        or
        command == "mute"
    ):

        speak(
            "Muting the computer, boss."
        )

        subprocess.run(
            [
                "powershell",
                "-Command",
                "(New-Object -ComObject WScript.Shell)"
                ".SendKeys([char]173)"
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

        return True


    # ==========================================
    # NO COMMAND FOUND
    # ==========================================

    return False


def execute_command(command, speak=None):
    """Entry point to execute commands from voice or UI."""
    handled = handle_pc_command(command, speak)
    if handled:
        log_activity(f"Executed: {command.title()}", "command")
    return handled