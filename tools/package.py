import argparse, hashlib, json, shutil, urllib.request, zipfile
from pathlib import Path
parser=argparse.ArgumentParser()
parser.add_argument('--build',type=Path,required=True)
parser.add_argument('--version',default='0.2')
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
build=args.build.resolve()
# Compiled gameplay source must match the reviewed source before packaging.
for source in (root/'src').rglob('*.gd'):
    staged=build/'source'/source.relative_to(root)
    assert staged.read_bytes()==source.read_bytes(),f'Stale compiled source: {source}'
for name in ['LICENSE.txt','COPYRIGHT.txt']:
    target=build/'windows'/('GODOT_'+name)
    if not target.exists():
        url='https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/'+name
        with urllib.request.urlopen(url,timeout=60) as response:
            target.write_bytes(response.read())
    shutil.copy2(target,build/'web'/target.name)
shutil.copy2(root/'README.md',build/'windows/LEEME.md')
packages=build/'packages'; packages.mkdir(exist_ok=True)
for label,folder in [('Windows',build/'windows'),('Web',build/'web'),('Fuentes',root)]:
    output=packages/f'The-Light-in-the-Darkness-v{args.version}-{label}.zip'
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for path in folder.rglob('*'):
            if path.is_file() and not any(part in ['.git','.godot','__pycache__'] for part in path.relative_to(folder).parts):
                archive.write(path,path.relative_to(folder))
    print(output.name,output.stat().st_size,flush=True)
summary={}
for name,marker in [('domain-tests','DOMAIN_TEST_RESULT '),('integration-tests','INTEGRATION_TEST_RESULT ')]:
    lines=(build/'logs'/(name+'.log')).read_text(encoding='utf-8').splitlines()
    result=json.loads(next(line[len(marker):] for line in lines if line.startswith(marker)))
    assert not result['failures']
    summary[name]=result
summary['packages']={p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in packages.glob('*.zip')}
summary['source_files']={p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file() and '.godot' not in p.parts}
(build/'delivery-manifest.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print('Verified checks:',sum(summary[k]['checks'] for k in ['domain-tests','integration-tests']))
