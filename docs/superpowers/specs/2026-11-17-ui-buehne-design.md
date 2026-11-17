# Design: neue Oberfläche „Bühne“

Stand: 2026-11-17 · Branch `ui-buehne`

## Warum

Die aktuelle Oberfläche (Seitenleiste, Kachel-Raster, Detailspalte, 4 Themes) wirkt austauschbar
und überladen („KI-Slop“). Das ständige Raster aller 29 Wallpaper nervt, zumal einige schwach
aussehen. Ziel: modern, minimalistisch, kühl, mit kurzen, flotten Animationen – und weiterhin
leichtgewichtig und schnell.

## Ziele

- Die App zeigt immer **ein** Wallpaper fensterfüllend und live (die „Bühne“).
- Bedienung über **eine schwebende Leiste unten** (Variante C aus dem Prototyp).
- Alles Weitere (Alle, Suchen, Anpassen, Einstellungen) **öffnet sich unten** als Feld, das aus
  der Leiste nach oben wächst – nie seitlich.
- Wallpaper lassen sich **ausblenden**; ausgeblendete tauchen beim Blättern nicht mehr auf.
- Eigener **Ambient-Rahmen** um ein rahmenloses Fenster: das Fenster soll nicht wie ein
  rechteckiger Ausschnitt auf dem Desktop liegen.
- Icons: **Phosphor Duotone** (MIT).

## Nicht-Ziele

- Keine Änderung am Desktop-Plugin, an der Engine-Logik, an der Playlist-Logik, Import oder
  Panel-Widget (Playlists bekommen nur einen neuen Platz in den Einstellungen).
- Kein neues Theme-System; die Theme-Auswahl entfällt ersatzlos.
- Keine Web-Oberfläche (QtWebEngine): zu schwer.

## Anti-Ziele (wäre ein Fehlschlag, auch wenn es funktioniert)

- Animationen, die dauerhaft GPU kosten, wenn nichts passiert, oder länger als ~0,35 s dauern.
- Die App ruckelt oder startet langsamer als heute.
- Die Vorschau läuft weiter, während das Fenster minimiert, verdeckt oder im Tray ist.
- Violett/Lila irgendwo im eigenen Design.

## Vorgehen (Approaches)

1. **QML-Oberfläche der bestehenden App ersetzen, Backend behalten** – gewählt. Die Python-Seite
   (`engine.py`, Bridge, Plugin) bleibt, `Preview.qml` liefert die Live-Bühne mit demselben
   Renderer wie der Desktop.
2. Web-Oberfläche im Qt-WebEngine – verworfen: deutlich mehr Speicher und Startzeit, widerspricht
   „lightweight“.
3. Bestehende Seiten nur umstylen – verworfen: das Raster als Startseite ist genau das, was stört.

## Aufbau

### Fenster und Rahmen
- `ApplicationWindow` rahmenlos (`Qt.FramelessWindowHint`), Hintergrund transparent nicht nötig:
  Das Fenster selbst ist der Rahmen.
- **Ambient-Rahmen:** 9 px Rand. Darin das Vorschaubild (`thumb`) des aktuellen Wallpapers,
  stark weichgezeichnet (`MultiEffect` blur), Sättigung hoch, Helligkeit ~55 %. Weichzeichnung des
  **statischen** Bildes, nicht des Live-Shaders. Wechselt mit Überblendung.
- Bühne innen mit 13 px Eckenradius, dünne helle Innenkante (1 px, ~7 % Weiß).
- Fenster verschieben: Ziehen auf freier Bühnenfläche → `startSystemMove()`. Größe ändern:
  Ziehen am Rahmen → `startSystemResize(edges)`.
- Fensterknöpfe: Minimieren und Schließen (= in den Tray) klein oben rechts, nur sichtbar, wenn
  die Maus über dem Fenster ist.

### Bühne
- Ein `Preview` fensterfüllend, `renderScale` 0,6, Bildrate = Bildrate der Leistungsstufe.
- `running` nur, wenn das Fenster sichtbar und aktiv ist (wie heute im `DetailPanel`).
- Wechsel zwischen Wallpapern: Überblendung ~0,45 s (alte Vorschau ausblenden, neue einblenden;
  höchstens zwei Previews gleichzeitig, die alte wird danach entladen).
- Dezenter Verlauf unten (schwarz → transparent, ~30 % Höhe), damit die Leiste lesbar bleibt.
- Maus bewegt sich 2,5 s nicht und kein Feld ist offen → Leiste und Fensterknöpfe blenden aus
  (0,35 s), Mauszeiger bleibt.

### Leiste (unten, schwebend, volle Breite mit 14 px Abstand)
- Glas: dunkel (~82 % Deckkraft), Weichzeichnung dahinter, 1 px Kante ~11 % Weiß, Radius 16, Höhe 68.
- Links: **Alle**, **Suchen**, **Anpassen**, **Einstellungen** (öffnen je ihr Feld; aktiver Knopf
  weiß gefüllt).
- Mitte: ‹ · Name (fett, 22 px, eng gesetzt) mit Zeile darunter: `07/29 · SHADER · ● LÄUFT`
  (Monospace, klein) · ›. Namenswechsel: alter Name rutscht nach unten weg, neuer kommt herein.
- Rechts: **Favorit** (Herz, gefüllt + rötlich wenn aktiv), **Ausblenden**, Knopf **Anwenden ↵**
  (weiß). Nach dem Anwenden 1,4 s grün mit „Läuft“.
