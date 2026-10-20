"""Analiza sólo una suite completa de 6 corridas reales; nunca datos de video/smoke."""
from pathlib import Path
import argparse, csv, json, statistics as st
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
METRICS = ['movement_block_ms', 'snapshot_ms', 'frame_wall_ms']

def quantile(values, p):
    ordered = sorted(values)
    index = (len(ordered) - 1) * p
    low = int(index)
    return ordered[low] + (ordered[min(low + 1, len(ordered)-1)] - ordered[low]) * (index-low)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--results', default=str(ROOT / 'results'))
    parser.add_argument('--session')
    args = parser.parse_args()
    groups = {}
    for path in Path(args.results).glob('*.json'):
        meta = json.loads(path.read_text(encoding='utf-8'))
        if meta.get('warmup_s') != 5 or meta.get('measurement_s') != 30 or meta.get('demo'):
            continue
        session = path.stem.rsplit('_', 2)[0]
        groups.setdefault(session, []).append((path, meta))
    valid = [key for key, items in groups.items() if len(items) == 6]
    session = args.session or max(valid, default='')
    if session not in valid:
        raise SystemExit('No hay una suite completa con 6 corridas de 5 + 30 segundos.')
    runs = sorted(groups[session], key=lambda item: item[1]['run'])
    assert [m['variant'] for _, m in runs] == ['OO','DATOS','DATOS','OO','OO','DATOS']
    invariants = ['seed','entities','engine','renderer','driver','viewport','vsync','cpu','gpu','debug_build']
    for _, meta in runs:
        assert all(meta[key] == runs[0][1][key] for key in invariants)
    output = ROOT / 'output' / 'analysis'
    output.mkdir(parents=True, exist_ok=True)
    summaries = []
    for path, meta in runs:
        with path.with_suffix('.csv').open(newline='', encoding='utf-8') as f:
            rows = list(csv.DictReader(f))
        assert len(rows) == meta['samples'] and len(rows) > 100
        assert 29.8 < float(rows[-1]['elapsed_s']) < 30.0
        assert all(float(b['elapsed_s']) > float(a['elapsed_s']) for a,b in zip(rows, rows[1:]))
        assert int(rows[-1]['draw_count']) > int(rows[0]['draw_count'])
        for metric in METRICS:
            values = [float(row[metric]) for row in rows]
            q1, q3 = quantile(values, .25), quantile(values, .75)
            summaries.append(dict(run=meta['run'], variant=meta['variant'], metric=metric,
                n=len(values), median_ms=st.median(values), q1_ms=q1, q3_ms=q3,
                iqr_ms=q3-q1, p95_ms=quantile(values,.95), source=path.with_suffix('.csv').name))
    with (output/'summary.csv').open('w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=summaries[0].keys())
        writer.writeheader(); writer.writerows(summaries)
    aggregate = []
    for variant in ['OO','DATOS']:
        for metric in METRICS:
            values = [r['median_ms'] for r in summaries if r['variant']==variant and r['metric']==metric]
            aggregate.append(dict(variant=variant, metric=metric, median_of_run_medians_ms=st.median(values),
                q1_run_medians_ms=quantile(values,.25), q3_run_medians_ms=quantile(values,.75),
                min_run_median_ms=min(values), max_run_median_ms=max(values)))
    with (output/'aggregate.csv').open('w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=aggregate[0].keys())
        writer.writeheader(); writer.writerows(aggregate)
    payload = dict(session=session, metadata=runs[0][1], runs=summaries, aggregate=aggregate)
    (output/'analysis.json').write_text(json.dumps(payload, indent=2, ensure_ascii=False),encoding='utf-8')
    plt.rcParams.update({'font.size':11, 'axes.spines.top':False, 'axes.spines.right':False})
    fig, axes = plt.subplots(2,1,figsize=(8.3,7.2))
    for ax, metric, title in zip(axes, ['movement_block_ms','frame_wall_ms'], ['Bloque de movimiento','Intervalo entre entradas a _process']):
        for x, variant, color in [(0,'OO','#157a72'),(1,'DATOS','#3469ad')]:
            group = next(a for a in aggregate if a['variant']==variant and a['metric']==metric)
            med = group['median_of_run_medians_ms']
            ax.errorbar([x],[med],yerr=[[med-group['q1_run_medians_ms']],[group['q3_run_medians_ms']-med]],fmt='s',color=color,capsize=9,markersize=9)
            values = [r['median_ms'] for r in summaries if r['variant']==variant and r['metric']==metric]
            ax.scatter([x-.12,x,x+.12],values,color=color,s=30,zorder=3)
        ax.set_xticks([0,1],['OO: nodo por entidad','DATOS: arrays agrupados'])
        ax.set_xlim(-.5,1.5); ax.set_ylim(bottom=0); ax.set_ylabel('Tiempo (ms)')
        ax.set_title(title, loc='left', fontweight='bold'); ax.grid(axis='y',alpha=.2)
    fig.suptitle('1 000 entidades / 3 corridas por variante',fontweight='bold')
    fig.text(.08,.015,'Puntos: medianas por corrida. Cuadrado: mediana de las 3 medianas. Barras: Q1-Q3 entre corridas.',fontsize=9)
    fig.tight_layout(rect=[0,.04,1,.96])
    fig.savefig(output/'comparison.png',dpi=180)
    fig.savefig(output/'comparison.svg')
    plt.close(fig)
    print(json.dumps(aggregate, indent=2))

if __name__ == '__main__': main()
