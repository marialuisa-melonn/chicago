#!/bin/bash
# Sube archivos a GitHub por la API de Contents y FALLA con exit!=0 si algo no subió.
# (git push falla en este repo con "remote: fatal error in commit_refs", del lado de GitHub)
set -o pipefail
cd "$(dirname "$0")"
python3 - "$@" <<'PY'
import base64, json, subprocess, sys, os, tempfile
REPO='marialuisa-melonn/chicago'
files = sys.argv[1:] or ['index.html','data.json','manifest.json','README.md','deploy.sh',
                         'icon-180.png','icon-192.png','icon-512.png']
tmp = os.path.join(tempfile.gettempdir(), 'chi_payload.json')
fallos = 0
for f in files:
    if not os.path.exists(f):
        print('NO EXISTE  ' + f); fallos += 1; continue
    r = subprocess.run(['gh','api',f'repos/{REPO}/contents/{f}','--jq','.sha'],
                       capture_output=True, text=True)
    body = {'message': f'Actualizar {f}', 'branch':'main',
            'content': base64.b64encode(open(f,'rb').read()).decode()}
    if r.returncode==0 and r.stdout.strip(): body['sha'] = r.stdout.strip()
    open(tmp,'w').write(json.dumps(body))   # gh rompe con payloads grandes por stdin
    p = subprocess.run(['gh','api','-X','PUT',f'repos/{REPO}/contents/{f}','--input',tmp],
                       capture_output=True, text=True)
    if p.returncode==0:
        print('subido     ' + f)
    else:
        print('FALLO      ' + f + '  ' + p.stderr.strip()[:200]); fallos += 1
if os.path.exists(tmp): os.remove(tmp)
sys.exit(1 if fallos else 0)
PY
