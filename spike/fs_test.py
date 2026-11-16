import sys
from PySide6.QtWidgets import QApplication, QLabel
from PySide6.QtCore import QTimer
app = QApplication(sys.argv)
from PySide6.QtCore import Qt
w = QLabel("FULLSCREEN TEST"); w.setAttribute(Qt.WA_TranslucentBackground); w.setStyleSheet("background:rgba(30,0,30,90); color:white; font-size:40px")
w.setScreen([s for s in app.screens() if s.name()==sys.argv[2]][0]) if len(sys.argv)>2 else None; w.showFullScreen()
QTimer.singleShot(int(sys.argv[1])*1000, app.quit)
app.exec()
