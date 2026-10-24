"""NVDA-style audio ducking: lower other applications' audio while Orca speaks.

Orca's speech-dispatcher client turns on BEGIN/END/CANCEL notifications for
every message it sends, and all of them pass through one dispatch callback on
the SSIP connection. Wrapping that callback gives an exact "speaking now"
signal for every utterance (key echo, characters, say all, ...) without
changing how Orca sends speech.

The extension only decides *when* to duck. It publishes the target volume for
everything else to the "orca-ducking" PipeWire metadata object, and the
WirePlumber script ~/.local/share/wireplumber/scripts/orca-ducking.lua applies
it to every playback stream except speech-dispatcher and Orca itself.

Orca+Ctrl+D cycles: no ducking -> duck while speaking -> always duck.
"""

from __future__ import annotations

import shutil
import subprocess
from typing import Any

import speechd
from gi.repository import Gio, GLib

from orca import debug, keybindings, presentation_manager, speechdispatcherfactory
from orca.command import Command, KeyboardCommand
from orca.extension import Extension, ExtensionPreference

METADATA_NAME = "orca-ducking"
LEVEL_KEY = "duck-level"

MODE_OFF = "off"
MODE_SPEECH = "speech"
MODE_ALWAYS = "always"
MODES = (MODE_OFF, MODE_SPEECH, MODE_ALWAYS)
MODE_LABELS = {
    MODE_OFF: "No audio ducking",
    MODE_SPEECH: "Duck audio while speaking",
    MODE_ALWAYS: "Always duck audio",
}

_END_EVENTS = (speechd.CallbackType.END, speechd.CallbackType.CANCEL)


