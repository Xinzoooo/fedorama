def test_main_loads_without_warnings(qml_load):
    root, warnings = qml_load("Main.qml")
    assert root is not None
    assert warnings == []


def test_stage_start_index(qml_load, eng):
    eng.toggleHidden("synthwave")                       # the running one is hidden
    root, _ = qml_load("Main.qml", running="synthwave")
    assert root.property("current")["id"] == "aurora"   # first visible


def test_stage_starts_at_running(qml_load):
    root, _ = qml_load("Main.qml", running="galaxy")
    assert root.property("current")["id"] == "galaxy"


def _child(root, name):
    from PySide6.QtCore import QObject
    o = root.findChild(QObject, name)
    assert o is not None, f"no object named {name}"
    return o


def test_bar_hide_skips_to_next(qml_load):
    root, w = qml_load("Main.qml", running="synthwave")
    _child(root, "hideButton").clicked.emit()
    assert root.property("current")["id"] == "aurora"
    assert w == []


def test_bar_next_and_apply(qml_load, plasma_calls):
    root, w = qml_load("Main.qml", running="synthwave")
    _child(root, "nextButton").clicked.emit()
    assert root.property("current")["id"] == "aurora"
    _child(root, "applyButton").clicked.emit()
    assert sorted(c[1] for c in plasma_calls if c[0] == "apply") == [0, 1, 2]
    assert root.property("justApplied") is True
    assert w == []


def _settle(qapp, n=3):
    for _ in range(n):
        qapp.processEvents()


def test_search_enter_jumps(qml_load, qapp):
    root, w = qml_load("Main.qml", running="synthwave")
    root.setProperty("panel", "search"); _settle(qapp)
    s = _child(root, "searchField")
    s.setProperty("text", "nord"); _settle(qapp)
    s.accepted.emit(); _settle(qapp)
    assert root.property("current")["id"] == "aurora"
    assert root.property("panel") == ""
    assert w == []


def test_all_panel_favorites_filter(qml_load, eng, qapp):
    eng.toggleFavorite("galaxy")
    root, w = qml_load("Main.qml")
    root.setProperty("panel", "all"); _settle(qapp)
    assert _child(root, "allStrip").property("count") == len(root.property("visibleList").toVariant())
    _child(root, "favFilter").clicked.emit(); _settle(qapp)
    assert _child(root, "allStrip").property("count") == 1
    assert w == []


def test_adjust_slider_sets_param(qml_load, eng, qapp):
    root, w = qml_load("Main.qml", running="aurora")
    root.setProperty("panel", "adjust"); _settle(qapp)
    _child(root, "slider-brightness").moved.emit(1.2)
    assert eng.params("aurora")["brightness"] == 1.2
    assert w == []


def test_adjust_reset(qml_load, eng, qapp):
    eng.setParam("aurora", "hue", 40)
    root, w = qml_load("Main.qml", running="aurora")
    root.setProperty("panel", "adjust"); _settle(qapp)
    _child(root, "resetParams").clicked.emit()
    assert eng.params("aurora").get("hue", 0) == 0
    assert w == []
