"""All file locations. Everything lives below ~/.local (XDG_DATA_HOME)."""
import os
from pathlib import Path

DATA = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "lwe"
APP_DIR = Path(__file__).resolve().parent.parent          # .../app
BUILTIN = DATA / "builtin"                                 # shipped wallpapers (compiled at install)
LIBRARY = DATA / "library"                                 # user imports
CONFIG = DATA / "config.json"
LOG = DATA / "lwe.log"
PLUGIN_UI = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "plasma/wallpapers/com.lwe.wallpaper/contents/ui"


def builtin_dirs() -> list[Path]:
    """Installed builtin content, or the repo's content dir when running from a checkout."""
    out = []
    if BUILTIN.is_dir():
        out.append(BUILTIN)
    repo = APP_DIR.parent / "content/wallpapers"
    if not out and repo.is_dir():
        out.append(repo)
    return out


def plugin_ui() -> Path:
    repo = APP_DIR.parent / "plugin/com.lwe.wallpaper/contents/ui"
    if repo.is_dir():                 # running from a source checkout
        return repo
    return PLUGIN_UI


def ensure():
    for p in (DATA, LIBRARY):
        p.mkdir(parents=True, exist_ok=True)
