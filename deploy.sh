#!/bin/bash
# Sube archivos a GitHub por la API de Contents.
# (git push falla en este repo con "remote: fatal error in commit_refs", del lado de GitHub)
cd "$(dirname "$0")"
python3 - "$@" <<'PY'
import base64, json, subprocess, sys, os, tempfile
REPO='marialuisa-melonn/chicago'
files = sys.argv[1:] or ['index.html','data.json','manifest.json','README.md','deploy.sh',
                         'icon-180.png','icon-192.png','icon-512.png']
tmp = os.path.join(tempfile.gettempdir(), 'chi_payload.json')
for f in files:
    if not os.path.exists(f): continue
    r = subprocess.run(['gh','api',f'repos/{REPO}/contents/{f}','--jq','.sha'],
                       capture_output=True, text=True)
    body = {'message': f'Actualizar {f}', 'branch':'main',
            'content': base64.b64encode(open(f,'rb').read()).decode()}
    if r.returncode==0 and r.stdout.strip(): body['sha'] = r.stdout.strip()
    # gh rompe con payloads grandes por stdin: hay que pasarle un archivo
    open(tmp,'w').write(json.dumps(body))
    p = subprocess.run(['gh','api','-X','PUT',f'repos/{REPO}/contents/{f}','--input',tmp],
                       capture_output=True, text=True)
    print(('subido  ' if p.returncode==0 else 'FALLO   ') + f, p.stderr[:200] if p.returncode else '')
if os.path.exists(tmp): os.remove(tmp)
PY
