#!/bin/bash
# Sube los archivos cambiados a GitHub por la API (git push falla con "commit_refs" en este repo)
cd "$(dirname "$0")"
python3 - "$@" <<'PY'
import base64, json, subprocess, sys, os
REPO='marialuisa-melonn/chicago'
files = sys.argv[1:] or ['index.html','data.json','manifest.json','README.md','icon-180.png','icon-192.png','icon-512.png']
for f in files:
    if not os.path.exists(f): continue
    r = subprocess.run(['gh','api',f'repos/{REPO}/contents/{f}','--jq','.sha'],capture_output=True,text=True)
    body={'message':f'Actualizar {f}','content':base64.b64encode(open(f,'rb').read()).decode(),'branch':'main'}
    if r.returncode==0 and r.stdout.strip(): body['sha']=r.stdout.strip()
    p=subprocess.run(['gh','api','-X','PUT',f'repos/{REPO}/contents/{f}','--input','-'],
                     input=json.dumps(body),capture_output=True,text=True)
    print(('subido  ' if p.returncode==0 else 'FALLÓ   ')+f, p.stderr[:200] if p.returncode else '')
PY