- Tooltips über den Symbolen.

### Felder (wachsen aus der Leiste nach oben, gleiche Breite, max. ~440 px hoch)
- Immer nur eins offen; erneuter Klick auf dasselbe Symbol oder Esc schließt.
- **Alle:** horizontaler Streifen aller sichtbaren Wallpaper (Vorschaubilder), aktuelles markiert
  und in die Mitte gescrollt; Klick springt dorthin. Umschalter „Alle | Favoriten“ oben im Feld.
  *(Entscheidung Claude: Favoriten brauchen ohne Seitenleiste einen Ort.)*
- Drag & Drop von Dateien aufs Fenster importiert wie heute. *(Entscheidung Claude)*
- **Suchen:** großes Eingabefeld, Treffer als Liste mit Vorschaubild; Enter nimmt den ersten.
- **Anpassen:** dieselben Regler wie heute im `DetailPanel` (Helligkeit, Farbton, Sättigung,
  Geschwindigkeit, Render-Auflösung; bei Video/Bild: Parallaxe, Bass-Puls, Ton/Lautstärke,
  Füllmodus), je nach Typ sichtbar, über `setParam`; wirken live auf die Bühne; „Zurücksetzen“.
  Unten eine Infozeile (Autor · Lizenz, ggf. Fehlertext) und für eigene Importe „Ordner“,
  „Umbenennen“, „Entfernen“. *(Entscheidung Claude: diese Aktionen hatten im neuen Aufbau keinen Platz.)*
- **Einstellungen:** Leistungsstufe (5 Knöpfe mit FPS-Zahl + Beschreibung), **Monitore**
  (Alle drei / einzelner Monitor: Ziel für „Anwenden“), die bestehenden Schalter (Pausen, Maus,
  Musik, Sperrbildschirm, Autostart), **Automatisch wechseln** (Playlists wie bisher auf der
  Monitor-Seite, pro Monitor: Aus / Rotation mit „Wechsel alle“ + „Zufällig“ + Auswahl per
  Vorschaubild-Klick / Tag-Nacht mit Uhrzeiten und je einem Wallpaper; über `setPlaylist`;
  der Monitor wird mit denselben Chips gewählt wie bei „Monitore“), **Ausgeblendet** (Vorschaubilder, Klick holt zurück),
  Import-Knopf, „Plasma-Standardhintergrund“.

### Tastatur und Maus
`←`/`→` und Mausrad blättern · `Enter` anwenden · `Leertaste` Alle · `/` Suchen · `A` Anpassen ·
`F` Favorit · `Entf` ausblenden · `Esc` Feld schließen.

### Aussehen
- Schwarz/Weiß; Farbe kommt nur aus den Wallpapern. Ausnahmen: Grün für „läuft“, Rot fürs Herz.
- Schrift: Inter Tight (Name, Text), JetBrains Mono (Zahlen, kleine Zeilen) – mitliefern oder
  Fallback auf Inter / System-Monospace.
- Animationen: nur Deckkraft, Position, Größe; Dauer 0,08–0,45 s, Kurve „ease-out“.
  Knöpfe geben beim Klick nach (Skalierung ~0,9).

### Reihenfolge der Wallpaper
Die stärksten zuerst (Synthwave, Nordlicht, Sternenhimmel, Ozean, Bergdämmerung, Galaxie, …),
Visualizer und Partikel ans Ende. Festgelegt über ein Sortierfeld (`order`) in den `wallpaper.json`
der mitgelieferten Inhalte; eigene Importe danach.

## Backend-Änderungen (klein)
- Konfiguration: Liste `hidden` (wie `favorites`) + Slot `toggleHidden(wid)`.
- Einstellung `applyTarget` (`""` = alle, sonst Bildschirmname); „Anwenden“ ruft
  `apply(wid, applyTarget)`.
- Theme-System entfernen: `themes/*.json`, Theme-Laden in `engine.py`, `themes`/`theme`-Properties.
  `Theme.qml` wird zu festen Design-Werten.

## Was entfällt
`LibraryPage.qml`, `Tile.qml`, `DetailPanel.qml`, `ScreensPage.qml`, `ScreenMap.qml`, `Chip.qml`,
`Glass.qml`, `NeonButton.qml`, `NeonSlider.qml`, alte Icons in `app/qml/icons/`, der Ordner `themes/`.
Ob einzelne davon (z. B. `Toggle.qml`, `Toasts.qml`) umgebaut weiterverwendet werden, entscheidet
der Bauplan.

## Leistung
- Schneller beim Start und Bedienen (kein Raster, keine Hover-Vorschauen, weniger Elemente).
- GPU bei offenem Fenster etwas höher als heute (große Live-Vorschau), begrenzt durch
  `renderScale` 0,6, FPS der Leistungsstufe und Pause bei verstecktem/inaktivem Fenster.
- Desktop-Wallpaper unverändert.

## Offen für den Bauplan
- Exakte Aufteilung in QML-Dateien.
- Ob Phosphor-SVGs einzeln mitgeliefert werden (nur die ~14 genutzten) – vorgeschlagen: ja.
- Wie die Schriften mitgeliefert werden (Dateien im Repo vs. Systemschrift-Fallback).

## Referenz
Klickbarer Prototyp: `.superpowers/brainstorm/23503-1794940491/content/prototyp-v5.html`
(Rahmen „Ambient“, Icons „Phosphor Duo“). Nicht im Repo.
