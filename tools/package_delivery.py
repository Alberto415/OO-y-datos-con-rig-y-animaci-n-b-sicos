"""Empaqueta los recursos necesarios, excluyendo cachés, clones y videos intermedios."""
from pathlib import Path
import hashlib, json, zipfile

ROOT = Path(__file__).resolve().parents[1]
excluded = {'.git','.godot','tmp','tarea1-referencia','__pycache__'}
archive = ROOT / 'output/Entrega_Tarea_2_Alberto.zip'
entries=[]
for path in sorted(ROOT.rglob('*')):
    relative=path.relative_to(ROOT)
    if not path.is_file() or any(part in excluded for part in relative.parts): continue
    if path==archive or path.suffix in ['.avi','.pyc','.zip']: continue
    if relative.as_posix()=='output/evidence/manifest.json': continue
    entries.append(path)
manifest=[{'path':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in entries]
manifest_path=ROOT/'output/evidence/manifest.json'
manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf-8')
entries.append(manifest_path)
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for path in entries: z.write(path,path.relative_to(ROOT))
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
print(json.dumps({'archive':str(archive),'files':len(entries),'bytes':archive.stat().st_size},indent=2))
