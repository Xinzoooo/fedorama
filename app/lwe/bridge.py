"""Tiny local HTTP server. KWin posts the global cursor position, the wallpaper plugin
polls /state for cursor + audio data. Listens on 127.0.0.1 only."""
from __future__ import annotations

import json
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse


class Bridge:
    def __init__(self, port: int, audio=None):
        self.port = port
        self.audio = audio
        self.cursor = [0.0, 0.0]
        self.cursor_seen = False
        self.on_command = None          # optional callback(cmd: str)
        self._srv = None

    def start(self) -> bool:
        bridge = self

        class H(BaseHTTPRequestHandler):
            def log_message(self, *a):
                pass

            def _send(self, code, body=b"", ctype="application/json"):
                self.send_response(code)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Length", str(len(body)))
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                if body:
                    self.wfile.write(body)

            def do_POST(self):
                u = urlparse(self.path)
                if u.path == "/cursor":
                    q = parse_qs(u.query)
                    try:
                        bridge.cursor = [float(q["x"][0]), float(q["y"][0])]
                        bridge.cursor_seen = True
                    except (KeyError, ValueError):
                        return self._send(400)
                    return self._send(204)
                self._send(404)

            def do_GET(self):
                u = urlparse(self.path)
                if u.path == "/state":
                    st = {"cursor": bridge.cursor if bridge.cursor_seen else None}
                    a = bridge.audio
                    if a is not None and a.active:
                        st["audio"] = [round(v, 3) for v in a.levels]
                        st["spectrum"] = [round(v, 3) for v in a.spectrum]
                    return self._send(200, json.dumps(st).encode())
                self._send(404)

        try:
            self._srv = ThreadingHTTPServer(("127.0.0.1", self.port), H)
        except OSError as e:
            print(f"bridge: port {self.port} busy: {e}")
            return False
        self._srv.daemon_threads = True
        threading.Thread(target=self._srv.serve_forever, name="lwe-bridge", daemon=True).start()
        return True

    def stop(self):
        if self._srv:
            self._srv.shutdown()
            self._srv.server_close()
            self._srv = None
