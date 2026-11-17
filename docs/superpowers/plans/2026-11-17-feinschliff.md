# Feinschliff der Bühne Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rahmen „Schwebend“, Fensterknöpfe in der Leiste, doppelt so schnelle Animationen und die fünf offenen Review-Punkte.

**Architecture:** Nur bestehende Dateien in `app/qml/` und `app/lwe/engine.py` ändern; neues statisches Schatten-PNG `app/qml/images/shadow.png` (einmal mit Pillow erzeugt, Skript `tools/gen_shadow.py`), eingebunden als `BorderImage`.

**Tech Stack:** PySide6 6.11 / Qt Quick, pytest (`QT_QPA_PLATFORM=offscreen`), Pillow (nur zum Erzeugen des PNG).

**Spec:** `docs/superpowers/specs/2026-11-17-feinschliff-design.md`

## Global Constraints
- Tests: `cd ~/LinuxWallpaperEngine && QT_QPA_PLATFORM=offscreen python3 -m pytest tests -q` – alle grün nach jeder Task.
- Kein Effekt, der pro Bild läuft, für Rahmen/Schatten (kein `MultiEffect`-Blur/Shadow).
- Dauern: Klick/Hover 50–70 ms, Standard 110 ms, Felder 160 ms, Überblendung 200 ms, Name 80 + 130 ms, Leiste ausblenden 180 ms.
- Schwarz/Weiß; Rot `Theme.danger` nur für Schließen-Hover.

## Review Focus
- **Klicks im transparenten Schattenrand:** dürfen nichts in der App auslösen außer Größe-Ändern → Test in Task 1 (`test_frame_margin_is_resize_only`: Stage-Inhalt beginnt bei x = Schattenrand).
- **Schließen per Leiste:** schließt nur das Fenster (App bleibt im Tray) → Test in Task 2.
- **Schnelles Auf/Zu eines Felds:** kein geladenes Feld bleibt zurück → Test in Task 4.
- **Blättern bei offenem „Alle“:** aktuelles Vorschaubild bleibt im sichtbaren Bereich → Test in Task 4.
- **Kleinstes Fenster mit zwei Knöpfen mehr in der Leiste:** keine Überlappung → bestehender `test_bar_fits_smallest_window` muss grün bleiben.

---

### Task 1: Rahmen „Schwebend“

**Files:** Create `tools/gen_shadow.py`, `app/qml/images/shadow.png`. Modify `app/qml/Main.qml`. Test `tests/test_qml.py`.

**Interfaces:** Produces in `Main.qml`: `readonly property int shadowMargin: 28`; Item `stageBox` füllt das Fenster minus `shadowMargin`; Eckradius 14.

- [ ] **Step 1: Failing test**
```python
def test_frame_margin_is_resize_only(qml_load, qapp):
    from PySide6.QtCore import QPointF
    root, w = qml_load("Main.qml")
    m = root.property("shadowMargin")
    assert m == 28
    stage = _child(root, "stageBox")
    assert stage.mapToScene(QPointF(0, 0)).x() == m
    assert root.property("color").alpha() == 0          # transparent window
    assert w == []
```
- [ ] **Step 2: Run – FAIL** (`shadowMargin` fehlt)
- [ ] **Step 3: `tools/gen_shadow.py`** schreibt ein 128×128-RGBA-PNG: schwarzes Rechteck mit Radius 14 in der Mitte (Rand 28), Gaußweichzeichnung Radius 14, Deckkraft max. 0.65, Inneres (ab 28 + 14 px) transparent ausgeschnitten, damit nichts unter die Bühne fällt. Einmal ausführen, PNG committen.
- [ ] **Step 4: `Main.qml`** – `color: "transparent"`; Ambient-Item + `MultiEffect` + Bühnen-Margin 9 entfernen; `BorderImage { source: "images/shadow.png"; anchors.fill: parent; border { left: 56; right: 56; top: 56; bottom: 56 } }`; `stageBox` mit `objectName: "stageBox"`, `anchors.margins: win.shadowMargin`; Maske und Innenkante Radius 14, Kante `Qt.rgba(1,1,1,0.14)`; Resize-Ränder: die äußeren `shadowMargin` px (Ecken 2× `shadowMargin`).
- [ ] **Step 5: Run – PASS**; live-Screenshot über das Prüfskript (in-App-Grab, nicht spectacle).
- [ ] **Step 6: Commit** `"Rahmen Schwebend: Schatten statt Ambient-Rahmen"`

### Task 2: Fensterknöpfe in die Leiste

**Files:** Modify `app/qml/Bar.qml`, `app/qml/Main.qml`. Test `tests/test_qml.py`.

**Interfaces:** Consumes `win.showMinimized()`, `win.close()`. `BarButton` bekommt `property bool danger` (Hover-Fläche `Theme.danger`, Icon weiß).

- [ ] **Step 1: Failing test**
```python
def test_window_buttons_live_in_bar(qml_load, qapp):
    root, w = qml_load("Main.qml")
    assert _child(root, "minimizeButton") is not None
    _child(root, "closeButton").clicked.emit(); _settle(qapp)
    assert root.property("visible") is False
    assert w == []
```
- [ ] **Step 2: Run – FAIL**
- [ ] **Step 3:** In `Bar.qml` rechts nach „Anwenden“: Trennstrich (1×22, `Qt.rgba(1,1,1,0.16)`), `BarButton { objectName: "minimizeButton"; icon: "minus"; tip: "Minimieren" }`, `BarButton { objectName: "closeButton"; icon: "close"; tip: "In den Tray"; danger: true }`. In `Main.qml` die `Row` mit `WinButton`s und die `component WinButton` löschen.
- [ ] **Step 4: Run – PASS** inkl. `test_bar_fits_smallest_window`.
- [ ] **Step 5: Commit** `"Minimieren und Schließen in der Leiste"`

