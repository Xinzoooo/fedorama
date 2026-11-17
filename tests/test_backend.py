def test_order_builtin_first_then_imports(eng):
    ids = [w["id"] for w in eng.wallpapers]
    assert ids[:5] == ["synthwave", "aurora", "starry-night", "ocean-sunset", "mountain-layers"]
    builtin = [w["builtin"] for w in eng.wallpapers]
    assert builtin == sorted(builtin, reverse=True)      # all builtin first, imports after


def test_toggle_hidden_roundtrip(eng):
    assert eng.toggleHidden("matrix-rain") is True
    assert next(w for w in eng.wallpapers if w["id"] == "matrix-rain")["hidden"] is True
    assert "matrix-rain" in eng.cfg.data["hidden"]
    assert eng.toggleHidden("matrix-rain") is True
    assert "matrix-rain" not in eng.cfg.data["hidden"]


def test_cannot_hide_last_visible(eng):
    ids = [w["id"] for w in eng.wallpapers]
    for i in ids[1:]:
        assert eng.toggleHidden(i) is True
    assert eng.toggleHidden(ids[0]) is False
    assert ids[0] not in eng.cfg.data["hidden"]


def test_apply_current_uses_target(eng, plasma_calls):
    eng.setGlobal("applyTarget", "DP-1")
    assert eng.applyCurrent("aurora") is True
    assert [c[1] for c in plasma_calls if c[0] == "apply"] == [2]


def test_apply_current_missing_target_falls_back_to_all(eng, plasma_calls, toasts):
    eng.setGlobal("applyTarget", "HDMI-A-9")
    assert eng.applyCurrent("aurora") is True
    assert sorted(c[1] for c in plasma_calls if c[0] == "apply") == [0, 1, 2]
    assert any("alle" in m.lower() for m, _ in toasts)


def test_no_theme_api(eng):
    assert not hasattr(eng, "themes")
    assert "theme" not in eng.settings
