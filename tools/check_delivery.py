"""Comprueba una copia extraída sin caché de importación de Godot."""
from pathlib import Path
import argparse, json, subprocess, zipfile, datetime

ROOT = Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--godot',required=True)
args=parser.parse_args()
destination=ROOT/'tmp'/('clean_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
with zipfile.ZipFile(ROOT/'output/Entrega_Tarea_2_Alberto.zip') as z:
    z.extractall(destination)
assert not (destination/'.godot').exists()
checks=[]
def run(name, arguments, expected):
    result=subprocess.run([args.godot,'--path',str(destination),*arguments],cwd=destination,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=90)
    passed=result.returncode==0 and expected in result.stdout and 'SCRIPT ERROR' not in result.stderr
    checks.append({'check':name,'pass':passed,'exit_code':result.returncode,'stdout_tail':result.stdout[-1800:],'stderr':result.stderr[-1000:]})
    if not passed:
        raise RuntimeError(json.dumps(checks[-1],ensure_ascii=False))
run('import_from_empty_cache',['--headless','--import'],'DONE')
run('1000_entity_equivalence',['--headless','--script','scripts/verify.gd'],'PASS:')
run('imported_character_scene',['scenes/character.tscn','--quit-after','10'],'IMPORTED GLB clips=')
run('rendered_csv_smoke',['--','--smoke','--out=res://tmp/clean_smoke'],'SAVED')
csvs=list((destination/'tmp/clean_smoke').glob('*.csv'))
metas=[json.loads(p.read_text(encoding='utf-8')) for p in (destination/'tmp/clean_smoke').glob('*.json')]
assert len(csvs)==6 and len(metas)==6 and all(m['samples']>0 for m in metas)
report={'pass':True,'clean_cache_at_start':True,'csv_files_created':len(csvs),'checks':checks,'note':'Smoke comprueba reproducción y guardado; los CSV de 0.5 s se excluyen del informe.'}
(ROOT/'output/evidence/package_validation.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps({'pass':True,'checks':len(checks),'csvs':len(csvs)}))
