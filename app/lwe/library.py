"""Wallpaper library: scanning, importing, thumbnails."""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

from . import paths, shaders

VIDEO_EXT = {".mp4", ".webm", ".mkv", ".mov", ".m4v", ".avi", ".ogv"}
GIF_EXT = {".gif"}
IMAGE_EXT = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".avif", ".jxl"}
SHADER_EXT = {".frag", ".glsl", ".fs", ".shader"}
SUPPORTED = VIDEO_EXT | GIF_EXT | IMAGE_EXT | SHADER_EXT


@dataclass
class Wallpaper:
    id: str
    title: str
    type: str
    dir: Path
    file: str = ""
    description: str = ""
    tags: list = field(default_factory=list)
    author: str = ""
    license: str = ""
    defaults: dict = field(default_factory=dict)
    preset: dict = field(default_factory=dict)
    builtin: bool = False
    error: str = ""

    @property
    def source(self) -> str:
        """Path handed to the Plasma plugin."""
        if self.type == "shader":
            return str(self.dir / "shader.qsb")
        if self.type == "particles":
            return ""
        return str(self.dir / self.file)

    @property
    def thumb(self) -> str:
        for n in ("thumb.jpg", "thumb.png"):
            p = self.dir / n
            if p.exists():
                return str(p)
        return ""

    def to_dict(self) -> dict:
        return {
            "id": self.id, "title": self.title, "type": self.type, "description": self.description,
            "tags": self.tags, "author": self.author, "license": self.license,
            "builtin": self.builtin, "source": self.source, "thumb": self.thumb,
            "error": self.error, "dir": str(self.dir),
        }