### Task 3: Animationen halbieren

**Files:** Modify `app/qml/Theme.qml` (`fast 70`, `anim 110`, `slow 200`), `Tray.qml` (Höhe 160, Inhalt 120/140, Weg 8 px), `Bar.qml` (Name 80 + 130), `Main.qml` (Leiste aus 180), `BarButton.qml`/`TextButton.qml`/`Pill.qml`/`Bar.qml`-Apply (Druck 50), `AllPanel.qml` (Hover-Hub 110).

- [ ] **Step 1: Failing test**
```python
def test_animation_budget():
    import re, pathlib
    qml = pathlib.Path(__file__).resolve().parent.parent / "app/qml"
    durations = [int(d) for f in qml.glob("*.qml") for d in re.findall(r"duration: *(\d+)", f.read_text())]
    assert durations and max(durations) <= 200
    theme = (qml / "Theme.qml").read_text()
    assert "fast: 70" in theme and "anim: 110" in theme and "slow: 200" in theme
```
- [ ] **Step 2: Run – FAIL** · **Step 3:** Werte setzen · **Step 4: Run – PASS** · **Step 5: Commit** `"Animationen doppelt so schnell"`

### Task 4: Die fünf offenen Punkte

**Files:** `app/qml/Tray.qml`, `app/qml/AllPanel.qml`, `app/qml/Main.qml` (`startIndex`), `app/lwe/engine.py` (`toggleHidden`), `install.sh:59`. Tests `tests/test_qml.py`, `tests/test_backend.py`.

- [ ] **Step 1: Failing tests**
```python
# test_qml.py
def test_tray_unloads_after_fast_close(qml_load, qapp):
    root, w = qml_load("Main.qml")
    root.setProperty("panel", "search"); root.setProperty("panel", ""); _settle(qapp)
    from PySide6.QtTest import QTest; QTest.qWait(400)
    assert root.property("typing") is False
    assert _find(root, "searchField") is None

def test_strip_follows_stage(qml_load, qapp):
    root, w = qml_load("Main.qml", running="synthwave")
    root.setProperty("panel", "all"); _settle(qapp)
    for _ in range(12): _child(root, "nextButton").clicked.emit()
    from PySide6.QtTest import QTest; QTest.qWait(400)
    strip = _child(root, "allStrip")
    assert strip.property("currentIndex") == root.property("index")

def test_start_uses_first_screen_with_our_plugin(qml_load, eng, monkeypatch):
    # first screen not ours: start image comes from the second
    eng.cfg.screen("DP-2")["wallpaper"] = "galaxy"; eng.cfg.screen("HDMI-A-1")["wallpaper"] = "aurora"
    monkeypatch.setattr(type(eng), "screen_list", lambda self: [
        {"name": "DP-2", "index": 0, "active": False, "wallpaper": "galaxy", "playlist": {}},
        {"name": "HDMI-A-1", "index": 1, "active": True, "wallpaper": "aurora", "playlist": {}}])
    root, _ = qml_load("Main.qml")
    assert root.property("current")["id"] == "aurora"

# test_backend.py
def test_stale_hidden_ids_do_not_block(eng):
    eng.cfg.data["hidden"] = ["gone-1", "gone-2"]
    ids = [w["id"] for w in eng.wallpapers]
    for i in ids[1:]:
        assert eng.toggleHidden(i) is True
```
  (`_find` = `_child` ohne Assert, gibt `None` zurück.)
- [ ] **Step 2: Run – FAIL**
- [ ] **Step 3:**
  - `Tray.qml`: `shown` zusätzlich leeren, wenn `panel === ""` und `height === 0` bereits beim Wechsel gilt; außerdem `Timer` (Höhendauer + 40 ms) nach dem Schließen als Absicherung.
  - `AllPanel.qml`: `currentIndex` an `panel.items`-Index von `win.currentId` binden, `highlightRangeMode: ListView.ApplyRange`, `preferredHighlightBegin/End` mittig, `highlightMoveDuration: Theme.anim`.
  - `Main.qml startIndex()`: erster Bildschirm mit `active && wallpaper`, sonst `screens[0]`.
  - `engine.toggleHidden`: Anzahl sichtbar = `len([i for i in self.lib.items if i not in h])`.
  - `install.sh`: `ok "App"`.
- [ ] **Step 4: Run – PASS** (ganze Suite) · **Step 5: Commit** `"Offene Review-Punkte: Feld-Schließen, Streifen folgt, Startbild, ausgeblendete IDs, Install-Meldung"`

### Task 5: Abnahme
- [ ] Installieren (`./install.sh --no-start --no-thumbs`), Tray neu starten (`lwe quit`, `lwe --tray`), Screenshots per in-App-Grab: normal, Feld offen, 820×540. `docs/app.png`/`docs/settings.png` erneuern. GPU-Messung wie zuvor (offen ohne Fokus) notieren. Commit `"Screenshots Feinschliff"`.
