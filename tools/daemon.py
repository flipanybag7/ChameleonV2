#!/usr/bin/env python3
"""Local-only JSON API for the profile store.

It intentionally binds to loopback and has no remote-control or credential
handling surface. A future iOS companion can use the same API contract.
"""
import argparse, json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import profilectl

class Handler(BaseHTTPRequestHandler):
    root = None
    def send_json(self, status, value):
        body = json.dumps(value, sort_keys=True).encode()
        self.send_response(status); self.send_header("Content-Type", "application/json"); self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
    def do_GET(self):
        if self.path != "/profiles": self.send_json(404, {"error":"not found"}); return
        self.send_json(200, profilectl.read_db(self.root))
    def do_POST(self):
        if self.path != "/profiles": self.send_json(404, {"error":"not found"}); return
        try:
            size = int(self.headers.get("Content-Length", "0")); payload = json.loads(self.rfile.read(size))
            name = str(payload["name"]).strip()
            if not name or len(name) > 80: raise ValueError("invalid name")
            db = profilectl.read_db(self.root)
            if any(p["name"] == name for p in db["profiles"].values()): raise ValueError("profile exists")
            pid = profilectl.profile_id(name)
            db["profiles"][pid] = {"id":pid,"name":name,"apps":{},"proxy":None,"location":None,"created":profilectl.time.time_ns() // 1_000_000_000}
            profilectl.write_db(self.root, db); self.send_json(201, db["profiles"][pid])
        except (KeyError, ValueError, json.JSONDecodeError) as exc: self.send_json(400, {"error":str(exc)})
    def log_message(self, *_): pass

def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--root", default="./profiles"); ap.add_argument("--host", default="127.0.0.1"); ap.add_argument("--port", type=int, default=8765); args=ap.parse_args()
    Handler.root=profilectl.root_path(args.root)
    ThreadingHTTPServer((args.host,args.port), Handler).serve_forever()

if __name__ == "__main__": main()
