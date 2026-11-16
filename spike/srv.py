from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json
st={"x":0,"y":0,"n":0}
class H(BaseHTTPRequestHandler):
    def log_message(self,*a): pass
    def do_POST(self):
        q=parse_qs(urlparse(self.path).query); st["x"]=float(q["x"][0]); st["y"]=float(q["y"][0]); st["n"]+=1
        self.send_response(204); self.end_headers()
    def do_GET(self):
        b=json.dumps(st).encode(); self.send_response(200); self.send_header("Content-Type","application/json"); self.send_header("Content-Length",str(len(b))); self.end_headers(); self.wfile.write(b)
ThreadingHTTPServer(("127.0.0.1",47811),H).serve_forever()
