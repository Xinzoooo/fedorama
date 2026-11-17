"""Talks to plasmashell through its scripting D-Bus API (org.kde.PlasmaShell.evaluateScript)."""
from __future__ import annotations

import json
import shutil
import subprocess

PLUGIN_ID = "com.lwe.wallpaper"
GROUP = ["Wallpaper", PLUGIN_ID, "General"]

_qdbus = None


def _dbus_eval(script: str) -> str:
    """Run a Plasma desktop script. Prefers QtDBus, falls back to qdbus CLI."""
    try:
        from PySide6.QtDBus import QDBusConnection, QDBusMessage
        msg = QDBusMessage.createMethodCall("org.kde.plasmashell", "/PlasmaShell",
                                            "org.kde.PlasmaShell", "evaluateScript")
        msg.setArguments([script])
        reply = QDBusConnection.sessionBus().call(msg, timeout=8000)
        if reply.type() == QDBusMessage.ErrorMessage:
            raise RuntimeError(reply.errorMessage())
        args = reply.arguments()
        return str(args[0]) if args else ""
    except ImportError:
        global _qdbus
        _qdbus = _qdbus or shutil.which("qdbus-qt6") or shutil.which("qdbus6") or shutil.which("qdbus")
        r = subprocess.run([_qdbus, "org.kde.plasmashell", "/PlasmaShell",
                            "org.kde.PlasmaShell.evaluateScript", script],
                           capture_output=True, text=True, timeout=10)
        if r.returncode != 0:
            raise RuntimeError(r.stderr.strip())
        return r.stdout


def _js(v) -> str:
    return json.dumps(v)


def screens() -> list[dict]:
    """Plasma screens: [{'index': 0, 'x':..,'y':..,'w':..,'h':.., 'plugin': ..}]"""
    out = _dbus_eval("""
        var res = {};
        desktops().forEach(function (d) {
            if (d.screen < 0) return;
            var g = screenGeometry(d.screen);
            res[d.screen] = {index: d.screen, x: g.x, y: g.y, w: g.width, h: g.height,
                             plugin: d.wallpaperPlugin};
        });
        print(JSON.stringify(Object.keys(res).map(function (k) { return res[k]; })));
    """)
    try:
        lst = json.loads(out.strip().splitlines()[-1])
    except (ValueError, IndexError):
        return []
    return sorted(lst, key=lambda s: s["index"])


def apply(screen_index: int | None, values: dict) -> None:
    """Switch the given Plasma screen (None = all) to our plugin and write config values."""
    cond = "true" if screen_index is None else f"d.screen === {int(screen_index)}"
    script = f"""
        var vals = {_js(values)};
        desktops().forEach(function (d) {{
            if (d.screen < 0 || !({cond})) return;
            if (d.wallpaperPlugin !== {_js(PLUGIN_ID)}) d.wallpaperPlugin = {_js(PLUGIN_ID)};
            d.currentConfigGroup = {_js(GROUP)};
            for (var k in vals) d.writeConfig(k, vals[k]);
            d.reloadConfig();
        }});
    """
    _dbus_eval(script)


def set_all(values: dict) -> None:
    """Write config values on every screen that already uses our plugin (e.g. Paused)."""
    script = f"""
        var vals = {_js(values)};
        desktops().forEach(function (d) {{
            if (d.screen < 0 || d.wallpaperPlugin !== {_js(PLUGIN_ID)}) return;
            d.currentConfigGroup = {_js(GROUP)};
            for (var k in vals) d.writeConfig(k, vals[k]);
            d.reloadConfig();
        }});
    """
    _dbus_eval(script)


def restore_default(plugin: str = "org.kde.image") -> None:
    """Give every desktop back to Plasma's own wallpaper plugin (its old config is kept by Plasma)."""
    _dbus_eval(f"""
        desktops().forEach(function (d) {{
            if (d.wallpaperPlugin === {_js(PLUGIN_ID)}) {{ d.wallpaperPlugin = {_js(plugin)}; d.reloadConfig(); }}
        }});
    """)


# ---------------------------------------------------------------- lock screen
# kscreenlocker_greet loads the same wallpaper plugin, configured in kscreenlockerrc:
#   [Greeter] WallpaperPlugin=...   and   [Greeter][Wallpaper][<plugin>][General] ...
# The greeter reads the file each time the screen locks, so writing it is enough.
LOCK_GROUP = ["Greeter", "Wallpaper", PLUGIN_ID, "General"]


def _kwrite(groups: list[str], key: str, value=None) -> None:
    cmd = ["kwriteconfig6", "--file", "kscreenlockerrc"]
    for g in groups:
        cmd += ["--group", g]
    cmd += ["--key", key]
    if value is None:
        cmd.append("--delete")
    else:
        if isinstance(value, bool):
            cmd += ["--type", "bool"]
            value = "true" if value else "false"
        cmd.append(str(value))
    subprocess.run(cmd, check=True, capture_output=True, timeout=10)


def apply_lockscreen(values: dict) -> None:
    """Use our plugin on the lock screen with the given config values."""
    for k, v in values.items():
        _kwrite(LOCK_GROUP, k, v)
    _kwrite(["Greeter"], "WallpaperPlugin", PLUGIN_ID)


def restore_lockscreen() -> None:
    """Give the lock screen back to Plasma's default wallpaper (only if it uses ours)."""
    r = subprocess.run(["kreadconfig6", "--file", "kscreenlockerrc", "--group", "Greeter",
                        "--key", "WallpaperPlugin"], capture_output=True, text=True, timeout=10)
    if r.stdout.strip() == PLUGIN_ID:
        _kwrite(["Greeter"], "WallpaperPlugin")


if __name__ == "__main__":
    import sys
    if sys.argv[1:2] == ["screens"]:
        print(json.dumps(screens(), indent=1))
    elif sys.argv[1:2] == ["apply"]:
        apply(None if sys.argv[2] == "all" else int(sys.argv[2]), json.loads(sys.argv[3]))
    elif sys.argv[1:2] == ["restore"]:
        restore_default()
        restore_lockscreen()