def _load(d: Path, builtin: bool) -> Wallpaper | None:
    meta = d / "wallpaper.json"
    try:
        m = json.loads(meta.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    w = Wallpaper(
        id=m.get("id") or d.name, title=m.get("title") or d.name, type=m.get("type", "shader"),
        dir=d, file=m.get("file", ""), description=m.get("description", ""),
        tags=list(m.get("tags", [])), author=m.get("author", ""), license=m.get("license", ""),
        defaults=dict(m.get("defaults", {})), preset=dict(m.get("preset", {})), builtin=builtin,
    )
    if w.type == "shader" and not (d / "shader.qsb").exists():
        w.error = "Shader nicht kompiliert"
    return w


class Library:
    def __init__(self):
        self.items: dict[str, Wallpaper] = {}
        self.scan()

    def scan(self):
        items = {}
        for root in paths.builtin_dirs():
            for d in sorted(root.iterdir()):
                if d.is_dir() and (w := _load(d, True)):
                    items[w.id] = w
        if paths.LIBRARY.is_dir():
            for d in sorted(paths.LIBRARY.iterdir()):
                if d.is_dir() and (w := _load(d, False)):
                    items[w.id] = w
        self.items = items

    def get(self, wid: str) -> Wallpaper | None:
        return self.items.get(wid)

    def ordered(self) -> list[Wallpaper]:
        return sorted(self.items.values(), key=lambda w: (w.builtin, w.title.lower()))

    # ------------------------------------------------------------- import
    def _unique_id(self, title: str) -> str:
        s = unicodedata.normalize("NFKD", title).encode("ascii", "ignore").decode().lower()
        s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")[:40] or "wallpaper"
        cand, n = s, 2
        while cand in self.items or (paths.LIBRARY / cand).exists():
            cand, n = f"{s}-{n}", n + 1
        return cand

    def import_path(self, src: Path) -> tuple[list[str], list[str]]:
        """Import a file or a folder (recursively). Returns (imported ids, error messages)."""
        src = Path(src)
        ok, errs = [], []
        if src.is_dir():
            if (src / "wallpaper.json").exists():
                r = self._import_package(src)
                (ok if r[0] else errs).append(r[1])
                return ok, errs
            for f in sorted(src.rglob("*")):
                if f.is_file() and f.suffix.lower() in SUPPORTED:
                    a, b = self.import_path(f)
                    ok += a
                    errs += b
            return ok, errs
        if src.suffix.lower() not in SUPPORTED:
            return [], [f"{src.name}: Dateityp wird nicht unterstützt"]
        r = self._import_file(src)
        (ok if r[0] else errs).append(r[1])
        return ok, errs

    def _import_package(self, src: Path) -> tuple[bool, str]:
        try:
            m = json.loads((src / "wallpaper.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as e:
            return False, f"{src.name}: wallpaper.json ungültig ({e})"
        wid = self._unique_id(m.get("id") or m.get("title") or src.name)
        dst = paths.LIBRARY / wid
        shutil.copytree(src, dst)
        m["id"] = wid
        (dst / "wallpaper.json").write_text(json.dumps(m, ensure_ascii=False, indent=2), encoding="utf-8")
        if m.get("type") == "shader":
            frag = dst / m.get("file", "shader.frag")
            ok, log = shaders.compile_shader(frag, dst / "shader.qsb")
            if not ok:
                shutil.rmtree(dst)
                return False, f"{src.name}: Shader-Fehler:\n{log}"
        self._thumb(dst, m.get("type"), dst / m.get("file", ""))
        self.scan()
        return True, wid

    def _import_file(self, src: Path) -> tuple[bool, str]:
        ext = src.suffix.lower()
        kind = ("video" if ext in VIDEO_EXT else "gif" if ext in GIF_EXT
                else "image" if ext in IMAGE_EXT else "shader")
        title = src.stem.replace("_", " ").replace("-", " ").strip().title() or "Wallpaper"
        wid = self._unique_id(title)
        dst = paths.LIBRARY / wid
        dst.mkdir(parents=True)
        fname = "shader.frag" if kind == "shader" else "media" + ext
        target = dst / fname
        try:
            os.link(src, target)            # instant, no extra disk space (same filesystem)
        except OSError:
            shutil.copy2(src, target)
        meta = {"id": wid, "title": title, "type": kind, "file": fname,
                "description": f"Importiert aus {src.name}", "tags": ["eigene", kind],
                "author": "", "license": "", "original": str(src)}
        if kind == "shader":
            ok, log = shaders.compile_shader(target, dst / "shader.qsb")
            if not ok:
                shutil.rmtree(dst)
                return False, f"{src.name}: Shader lässt sich nicht kompilieren:\n{log}"
        (dst / "wallpaper.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")
        self._thumb(dst, kind, target)
        self.scan()
        return True, wid

    def _thumb(self, dst: Path, kind: str | None, media: Path):
        out = dst / "thumb.jpg"
        try:
            if kind == "video" and shutil.which("ffmpeg"):
                dur = 0.0
                if shutil.which("ffprobe"):
                    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                                        "-of", "csv=p=0", str(media)], capture_output=True, text=True, timeout=20)
                    try:
                        dur = float(r.stdout.strip())
                    except ValueError:
                        dur = 0.0
                ss = f"{min(dur * 0.3, 5.0):.2f}" if dur else "0"
                subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", ss, "-i", str(media), "-frames:v", "1",
                                "-vf", "scale=480:-2", "-q:v", "4", str(out)], timeout=30)
            elif kind in ("gif", "image"):
                from PySide6.QtGui import QImage
                img = QImage(str(media))
                if not img.isNull():
                    img.scaledToWidth(480).save(str(out), "JPG", 85)
        except Exception as e:      # thumbnails are optional
            print("thumbnail failed:", e)

    # ------------------------------------------------------------- edit
    def remove(self, wid: str) -> bool:
        w = self.items.get(wid)
        if not w or w.builtin:
            return False
        shutil.rmtree(w.dir, ignore_errors=True)
        self.scan()
        return True

    def rename(self, wid: str, title: str, tags: list[str] | None = None) -> bool:
        w = self.items.get(wid)
        if not w or w.builtin:
            return False
        meta_p = w.dir / "wallpaper.json"
        m = json.loads(meta_p.read_text(encoding="utf-8"))
        m["title"] = title.strip() or m["title"]
        if tags is not None:
            m["tags"] = [t.strip().lower() for t in tags if t.strip()]
        meta_p.write_text(json.dumps(m, ensure_ascii=False, indent=2), encoding="utf-8")
        self.scan()
        return True
