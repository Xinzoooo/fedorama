#!/usr/bin/env bash
# Linux Wallpaper Engine – Installation (nur unter ~/.local, kein sudo)
#   ./install.sh               installieren / aktualisieren
#   ./install.sh --no-start    danach nicht automatisch öffnen
#   ./install.sh --no-thumbs   keine Vorschaubilder rendern (z. B. ohne laufende Sitzung)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
LWE="$DATA/lwe"
BIN="$HOME/.local/bin"
START=1; THUMBS=1
for a in "$@"; do
    case "$a" in
        --no-start) START=0 ;;
        --no-thumbs) THUMBS=0 ;;
        -h|--help) sed -n 2,5p "$0"; exit 0 ;;
    esac
done

c_ok=$'\e[32m'; c_err=$'\e[31m'; c_dim=$'\e[2m'; c_b=$'\e[1m'; c_0=$'\e[0m'
step() { echo "${c_b}==>${c_0} $*"; }
ok()   { echo "    ${c_ok}✓${c_0} $*"; }
die()  { echo "    ${c_err}✗ $*${c_0}" >&2; exit 1; }

# ------------------------------------------------------------------ checks
step "Prüfe Voraussetzungen"
missing=()
command -v plasmashell >/dev/null || die "plasmashell nicht gefunden – nur KDE Plasma 6 wird unterstützt."
pv=$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+' | head -1 || echo 0)
[ "${pv:-0}" -ge 6 ] || die "Plasma 6 benötigt (gefunden: $(plasmashell --version 2>/dev/null))"
command -v kpackagetool6 >/dev/null || missing+=("kf6-kpackage")
command -v python3 >/dev/null || missing+=("python3")
python3 -c "import PySide6.QtQuick, PySide6.QtDBus, PySide6.QtWidgets" 2>/dev/null || missing+=("python3-pyside6")
QSB=""
for q in /usr/lib64/qt6/bin/qsb /usr/lib/qt6/bin/qsb "$(command -v qsb-qt6 || true)" "$(command -v qsb || true)"; do
    [ -n "$q" ] && [ -x "$q" ] && QSB="$q" && break
