"""Performance presets ("Leistungsstufen").

Each preset sets the frame-rate cap, the pause rules and three multipliers the
plugin applies on top of every wallpaper's own values:
  renderMul / renderMax  shader render resolution (wallpaper renderScale * renderMul,
                         capped at renderMax; > 1 means supersampling)
  particleMul            number and emit rate of particles
"""
from __future__ import annotations

PRESETS = [
    {"id": "winterschlaf", "name": "Winterschlaf", "hint": "Minimaler Verbrauch – ideal für Laptop & Akku",
     "fps": 20, "pauseOnFullscreen": True, "pauseOnMaximized": True,
     "renderMul": 0.6, "renderMax": 0.6, "particleMul": 0.4},
    {"id": "cruise", "name": "Cruise", "hint": "Ausgewogen – schön und sparsam",
     "fps": 30, "pauseOnFullscreen": True, "pauseOnMaximized": True,
     "renderMul": 1.0, "renderMax": 0.75, "particleMul": 0.7},
    {"id": "turbo", "name": "Turbo", "hint": "Flüssige 60 FPS, Shader wie vorgesehen",
     "fps": 60, "pauseOnFullscreen": True, "pauseOnMaximized": False,
     "renderMul": 1.0, "renderMax": 1.0, "particleMul": 1.0},
    {"id": "overdrive", "name": "Overdrive", "hint": "Ultra: 120 FPS, volle Auflösung, mehr Partikel",
     "fps": 120, "pauseOnFullscreen": True, "pauseOnMaximized": False,
     "renderMul": 2.0, "renderMax": 1.0, "particleMul": 1.5},
    {"id": "hyperdrive", "name": "Hyperdrive", "hint": "144 FPS + Supersampling – nur für starke GPUs",
     "fps": 144, "pauseOnFullscreen": True, "pauseOnMaximized": False,
     "renderMul": 2.0, "renderMax": 1.5, "particleMul": 2.0},
]
BY_ID = {p["id"]: p for p in PRESETS}
CUSTOM = "custom"
# keys a preset writes into the global settings
KEYS = ("fps", "pauseOnFullscreen", "pauseOnMaximized", "renderMul", "renderMax", "particleMul")
