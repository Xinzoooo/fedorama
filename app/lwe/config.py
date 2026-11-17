"""Persistent settings (JSON in ~/.local/share/lwe/config.json)."""
from __future__ import annotations

import copy
import json
import os
import tempfile

from . import paths

DEFAULTS = {
    "version": 1,
    "theme": "minimal",
    "paused": False,
    "global": {
        "fps": 30,
        "pauseOnFullscreen": True,
        "pauseOnMaximized": True,       # matches the default preset (cruise)
        "mouse": True,
        "audio": False,
        "transition": 900,
        "bridgePort": 47811,
        "autostart": True,
        "lockscreen": True,
        "applyTarget": "",        # "" = all screens, else a connector name
        "quality": "cruise",      # preset id from quality.py, or "custom"
        "renderMul": 1.0,
        "renderMax": 0.75,
        "particleMul": 0.7,
    },
    "screens": {},        # connector -> {"wallpaper": id}
    "playlists": {},      # connector -> {...}
    "favorites": [],
    "hidden": [],         # wallpaper ids skipped in the app
    "params": {},         # wallpaper id -> overrides
}

PLAYLIST_DEFAULT = {
    "enabled": False, "mode": "interval", "interval": 10, "shuffle": False, "items": [],
    "day": "", "night": "", "dayStart": "07:00", "nightStart": "19:00",
}


def _merge(base: dict, over: dict) -> dict:
    out = copy.deepcopy(base)
    for k, v in (over or {}).items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _merge(out[k], v)
        else:
            out[k] = v
    return out


class Config:
    def __init__(self):
        self.data = copy.deepcopy(DEFAULTS)
        self.load()

    def load(self):
        try:
            with open(paths.CONFIG, encoding="utf-8") as f:
                self.data = _merge(DEFAULTS, json.load(f))
        except FileNotFoundError:
            pass
        except (OSError, ValueError) as e:
            print("config: could not read, using defaults:", e)

    def save(self):
        paths.ensure()
        fd, tmp = tempfile.mkstemp(dir=paths.DATA, prefix=".config.", suffix=".json")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(self.data, f, ensure_ascii=False, indent=2)
        os.replace(tmp, paths.CONFIG)

    # convenience accessors
    @property
    def g(self) -> dict:
        return self.data["global"]

    def screen(self, name: str) -> dict:
        return self.data["screens"].setdefault(name, {})

    def playlist(self, name: str) -> dict:
        pl = self.data["playlists"].get(name)
        pl = _merge(PLAYLIST_DEFAULT, pl or {})
        self.data["playlists"][name] = pl
        return pl