class AudioDucking(Extension):
    """Lowers other applications' audio while Orca speaks."""

    GROUP_LABEL = "Audio ducking"
    DESCRIPTION = "Lowers other applications' audio while Orca speaks, like NVDA's audio ducking."
    VERSION = "1.1"

    def __init__(self) -> None:
        super().__init__()
        self._pw_metadata = shutil.which("pw-metadata")
        self._speaking_msg_id: int | None = None
        self._release_source_id = 0
        # (connection, our hook, the callback it wraps) for each hooked SSIP client
        self._hooks: list[tuple[Any, Any, Any]] = []
        # Level writes are serialized: one pw-metadata at a time, latest value wins.
        self._wanted_level: float | None = None
        self._published_level: float | None = None
        self._writer: Gio.Subprocess | None = None

    # ---- Orca integration ---------------------------------------------------

    def _get_commands(self) -> list[Command]:
        kb_orca_ctrl_d = keybindings.KeyBinding("d", keybindings.ORCA_CTRL_MODIFIER_MASK)
        return [
            KeyboardCommand(
                "audioDuckingCycleMode",
                self.cycle_mode,
                self.GROUP_LABEL,
                "Cycles the audio ducking mode",
                desktop_keybinding=kb_orca_ctrl_d,
                laptop_keybinding=kb_orca_ctrl_d,
            ),
        ]

    def get_preferences(self) -> list[ExtensionPreference]:
        return [
            ExtensionPreference.enum(
                "mode",
                "Ducking mode",
                tuple((mode, MODE_LABELS[mode]) for mode in MODES),
                MODE_SPEECH,
            ),
            ExtensionPreference.integer(
                "level", "Volume of other audio while ducked, in percent", 30, 0, 100
            ),
            ExtensionPreference.integer(
                "release_ms", "Delay before restoring volume after speech, in ms", 400, 0, 3000
            ),
            ExtensionPreference.integer(
                "fade_out_ms", "Fade time when lowering other audio, in ms", 150, 0, 5000
            ),
            ExtensionPreference.integer(
                "fade_in_ms", "Fade time when restoring other audio, in ms", 600, 0, 5000
            ),
        ]

    def on_ready(self) -> None:
        self._hook_speech_servers()
        self._update()

    def on_enabled(self) -> None:
        self._hook_speech_servers()
        self._update()

    def on_disabled(self) -> None:
        self._unhook_speech_servers()
        self._cancel_release()
        self._set_level(1.0)

    def on_shutdown(self) -> None:
        # Runs on a worker thread with a 0.5 s budget while the main loop is
        # going away, so restore synchronously instead of via _set_level.
        self._unhook_speech_servers()
        if self._published_level != 1.0 and self._pw_metadata:
            try:
                subprocess.run(
                    [self._pw_metadata, "-n", METADATA_NAME, "0", LEVEL_KEY, "1"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=0.4,
                    check=False,
                )
            except (OSError, subprocess.TimeoutExpired):
                pass

    def on_speech_output(self, output: Any) -> None:
        # Called before every utterance; cheap way to pick up a speech-dispatcher
        # client that was (re)created since we last looked (reconnect, new synth).
        self._hook_speech_servers()
        return None

    def cycle_mode(self) -> bool:
        """Cycles off -> duck while speaking -> always duck."""

        mode = MODES[(MODES.index(self._get_mode()) + 1) % len(MODES)]
        self.settings.set("mode", mode)
        self._update()
        presentation_manager.get_manager().present_message(MODE_LABELS[mode])
        return True

    # ---- Settings -----------------------------------------------------------

    def _get_mode(self) -> str:
        mode = self.settings.get("mode", MODE_SPEECH)
        return mode if mode in MODES else MODE_SPEECH

    def _get_duck_level(self) -> float:
        try:
            percent = int(self.settings.get("level", 30))
        except (TypeError, ValueError):
            percent = 30
        return max(0, min(100, percent)) / 100

    def _get_ms(self, key: str, default: int) -> int:
        try:
            return max(0, int(self.settings.get(key, default)))
        except (TypeError, ValueError):
            return default

    def _get_release_ms(self) -> int:
        return self._get_ms("release_ms", 400)

    def _get_fade_ms(self, level: float) -> int:
        previous = self._published_level if self._published_level is not None else 1.0
        if level >= previous:
            return self._get_ms("fade_in_ms", 600)
        return self._get_ms("fade_out_ms", 150)

    # ---- Speech-dispatcher events -------------------------------------------

    def _hook_speech_servers(self) -> None:
        # pylint: disable=protected-access
        servers = list(speechdispatcherfactory.SpeechServer._active_servers.values())
        for server in servers:
            conn = getattr(getattr(server, "_client", None), "_conn", None)
            original = getattr(conn, "_callback", None)
            if original is None or any(hook is original for _c, hook, _o in self._hooks):
                continue

            def hook(msg_id, client_id, event_type, _original=original, **kwargs):
                # Runs on speech-dispatcher's listener thread; an exception here
                # would kill that thread, so never let one escape.
                _original(msg_id, client_id, event_type, **kwargs)
                try:
                    GLib.idle_add(self._on_speech_event, msg_id, event_type)
                except Exception:  # pylint: disable=broad-exception-caught
                    pass

            conn._callback = hook
            self._hooks.append((conn, hook, original))
            debug.print_message(debug.LEVEL_INFO, "AUDIO DUCKING: Hooked speech events.", True)

    def _unhook_speech_servers(self) -> None:
        # pylint: disable=protected-access
        for conn, hook, original in self._hooks:
            if getattr(conn, "_callback", None) is hook:
                conn._callback = original
        self._hooks.clear()

    def _on_speech_event(self, msg_id: int, event_type: str) -> bool:
        if event_type == speechd.CallbackType.BEGIN:
            self._speaking_msg_id = msg_id
        elif event_type in _END_EVENTS:
            # Only the message that is actually playing ends speech; CANCELs
            # for queued messages that never started are ignored.
            if msg_id != self._speaking_msg_id:
                return False
            self._speaking_msg_id = None
        else:
            return False
        self._update()
        return False

    # ---- Ducking state ------------------------------------------------------

    def _update(self) -> None:
        mode = self._get_mode()
        if mode == MODE_ALWAYS or (mode == MODE_SPEECH and self._speaking_msg_id is not None):
            self._cancel_release()
            self._set_level(self._get_duck_level())
        elif mode == MODE_SPEECH and self._wanted_level not in (None, 1.0):
            # Hold the duck briefly so gaps between utterances don't pump the volume.
            if not self._release_source_id:
                self._release_source_id = GLib.timeout_add(self._get_release_ms(), self._release)
        else:
            self._cancel_release()
            self._set_level(1.0)

    def _release(self) -> bool:
        self._release_source_id = 0
        self._set_level(1.0)
        return False

    def _cancel_release(self) -> None:
        if self._release_source_id:
            GLib.source_remove(self._release_source_id)
            self._release_source_id = 0

    def _set_level(self, level: float) -> None:
        if level == self._wanted_level:
            return
        self._wanted_level = level
        self._flush()

    def _flush(self) -> None:
        if self._writer is not None or self._wanted_level is None:
            return
        if self._wanted_level == self._published_level or not self._pw_metadata:
            return

        # "<level> <fade ms>"; the WirePlumber script does the actual fade.
        level = self._wanted_level
        value = f"{level:.2f} {self._get_fade_ms(level)}"
        argv = [self._pw_metadata, "-n", METADATA_NAME, "0", LEVEL_KEY, value]
        try:
            self._writer = Gio.Subprocess.new(
                argv,
                Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_SILENCE,
            )
        except GLib.Error as error:
            msg = f"AUDIO DUCKING: Failed to run pw-metadata: {error.message}"
            debug.print_message(debug.LEVEL_WARNING, msg, True)
            return
        self._writer.wait_async(None, self._on_writer_done, level)

    def _on_writer_done(self, proc: Gio.Subprocess, result: Gio.AsyncResult, level: float) -> None:
        self._writer = None
        try:
            proc.wait_finish(result)
            succeeded = proc.get_successful()
        except GLib.Error:
            succeeded = False
        if not succeeded:
            # Most likely WirePlumber lacks the orca-ducking script. Don't retry
            # in a loop; the next state change will try again.
            msg = f"AUDIO DUCKING: pw-metadata failed to publish level {level:.2f}"
            debug.print_message(debug.LEVEL_WARNING, msg, True)
            self._published_level = None
            if self._wanted_level == level:
                self._wanted_level = None
            else:
                self._flush()
            return
        self._published_level = level
        self._flush()
