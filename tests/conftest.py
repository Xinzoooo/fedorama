"""Test setup: isolated data dir, offscreen Qt, no calls into the real Plasma session."""
import os
import sys
import tempfile
from pathlib import Path

import pytest

# lwe.paths reads XDG_DATA_HOME at import time, so set it before anything imports lwe
os.environ["XDG_DATA_HOME"] = tempfile.mkdtemp(prefix="lwe-test-")
os.environ["QT_QPA_PLATFORM"] = "offscreen"
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "app"))

from PySide6.QtGui import QGuiApplication  # noqa: E402

SCREENS = [
    {"name": "DP-2", "index": 0},
    {"name": "HDMI-A-1", "index": 1},
    {"name": "DP-1", "index": 2},
]


@pytest.fixture(scope="session")
def qapp():
    return QGuiApplication.instance() or QGuiApplication([])


@pytest.fixture
def plasma_calls(monkeypatch):
    from lwe import plasma
    calls = []
    monkeypatch.setattr(plasma, "apply", lambda idx, values: calls.append(("apply", idx)))
    monkeypatch.setattr(plasma, "set_all", lambda values: calls.append(("set_all", None)))
    monkeypatch.setattr(plasma, "apply_lockscreen", lambda values: None)
    monkeypatch.setattr(plasma, "restore_lockscreen", lambda: None)
    monkeypatch.setattr(plasma, "screens", lambda: [])
    return calls


@pytest.fixture
def eng(qapp, plasma_calls, monkeypatch, tmp_path):
    from lwe import paths
    from lwe.engine import Engine
    monkeypatch.setattr(paths, "CONFIG", tmp_path / "config.json")   # fresh config per test

    def screen_list(self):
        return [dict(s, wallpaper=self.cfg.data["screens"].get(s["name"], {}).get("wallpaper", ""),
                     playlist=self.cfg.playlist(s["name"])) for s in SCREENS]
    monkeypatch.setattr(Engine, "screen_list", screen_list)
    return Engine(headless=True)


@pytest.fixture
def toasts(eng):
    got = []
    eng.toast.connect(lambda m, k: got.append((m, k)))
    return got
