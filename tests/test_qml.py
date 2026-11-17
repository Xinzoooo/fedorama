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
