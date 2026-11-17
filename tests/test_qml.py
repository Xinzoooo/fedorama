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
