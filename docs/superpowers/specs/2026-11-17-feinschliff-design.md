# Design: Feinschliff der Bühne

Stand: 2026-11-17 · kleine Änderung · baut auf `2026-11-17-ui-buehne-design.md` auf

## Warum
Die neue Oberfläche gefällt, wirkt aber noch nicht flott genug; der Ambient-Rahmen und die
Fensterknöpfe oben rechts sehen „komisch“ aus. Fünf kleine Punkte aus dem Review sind offen.

## Ziele
1. **Rahmen „Schwebend“ (A):** kein Rand mehr. Die Bühne ist das Fenster: runde Ecken (14 px),
   1-px-Kante `rgba(255,255,255,0.14)`, weicher, tiefer Schatten rundherum.
2. **Fensterknöpfe in der Leiste (3):** oben rechts verschwindet ganz. Minimieren und Schließen
   sitzen ganz rechts in der Leiste hinter einem Trennstrich; Schließen färbt sich beim Drüberfahren rot.
3. **Animationen etwa halbieren:** Klick/Hover 50–70 ms, Standard 110 ms, Felder 160 ms,
   Überblendung Bühne/Rahmen 200 ms, Namenswechsel 80 + 130 ms, Ausblenden der Leiste 180 ms.
4. **Die fünf offenen Punkte:**
   - Feld schließt robust (geladener Inhalt wird auch entladen, wenn das Zuklappen vor dem ersten
     Animationsbild passiert).
   - Streifen in „Alle“ scrollt beim Blättern mit.
   - Startbild = Wallpaper des ersten Monitors, auf dem unser Plugin läuft (gleiche Regel wie
     Sperrbildschirm).
   - Veraltete IDs in `hidden` zählen beim Schutz „mindestens eins sichtbar“ nicht mit.
   - `install.sh` meldet „App“ statt „App + Themes“.

## Nicht-Ziele
GPU-Optimierungen am Desktop-Plugin, Vergleich mit Steam Wallpaper Engine.

## Vorgehen
Nur ein sinnvoller Weg: die bestehenden QML-Dateien anpassen. Der Schatten ist ein einmal
erzeugtes PNG (`app/qml/images/shadow.png`, mit Pillow erzeugt, mitgeliefert) als `BorderImage`
in einem transparenten Fensterrand von 28 px – kostet pro Bild praktisch nichts, anders als ein
Live-Schatten- oder Weichzeichner-Effekt. Der Ambient-Rahmen (`MultiEffect`-Blur) entfällt
dadurch komplett. Die Ränder zum Größe-Ändern liegen im Schattenbereich.

Verworfen: Schatten per `MultiEffect` (läuft bei jedem Bild mit), KWin-Fensterschatten (gibt es
für rahmenlose Qt-Fenster unter Wayland nicht).
