#!/usr/bin/env bash
# Fedorama – Deinstallation
#   ./uninstall.sh           entfernt Programm, Plugin, KWin-Script, Starter, Autostart.
#                            Deine importierten Wallpaper + Einstellungen bleiben erhalten.
#   ./uninstall.sh --purge   entfernt zusätzlich ~/.local/share/lwe komplett (Bibliothek, Einstellungen)
set -uo pipefail

DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
LWE="$DATA/lwe"
BIN="$HOME/.local/bin"
PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1
c_ok=$'\e[32m'; c_b=$'\e[1m'; c_0=$'\e[0m'
step() { echo "${c_b}==>${c_0} $*"; }
ok()   { echo "    ${c_ok}✓${c_0} $*"; }

step "Beende laufende Instanz"
[ -x "$BIN/lwe" ] && "$BIN/lwe" quit >/dev/null 2>&1
pkill -u "$(id -u)" -f "python3 -m lwe.main" 2>/dev/null
ok "beendet"

step "Gebe Plasma seinen normalen Hintergrund zurück"
# Plasma behält die alte Konfiguration von org.kde.image, daher kommt dein vorheriges Bild zurück.
qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    desktops().forEach(function (d) {
        if (d.wallpaperPlugin === "com.lwe.wallpaper") { d.wallpaperPlugin = "org.kde.image"; d.reloadConfig(); }
    });' >/dev/null 2>&1 && ok "Standard-Hintergrund aktiv" || echo "    – plasmashell nicht erreichbar, übersprungen"

if [ "$(kreadconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin 2>/dev/null)" = "com.lwe.wallpaper" ]; then
    kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin --delete
    ok "Sperrbildschirm zurückgesetzt"
fi

step "Entferne Plasma-Plugin, Leisten-Widget und KWin-Script"
kpackagetool6 -t Plasma/Wallpaper -r com.lwe.wallpaper >/dev/null 2>&1 && ok "Plugin entfernt"
qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    panels().forEach(function (p) { p.widgets("com.lwe.panel").forEach(function (w) { w.remove(); }); });' >/dev/null 2>&1
kpackagetool6 -t Plasma/Applet -r com.lwe.panel >/dev/null 2>&1 && ok "Leisten-Widget entfernt"
kwriteconfig6 --file kwinrc --group Plugins --key lwecursorEnabled --delete 2>/dev/null
kpackagetool6 -t KWin/Script -r lwecursor >/dev/null 2>&1 && ok "KWin-Script entfernt"
qdbus-qt6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1

step "Entferne Starter, Menüeintrag, Autostart, Programmdateien"
rm -f "$BIN/lwe" "$DATA/applications/lwe.desktop" "$DATA/icons/hicolor/scalable/apps/lwe.svg" "$HOME/.config/autostart/lwe.desktop"
rm -rf "$LWE/app" "$LWE/builtin" "$LWE/.thumbs.qml"
update-desktop-database "$DATA/applications" >/dev/null 2>&1
ok "erledigt"

if [ "$PURGE" = 1 ]; then
    rm -rf "$LWE"
    ok "Bibliothek und Einstellungen gelöscht ($LWE)"
else
    echo "    Deine Bibliothek und Einstellungen liegen weiter in $LWE"
    echo "    (komplett löschen: ./uninstall.sh --purge)"
fi
echo
echo "${c_ok}${c_b}Fedorama wurde deinstalliert.${c_0}"
