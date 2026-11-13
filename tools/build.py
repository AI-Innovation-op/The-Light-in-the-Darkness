"""Reproducible Godot build. Output and engine location are explicit arguments."""
import argparse, json, os, shutil, subprocess, hashlib, urllib.request, io, zipfile
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('--runtime',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
parser.add_argument('--skip-native',action='store_true')
args=parser.parse_args()
source=Path(__file__).resolve().parents[1]
output=args.output.resolve()
if output==source or source in output.parents:
    parser.error('--output must be outside the source project to avoid recursive copies')
project=output/'source'
project.mkdir(parents=True,exist_ok=True)
shutil.copytree(source,project,dirs_exist_ok=True,ignore=shutil.ignore_patterns('.godot','build','__pycache__','.git'))
logs=output/'logs'; logs.mkdir(exist_ok=True)
profile=output/'profile'; profile.mkdir(exist_ok=True)
environment={**os.environ,'APPDATA':str(profile)}
engine=args.runtime/'Godot_v4.7.2-stable_win64_console.exe'
web=output/'web'; web.mkdir(exist_ok=True)
native=output/'windows'; native.mkdir(exist_ok=True)
template=args.runtime/'windows_release_x86_64.exe'

def fetch(url,headers=None):
    with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'TLITD-Oakhaven-build',**(headers or {})}),timeout=90) as r:
        return r.read()

class RemoteZip(io.RawIOBase):
    def __init__(self,url,size): self.url=url; self.size=size; self.pos=0
    def seekable(self): return True
    def tell(self): return self.pos
    def seek(self,n,w=0): self.pos=n if w==0 else (self.pos if w==1 else self.size)+n; return self.pos
    def read(self,n=-1):
        n=min(self.size-self.pos,n if n>=0 else self.size)
        if n<=0:return b''
        if n>120*1024*1024:raise ValueError('Bounded download exceeded')
        req=urllib.request.Request(self.url,headers={'User-Agent':'TLITD-Oakhaven-build','Range':f'bytes={self.pos}-{self.pos+n-1}'})
        with urllib.request.urlopen(req,timeout=90) as r:
            if r.status!=206: raise ValueError('Range response required')
            data=r.read(n+1)
        if len(data)!=n:raise ValueError('Invalid byte range')
        self.pos+=n
        return data

def run(name,extra):
    result=subprocess.run([str(engine),'--headless','--path',str(project),*extra],capture_output=True,text=True,timeout=150,env=environment)
    text=result.stdout+'\n'+result.stderr
    (logs/(name+'.log')).write_text(text,encoding='utf-8')
    print(name,'exit',result.returncode,flush=True)
    if result.returncode or 'SCRIPT ERROR:' in text or 'Parse Error:' in text:
        print(text[-14000:],flush=True)
        raise SystemExit(result.returncode or 1)

preset='''[preset.0]
name="Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter="assets/narrative/*.json"
exclude_filter="tests/*,tools/*"
export_path="../web/index.html"
custom_features="playtest"
[preset.0.options]
custom_template/release="WEB_TEMPLATE"
variant/thread_support=false
variant/extensions_support=false
html/canvas_resize_policy=2
progressive_web_app/enabled=false
'''.replace('WEB_TEMPLATE',(args.runtime/'web_release.zip').as_posix())
if not args.skip_native:
    if not template.exists():
        release=json.loads(fetch('https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable'))
        asset=next(a for a in release['assets'] if a['name']=='Godot_v4.7.2-stable_export_templates.tpz')
        with zipfile.ZipFile(RemoteZip(asset['browser_download_url'],asset['size'])) as package:
            member=next(n for n in package.namelist() if n.endswith('/windows_release_x86_64.exe'))
            template.write_bytes(package.read(member))
        print('Official Windows template acquired:',template.stat().st_size,flush=True)
    preset+='''
[preset.1]
name="Windows"
platform="Windows Desktop"
runnable=false
export_filter="all_resources"
include_filter="assets/narrative/*.json"
exclude_filter="tests/*,tools/*"
export_path="../windows/TheLightInTheDarkness.exe"
[preset.1.options]
custom_template/release="NATIVE_TEMPLATE"
binary_format/architecture="x86_64"
binary_format/embed_pck=true
application/modify_resources=false
debug/export_console_wrapper=0
'''.replace('NATIVE_TEMPLATE',template.as_posix())
(project/'export_presets.cfg').write_text(preset,encoding='utf-8')
run('import',['--editor','--import','--quit'])
run('domain-tests',['--script','res://tests/domain_tests.gd'])
if (project/'tests/integration_tests.gd').exists():
    run('integration-tests',['--fixed-fps','60','--script','res://tests/integration_tests.gd'])
run('web-export',['--export-release','Web',str(web/'index.html')])
if not args.skip_native:
    run('windows-export',['--export-release','Windows',str(native/'TheLightInTheDarkness.exe')])
manifest={'godot':'4.7.2-stable','source_files':{str(p.relative_to(source)):hashlib.sha256(p.read_bytes()).hexdigest() for p in source.rglob('*') if p.is_file() and '.godot' not in p.parts},'output':str(output)}
(output/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('BUILD COMPLETE',output,flush=True)
