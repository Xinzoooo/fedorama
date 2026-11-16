"""Captures what is currently playing (PipeWire/Pulse monitor source) and turns it into
16 spectrum bands + bass/mid/treble/level. Pure Python, no numpy needed."""
from __future__ import annotations

import array
import cmath
import math
import shutil
import subprocess
import threading
import time

RATE = 11025          # enough for visuals (0 – 5.5 kHz)
N = 512               # FFT size
BANDS = 16
HOP = RATE // 30      # ~30 updates per second


def _fft(x: list[complex]) -> list[complex]:
    n = len(x)
    j = 0
    for i in range(1, n):            # bit reversal
        bit = n >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j |= bit
        if i < j:
            x[i], x[j] = x[j], x[i]
    size = 2
    while size <= n:
        half = size // 2
        w_step = cmath.exp(-2j * math.pi / size)
        for start in range(0, n, size):
            w = 1 + 0j
            for k in range(start, start + half):
                t = w * x[k + half]
                x[k + half] = x[k] - t
                x[k] = x[k] + t
                w *= w_step
        size *= 2
    return x


class AudioAnalyzer:
    def __init__(self):
        self.spectrum = [0.0] * BANDS
        self.levels = [0.0, 0.0, 0.0, 0.0]
        self.active = False
        self._proc = None
        self._thread = None
        self._stop = threading.Event()
        self._window = [0.5 - 0.5 * math.cos(2 * math.pi * i / (N - 1)) for i in range(N)]
        # log spaced band edges in FFT bins, 40 Hz .. 5000 Hz
        lo, hi = 40.0, 5000.0
        edges = [lo * (hi / lo) ** (b / BANDS) for b in range(BANDS + 1)]
        self._edges = [max(1, int(e * N / RATE)) for e in edges]
        self._peak = 1e-3
        self.error = ""

    @staticmethod
    def available() -> bool:
        return shutil.which("parec") is not None

    def start(self):
        if self.active:
            return
        if not self.available():
            self.error = "parec nicht gefunden (Paket pulseaudio-utils)"
            return
        self._stop.clear()
        self._proc = subprocess.Popen(
            ["parec", "--device=@DEFAULT_MONITOR@", "--format=s16le", f"--rate={RATE}", "--channels=1",
             "--latency-msec=40", "--raw", "--client-name=Linux Wallpaper Engine"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        self._thread = threading.Thread(target=self._run, name="lwe-audio", daemon=True)
        self._thread.start()
        self.active = True

    def stop(self):
        self._stop.set()
        if self._proc:
            self._proc.terminate()
            try:
                self._proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self._proc.kill()
            self._proc = None
        self.active = False
        self.spectrum = [0.0] * BANDS
        self.levels = [0.0] * 4

    def _run(self):
        buf = array.array("h", [0] * N)
        stream = self._proc.stdout
        while not self._stop.is_set():
            data = stream.read(HOP * 2)
            if not data:
                break
            new = array.array("h")
            new.frombytes(data[: len(data) // 2 * 2])
            buf = buf[len(new):] + new if len(new) < N else new[-N:]
            self._analyse(buf)
        self.active = False

    def _analyse(self, buf):
        x = [complex(buf[i] / 32768.0 * self._window[i]) for i in range(N)]
        f = _fft(x)
        mags = [abs(c) for c in f[: N // 2]]
        bands = []
        for b in range(BANDS):
            a, e = self._edges[b], max(self._edges[b + 1], self._edges[b] + 1)
            seg = mags[a:e]
            bands.append(math.sqrt(sum(v * v for v in seg) / len(seg)) if seg else 0.0)
        # slight boost for high bands (they are naturally weaker)
        bands = [v * (1.0 + i * 0.12) for i, v in enumerate(bands)]
        peak = max(bands) if bands else 0
        # automatic gain: follow peaks quickly, decay slowly
        self._peak = max(peak, self._peak * 0.995, 0.02)
        norm = [min(1.0, v / self._peak) for v in bands]
        out = []
        for old, new in zip(self.spectrum, norm):
            out.append(new if new > old else old * 0.82 + new * 0.18)   # fast attack, slow release
        self.spectrum = out
        rms = math.sqrt(sum((s / 32768.0) ** 2 for s in buf) / N)
        silent = rms < 1e-4
        bass = sum(out[0:4]) / 4
        mid = sum(out[4:10]) / 6
        treble = sum(out[10:16]) / 6
        level = 0.0 if silent else min(1.0, sum(out) / BANDS * 3.0)
        self.levels = [bass, mid, treble, level]


if __name__ == "__main__":
    a = AudioAnalyzer()
    a.start()
    t0 = time.time()
    for _ in range(20):
        time.sleep(0.2)
        print(" ".join(f"{v:.2f}" for v in a.levels), "|", "".join(" .:-=+*#%@"[min(9, int(v * 9.99))] for v in a.spectrum))
    a.stop()
    # benchmark
    import random
    buf = array.array("h", [random.randint(-3000, 3000) for _ in range(N)])
    t = time.perf_counter()
    for _ in range(30):
        a._analyse(buf)
    print(f"analyse: {(time.perf_counter() - t) / 30 * 1000:.2f} ms/frame")
