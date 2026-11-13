import argparse, subprocess, os
from pathlib import Path
parser=argparse.ArgumentParser()
parser.add_argument('--build',type=Path,required=True)
parser.add_argument('--runtime',type=Path,required=True)
args=parser.parse_args()
env={**os.environ,'APPDATA':str(args.build/'profile')}
commands={
    'integration-verbose':[str(args.runtime/'Godot_v4.7.2-stable_win64_console.exe'),'--headless','--verbose','--path',str(args.build/'source'),'--fixed-fps','60','--script','res://tests/integration_tests.gd'],
    'native-boot':[str(args.build/'windows/TheLightInTheDarkness.exe'),'--headless','--fixed-fps','60','--quit-after','90']
}
for name,command in commands.items():
    result=subprocess.run(command,capture_output=True,text=True,timeout=90,env=env,cwd=args.build/'windows')
    output=result.stdout+'\n'+result.stderr
    (args.build/'logs'/(name+'.log')).write_text(output,encoding='utf-8')
    print(name,'exit',result.returncode)
    print('\n'.join(line for line in output.splitlines() if any(t in line for t in ['Leaked','instances','Orphan','SCRIPT ERROR','ERROR:','TEST_RESULT'])))
    assert result.returncode==0 and 'SCRIPT ERROR:' not in output
