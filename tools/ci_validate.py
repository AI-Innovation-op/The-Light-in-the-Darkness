"""Cross-platform CI: verified Godot download, architecture, domain, and scene tests."""
import argparse, hashlib, json, os, platform, re, subprocess, sys, tempfile, urllib.request, zipfile
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('--godot',type=Path)
parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parents[1])
args=parser.parse_args()
version='4.7.2-stable'
cache=Path(tempfile.gettempdir())/'tlitd-ci-runtime'
cache.mkdir(exist_ok=True)
engine=args.godot
if engine is None:
    suffix='win64.exe.zip' if platform.system()=='Windows' else 'linux.x86_64.zip'
    archive_name=f'Godot_v{version}_{suffix}'
    base=f'https://github.com/godotengine/godot-builds/releases/download/{version}/'
    def fetch(url):
        request=urllib.request.Request(url,headers={'User-Agent':'TLITD-CI'})
        with urllib.request.urlopen(request,timeout=90) as response:
            return response.read()
    sums=fetch(base+'SHA512-SUMS.txt').decode()
    data=fetch(base+archive_name)
    expected=next(line.split()[0] for line in sums.splitlines() if line.split()[-1].lstrip('*')==archive_name)
    assert hashlib.sha512(data).hexdigest()==expected,'Official Godot checksum mismatch'
    archive=cache/archive_name
    archive.write_bytes(data)
    with zipfile.ZipFile(archive) as package:
        member=next(n for n in package.namelist() if n.endswith('_console.exe')) if platform.system()=='Windows' else next(n for n in package.namelist() if n.endswith('.x86_64'))
        engine=cache/Path(member).name
        engine.write_bytes(package.read(member))
        engine.chmod(0o755)

environment={**os.environ,'APPDATA':str(cache/'profile'),'XDG_DATA_HOME':str(cache/'data'),'XDG_CONFIG_HOME':str(cache/'config')}
for name in ['profile','data','config']:
    (cache/name).mkdir(exist_ok=True)
subprocess.run([sys.executable,str(args.project/'tools/check_architecture.py')],check=True)
checks=0
for name,extra in [
    ('import',['--editor','--import','--quit']),
    ('domain',['--script','res://tests/domain_tests.gd']),
    ('integration',['--fixed-fps','60','--script','res://tests/integration_tests.gd'])
]:
    result=subprocess.run([str(engine),'--headless','--path',str(args.project),*extra],capture_output=True,text=True,timeout=180,env=environment)
    output=result.stdout+'\n'+result.stderr
    print(output,flush=True)
    if result.returncode or 'SCRIPT ERROR:' in output or 'Parse Error:' in output:
        raise SystemExit(result.returncode or 1)
    for line in output.splitlines():
        if '_TEST_RESULT ' in line:
            payload=json.loads(line.split('_TEST_RESULT ',1)[1])
            assert not payload['failures']
            checks+=payload['checks']
print(f'CI VALIDATION PASSED: {checks} checks')
