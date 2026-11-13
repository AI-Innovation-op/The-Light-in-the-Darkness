"""Local preview server. Binds only loopback; no external telemetry."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from functools import partial
import argparse, json, time

parser=argparse.ArgumentParser()
parser.add_argument('--web',type=Path,required=True)
parser.add_argument('--evidence',type=Path,required=True)
parser.add_argument('--port',type=int,default=8766)
args=parser.parse_args()
args.evidence.mkdir(parents=True,exist_ok=True)

class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control','no-store')
        super().end_headers()
    def do_POST(self):
        if self.path not in ['/playtest','/screenshot']:
            self.send_error(404); return
        size=int(self.headers.get('Content-Length',0))
        if size>200000:
            self.send_error(413); return
        data=json.loads(self.rfile.read(size))
        name='latest-playtest.json' if self.path=='/playtest' else f'screenshot-{time.time_ns()}.json'
        (args.evidence/name).write_text(json.dumps(data,indent=2),encoding='utf-8')
        self.send_response(200); self.end_headers(); self.wfile.write(b'OK')
    def log_message(self,*values): pass

print(f'http://127.0.0.1:{args.port}',flush=True)
ThreadingHTTPServer(('127.0.0.1',args.port),partial(Handler,directory=str(args.web.resolve()))).serve_forever()