done
[ -n "$QSB" ] || missing+=("qt6-qtshadertools")
[ -d /usr/lib64/qt6/qml/QtMultimedia ] || [ -d /usr/lib/qt6/qml/QtMultimedia ] || missing+=("qt6-qtmultimedia")
if [ ${#missing[@]} -gt 0 ]; then
    echo "    ${c_err}Es fehlen Pakete:${c_0} ${missing[*]}"
    echo "    Installieren mit:  sudo dnf install ${missing[*]}"
    exit 1
fi
ok "Plasma $(plasmashell --version | awk '{print $2}'), PySide6, qsb"
command -v ffmpeg >/dev/null && ok "ffmpeg (Video-Vorschaubilder)" || echo "    ${c_dim}– ffmpeg fehlt: Videos funktionieren, aber ohne Vorschaubild${c_0}"
command -v parec  >/dev/null && ok "parec (Audio-Visualizer)"     || echo "    ${c_dim}– parec fehlt: Audio-Visualizer nicht verfügbar (Paket pulseaudio-utils)${c_0}"

# ------------------------------------------------------------------ stop running instance
if [ -x "$BIN/lwe" ]; then "$BIN/lwe" quit >/dev/null 2>&1 || true; fi

# ------------------------------------------------------------------ files
step "Kopiere Programm nach $LWE"
mkdir -p "$LWE/app" "$LWE/builtin" "$LWE/library" "$LWE/themes" "$BIN"
rm -rf "$LWE/app/app" "$LWE/app/themes"
cp -r "$SRC/app" "$SRC/themes" "$LWE/app/"
find "$LWE/app" -name __pycache__ -type d -prune -exec rm -rf {} +
ok "App + Themes"

step "Mitgelieferte Wallpaper"
# keep already rendered thumbnails if the wallpaper did not change
for d in "$SRC"/content/wallpapers/*/; do
    id=$(basename "$d")
    mkdir -p "$LWE/builtin/$id"
    cp -r "$d". "$LWE/builtin/$id/"
done
# drop builtin wallpapers that no longer exist in this version
for d in "$LWE"/builtin/*/; do
    [ -d "$SRC/content/wallpapers/$(basename "$d")" ] || rm -rf "$d"
done
python3 "$LWE/app/app/lwe/shaders.py" build "$LWE/builtin" || die "Shader konnten nicht kompiliert werden"
ok "$(ls "$LWE/builtin" | wc -l) Wallpaper bereit"

# ------------------------------------------------------------------ plasma plugin
step "Plasma-Wallpaper-Plugin"
WAS_INSTALLED=0
if kpackagetool6 -t Plasma/Wallpaper -l 2>/dev/null | grep -qx "com.lwe.wallpaper"; then
    # only reload plasmashell later if the plugin really changed
    diff -rq "$SRC/plugin/com.lwe.wallpaper" "$DATA/plasma/wallpapers/com.lwe.wallpaper" >/dev/null 2>&1 || WAS_INSTALLED=1
    kpackagetool6 -t Plasma/Wallpaper -u "$SRC/plugin/com.lwe.wallpaper" >/dev/null
else
    kpackagetool6 -t Plasma/Wallpaper -i "$SRC/plugin/com.lwe.wallpaper" >/dev/null
fi
ok "com.lwe.wallpaper"

step "Widget für die Kontrollleiste"
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "com.lwe.panel"; then
    diff -rq "$SRC/plasmoid/com.lwe.panel" "$DATA/plasma/plasmoids/com.lwe.panel" >/dev/null 2>&1 || WAS_INSTALLED=1
    kpackagetool6 -t Plasma/Applet -u "$SRC/plasmoid/com.lwe.panel" >/dev/null
else
    kpackagetool6 -t Plasma/Applet -i "$SRC/plasmoid/com.lwe.panel" >/dev/null
fi
ok "com.lwe.panel  (Rechtsklick auf die Leiste → Widgets hinzufügen → „Linux Wallpaper Engine“)"

step "KWin-Script für die Mausposition"
if kpackagetool6 -t KWin/Script -l 2>/dev/null | grep -qx "lwecursor"; then
    kpackagetool6 -t KWin/Script -u "$SRC/kwin/lwecursor" >/dev/null
else
    kpackagetool6 -t KWin/Script -i "$SRC/kwin/lwecursor" >/dev/null
fi
kwriteconfig6 --file kwinrc --group Plugins --key lwecursorEnabled true
qdbus-qt6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true
ok "lwecursor aktiviert"

# ------------------------------------------------------------------ launcher, menu, autostart
step "Starter, Menüeintrag, Autostart"
cat > "$BIN/lwe" <<EOF
#!/bin/sh
# Linux Wallpaper Engine launcher
PYTHONPATH="$LWE/app/app\${PYTHONPATH:+:\$PYTHONPATH}" exec python3 -m lwe.main "\$@"
EOF
chmod +x "$BIN/lwe"
mkdir -p "$DATA/applications" "$DATA/icons/hicolor/scalable/apps" "$HOME/.config/autostart"
sed "s|@BIN@|$BIN/lwe|g" "$SRC/assets/lwe.desktop" > "$DATA/applications/lwe.desktop"
cp "$SRC/assets/lwe.svg" "$DATA/icons/hicolor/scalable/apps/lwe.svg"
cat > "$HOME/.config/autostart/lwe.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Linux Wallpaper Engine
Exec=$BIN/lwe --tray
Icon=lwe
X-KDE-autostart-phase=2
NoDisplay=true
EOF
update-desktop-database "$DATA/applications" >/dev/null 2>&1 || true
ok "$BIN/lwe"
case ":$PATH:" in *":$BIN:"*) ;; *) echo "    ${c_dim}Hinweis: $BIN ist nicht im PATH – App über das Startmenü öffnen.${c_0}";; esac

# ------------------------------------------------------------------ thumbnails
if [ "$THUMBS" = 1 ] && [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    step "Rendere Vorschaubilder (einmalig, ca. 1 Minute – ein kleines Fenster blinkt dabei)"
    (cd "$LWE/app/app" && python3 -m lwe.thumbs "$LWE/builtin") >/dev/null 2>&1 && ok "fertig" \
        || echo "    ${c_dim}– übersprungen (die App zeigt dann Live-Standbilder)${c_0}"
fi

# ------------------------------------------------------------------ reload plasma when updating
if [ "$WAS_INSTALLED" = 1 ]; then
    step "Lade Plasma neu, damit das aktualisierte Plugin aktiv wird"
    systemctl --user restart plasma-plasmashell.service 2>/dev/null || { kquitapp6 plasmashell >/dev/null 2>&1; (plasmashell >/dev/null 2>&1 &); }
    sleep 3
    ok "plasmashell neu gestartet"
fi

echo
echo "${c_ok}${c_b}Fertig!${c_0}  Starten: Startmenü → „Linux Wallpaper Engine“  oder  ${c_b}lwe${c_0}"
echo "         Deinstallieren: ${c_b}$SRC/uninstall.sh${c_0}"
if [ "$START" = 1 ] && [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    (setsid "$BIN/lwe" >/dev/null 2>&1 &)
fi
