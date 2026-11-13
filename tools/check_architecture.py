"""Check dependency direction and resource references without third-party packages."""
from pathlib import Path
import re, json
root=Path(__file__).resolve().parents[1]
errors=[]
for script in (root/'src').rglob('*.gd'):
    text=script.read_text(encoding='utf-8')
    layer=script.relative_to(root/'src').parts[0]
    for dependency in re.findall(r'preload\("res://([^"\n]+)"\)',text):
        if not (root/dependency).is_file(): errors.append(f'{script.name}: missing {dependency}')
        target=Path(dependency).parts
        if len(target)>1 and target[0]=='src':
            if layer=='domain' and target[1]!='domain': errors.append(f'{script.name}: domain imports {target[1]}')
            if layer=='application' and target[1] not in ['domain','application']: errors.append(f'{script.name}: application imports {target[1]}')
            if layer=='infrastructure' and target[1] in ['application','presentation']: errors.append(f'{script.name}: infrastructure imports {target[1]}')
    if layer in ['domain','application']:
        for forbidden in ['extends Node','Input.','FileAccess.','get_tree(','AudioStreamPlayer','JavaScriptBridge']:
            if forbidden in text: errors.append(f'{script.name}: engine adapter leaked into {layer}: {forbidden}')
json.loads((root/'assets/narrative/oakhaven.json').read_text(encoding='utf-8'))
story=json.loads((root/'assets/narrative/story.json').read_text(encoding='utf-8'))
for pages in story['sequences'].values():
    for page in pages:
        image=root/'assets/cinematics'/(page['image']+'.png')
        if not image.exists(): errors.append(f'Missing narrative illustration: {image.name}')
assert not errors,'\n'.join(errors)
print('Architecture and narrative JSON checks passed.')
