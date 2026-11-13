#!/usr/bin/env python3
"""Select comparable runs, then plot observed post-epoch validation accuracy only.
No clock(), GPU-event-only time, total/epochs estimates, interpolation or smoothing.
"""
import argparse
import csv
import json
import math
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERSIONS = {
    'cpu': ('CPU', 'cpu/main.c'),
    'baseline': ('CUDA baseline', 'cuda_00_baseline/fnn_cuda.cu'),
    'opt1': ('Opt1 selective tiling', 'cuda_01_selective_tiling/fnn_cuda_opt1.cu'),
    'opt2': ('Opt2 forward fusion', 'cuda_02_forward_fusion/fnn_cuda_opt2.cu'),
    'opt3': ('Opt3 register reuse', 'cuda_03_register_reuse/fnn_cuda_opt3.cu'),
}
CPU_RUN = ROOT/'results/cpu/wall_time_20261112/metrics.csv'
INCREMENTAL_RUN = ROOT/'results/incremental_training'

def relative(path):
    return Path(path).resolve().relative_to(ROOT.resolve()).as_posix()

PLOT_FORMATS = ('png','pdf')
TIMING = 'monotonic wall: shuffle + train + post-epoch train/validation evaluation; excludes setup/warmup/final test/export'

def read_info(path):
    if not path.exists():
        return {}
    return dict(line.split('=', 1) for line in path.read_text(errors='replace').splitlines() if '=' in line)

def write_csv(path, rows, fields=None):
    if fields is None:
        fields = list(rows[0]) if rows else []
    with path.open('x', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)

def version_for(path, info):
    p = path.as_posix().lower()
    impl = info.get('implementation', '').lower()
    if 'incremental' in impl or '/incremental/' in p:
        return None
    for key, token in [('opt3','opt3'), ('opt2','opt2'), ('opt1','opt1')]:
        if token in impl or f'/a_{key}/' in p or f'/results/{key}/' in p:
            return key
    if 'plain cuda' in impl or '/cuda_baseline/' in p or '/a_baseline/' in p:
        return 'baseline'
    if impl.startswith('cpu') or '/results/cpu/' in p or '/a_cpu/' in p:
        return 'cpu'
    return None

def logs_for(path):
    candidates = [path.parent / 'train.log', path.parent.with_suffix('.log'), path.parent.parent / (path.parent.name + '.log')]
    if '/cuda_baseline/training_20ep/' in path.as_posix():
        candidates.append(ROOT/'results/cuda_baseline/logs/cuda_full.log')
    if '/cpu/' in path.as_posix():
        candidates.append(path.parent/'train_full.log')
    return sorted(set(p for p in candidates if p.is_file()))

def select_runs(paths):
    manifest, data, seen = [], [], set()
    for path in sorted(set(p.resolve() for p in paths)):
        info = read_info(path.parent/'run_info.txt')
        variant = version_for(path, info)
        logs = logs_for(path)
        text = '\n'.join(p.read_text(errors='replace') for p in logs)
        with path.open(encoding='utf-8-sig', newline='') as stream:
            rows = list(csv.DictReader(stream))
        reasons = []
        low = path.as_posix().lower()
        if variant == 'cpu' and CPU_RUN.exists() and path != CPU_RUN.resolve():
            reasons.append('not the designated formal CPU wall-time run; historical CPU retained but not counted')
        if variant is None:
            reasons.append('not one of five comparison versions')
        if any(x in low for x in ['profiling', 'smoke', 'tiling_attempt', 'outputs_snapshot']):
            reasons.append('profiling/smoke/failed attempt/duplicate snapshot')
        if len(rows) != 20 or [r.get('epoch') for r in rows] != [str(i) for i in range(1,21)]:
            reasons.append('not a complete 20-epoch run')
        signature = (variant, path.read_bytes())
        if signature in seen:
            reasons.append('byte-identical metrics duplicate')
        # Only canonical historical CPU is admitted without run_info, for epoch plot only.
        historical_cpu = variant == 'cpu' and path == (ROOT/'results/cpu/baseline/metrics.csv').resolve()
        if not historical_cpu:
            required = {'architecture':'784,128,64,10', 'seed':'39', 'batch':'32', 'epochs':'20'}
            if variant != 'cpu':
                required['threads'] = '128'
            if variant in ('opt1','opt2','opt3'):
                required.update(tile='16', gemm_policy='targeted')
            if variant in ('opt2','opt3'):
                required['forward_fusion'] = 'on'
            if variant == 'opt3':
                required['dw1_rows_per_thread'] = '2'
            if any(info.get(k) != v for k,v in required.items()):
                reasons.append('missing/mismatched fixed parameters')
            try:
                if abs(float(info.get('lr','nan')) - .01) > 1e-8 or not math.isfinite(float(info.get('lr','nan'))):
                    reasons.append('learning rate mismatch')
            except ValueError:
                reasons.append('invalid learning rate')
        split_ok = ('Training 48000, validation 12000, test 10000' in text or
                    all(info.get(k)==str(v) for k,v in [('train_count',48000),('val_count',12000),('test_count',10000)]))
        if not split_ok:
            reasons.append('split counts not established by log/info')
        try:
            accuracies = [float(r['val_accuracy']) for r in rows]
            if not all(math.isfinite(a) and 0 <= a <= 1 for a in accuracies):
                reasons.append('invalid validation accuracy')
        except (KeyError, ValueError):
            reasons.append('missing/invalid validation accuracy')
        wall_ok = bool(rows) and all('epoch_wall_s' in r for r in rows)
        if wall_ok:
            try:
                wall_ok = all(math.isfinite(float(r['epoch_wall_s'])) and float(r['epoch_wall_s']) > 0 for r in rows)
            except ValueError:
                wall_ok = False
        if variant == 'cpu' and info.get('timing') != 'monotonic_shuffle_train_trainval_evaluation':
            wall_ok = False
        eligible = not reasons
        if eligible:
            seen.add(signature)
        source = ROOT/VERSIONS[variant][1] if variant else None
        entry = dict(run_id=relative(path.parent), version=variant or 'excluded', metrics_path=relative(path),
                     logs=';'.join(relative(p) for p in logs),run_info=relative(path.parent/'run_info.txt') if info else '',
                     source_path=relative(source) if source else '',
                     parameters=json.dumps({k:info[k] for k in ['architecture','epochs','seed','lr','batch','threads','tile','gemm_policy','forward_fusion','dw1_rows_per_thread'] if k in info},sort_keys=True),
                     data_split='48000/12000/10000' if split_ok else 'unverified',
                     timing_definition=TIMING if wall_ok else 'no comparable epoch wall time',
                     eligible_accuracy=eligible,eligible_time=eligible and wall_ok,
                     reason='; '.join(reasons + ([] if wall_ok else ['missing comparable epoch wall time'])))
        manifest.append(entry)
        if eligible:
            cumulative = 0.0
            for r in rows:
                if wall_ok:
                    cumulative += float(r['epoch_wall_s'])
                data.append(dict(version=variant, run_id=entry['run_id'], epoch=int(r['epoch']),
                                 val_accuracy_pct=100*float(r['val_accuracy']), val_loss=float(r['val_loss']),
                                 epoch_wall_s=float(r['epoch_wall_s']) if wall_ok else '',
                                 cumulative_epoch_wall_s=cumulative if wall_ok else ''))
    return manifest, data

def analyze(manifest, data, out, plots=True):
    write_csv(out/'epoch_observations.csv', data)
    tta=[]
    for m in manifest:
        if not m['eligible_accuracy']:
            continue
        run=[r for r in data if r['run_id']==m['run_id']]
        for threshold in (90,95,96):
            hit=next((r for r in run if r['val_accuracy_pct']>=threshold),None)
            status='missing_epoch_wall_time' if not m['eligible_time'] else 'reached' if hit else 'not_reached'
            tta.append(dict(version=m['version'],run_id=m['run_id'],threshold_pct=threshold,status=status,
                            epoch=hit['epoch'] if hit else 'not_reached',
                            cumulative_epoch_wall_s=hit['cumulative_epoch_wall_s'] if hit and m['eligible_time'] else 'not_reached' if not hit else 'missing'))
    write_csv(out/'time_to_accuracy.csv',tta)
    summaries=[]
    for v in VERSIONS:
        for t in (90,95,96):
            group=[r for r in tta if r['version']==v and r['threshold_pct']==t]
            values=[r['cumulative_epoch_wall_s'] for r in group if r['status']=='reached']
            summaries.append(dict(version=v,threshold_pct=t,n_runs=len(group),first_epoch_min=min((r['epoch'] for r in group if r['status']=='reached'),default='not_reached'),first_epoch_max=max((r['epoch'] for r in group if r['status']=='reached'),default='not_reached'),n_accuracy_reached=sum(r['epoch']!='not_reached' for r in group),n_timed_reached=len(values),n_missing_time=sum(r['status']=='missing_epoch_wall_time' for r in group),
                                  mean_wall_s=statistics.mean(values) if values else '',
                                  stdev_wall_s=statistics.stdev(values) if len(values)>1 else '',
                                  repeats='seed=39 timing repeats, not independent convergence seeds'))
    write_csv(out/'time_to_accuracy_summary.csv',summaries)
    epoch_summary=[]
    for v in VERSIONS:
        rr=[r for r in data if r['version']==v and r['epoch_wall_s']!='']
        ids=sorted({r['run_id'] for r in rr})
        totals=[sum(r['epoch_wall_s'] for r in rr if r['run_id']==i) for i in ids]
        epoch_summary.append(dict(version=v,n_timing_runs=len(ids),mean_20epoch_wall_s=statistics.mean(totals) if totals else '',mean_measured_epoch_wall_s=statistics.mean(r['epoch_wall_s'] for r in rr) if rr else ''))
    write_csv(out/'epoch_time_summary.csv',epoch_summary)
    speedups=[]
    for reference in ['cpu','baseline']:
        for row in summaries:
            if row['version']==reference or row['mean_wall_s']=='':
                continue
            ref=next(s for s in summaries if s['version']==reference and s['threshold_pct']==row['threshold_pct'])
            if ref['mean_wall_s']=='':
                continue
            speedups.append(dict(reference=reference,version=row['version'],threshold_pct=row['threshold_pct'],reference_n=ref['n_timed_reached'],version_n=row['n_timed_reached'],speedup_ratio_of_mean_time_to_accuracy=ref['mean_wall_s']/row['mean_wall_s'],definition='ratio of observed per-run mean threshold epoch wall times; not steady-state train_GPU speedup'))
    write_csv(out/'time_to_accuracy_speedup.csv',speedups,['reference','version','threshold_pct','reference_n','version_n','speedup_ratio_of_mean_time_to_accuracy','definition'])
    missing=[v for v in VERSIONS if not any(m['version']==v and m['eligible_time'] for m in manifest)]
    if not plots:
        return
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    colors=dict(zip(VERSIONS,['#444444','#0072B2','#E69F00','#009E73','#CC79A7']))
    for filename,xkey,cuda,log in [('accuracy_vs_epoch','epoch',False,False),('validation_accuracy_vs_time','cumulative_epoch_wall_s',False,False),('validation_accuracy_vs_time_cuda','cumulative_epoch_wall_s',True,False),('validation_accuracy_vs_time_log','cumulative_epoch_wall_s',False,True)]:
        fig,ax=plt.subplots(figsize=(8.2,5.0),layout='constrained')
        for v,(label,_) in VERSIONS.items():
            if cuda and v=='cpu':
                continue
            runs=sorted({r['run_id'] for r in data if r['version']==v and r[xkey]!=''})
            for i,run_id in enumerate(runs):
                rows=[r for r in data if r['run_id']==run_id]
                ax.plot([r[xkey] for r in rows],[r['val_accuracy_pct'] for r in rows],color=colors[v],linewidth=.8,alpha=.22)
            if runs:
                repeated=[[r for r in data if r['run_id']==run] for run in runs]
                xx=[statistics.mean(rr[i][xkey] for rr in repeated) for i in range(20)]
                yy=[statistics.mean(rr[i]['val_accuracy_pct'] for rr in repeated) for i in range(20)]
                ax.plot(xx,yy,color=colors[v],marker='o',markersize=2.6,linewidth=1.6,label=f'{label} (n={len(runs)})')
            if not runs:
                ax.plot([],[],color=colors[v],linestyle=':',label=f'{label}: missing wall time' if xkey!='epoch' else f'{label}: missing data')
        if log:
            ax.set_xscale('log')
        ax.set(xlabel='Epoch' if xkey=='epoch' else 'Cumulative epoch wall time (s)',ylabel='Post-epoch validation accuracy (%)',title='MNIST, seed 39; observed epoch endpoints')
        ax.grid(True,alpha=.2);ax.legend(fontsize=8)
        if missing and not cuda and xkey!='epoch':
            fig.suptitle('Incomplete five-version comparison: missing '+', '.join(missing),fontsize=10)
        save_figure(fig,out/'figures'/filename)
        plt.close(fig)

def save_figure(fig,stem):
    # Direct Matplotlib PDF export preserves vector paths and text.
    stem.parent.mkdir(parents=True,exist_ok=True)
    for ext in PLOT_FORMATS:
        fig.savefig(stem.with_suffix('.'+ext),dpi=200,bbox_inches='tight',pad_inches=0.12)


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True);p.add_argument('--extra-root',action='append',type=Path,default=[]);p.add_argument('--no-plots',action='store_true');p.add_argument('--png-only',action='store_true',help='PNG rendering only when optional PDF dependencies are unavailable');p.add_argument('--incremental-root',type=Path,default=INCREMENTAL_RUN if INCREMENTAL_RUN.exists() else None)
    global PLOT_FORMATS
    a=p.parse_args();PLOT_FORMATS=('png',) if a.png_only else ('png','pdf');a.out.mkdir(parents=True,exist_ok=False)
    paths=list((ROOT/'results').rglob('metrics.csv'))
    for root in a.extra_root:
        paths.extend(root.rglob('metrics.csv'))
    manifest,data=select_runs(paths);analyze(manifest,data,a.out,not a.no_plots)
    if a.incremental_root:
        plot_incremental(a.incremental_root,a.out,not a.no_plots)
    print('Saved analysis to',a.out)

def plot_incremental(root,out,plots=True):
    rows=[]
    for stage in ['initial_training','new_data_training']:
        path=root/stage/'metrics.csv'
        info=read_info(path.parent/'run_info.txt')
        if info.get('completed')!='true':
            raise ValueError(f'Incomplete incremental stage: {path}')
        with path.open() as stream:
            for row in csv.DictReader(stream):
                row['stage']=stage;rows.append(row)
    first=[r for r in rows if r['stage']=='initial_training' and r['event']=='epoch_end']
    second=[r for r in rows if r['stage']=='new_data_training']
    if len(first)!=10 or len([r for r in second if r['event']=='epoch_end'])!=5:
        raise ValueError('Expected 10 initial epochs and 5 new-data epochs')
    if second[0]['event']!='loaded_before_update' or abs(float(first[-1]['val_accuracy'])-float(second[0]['val_accuracy']))>1e-10 or abs(float(first[-1]['val_loss'])-float(second[0]['val_loss']))>1e-10:
        raise ValueError('Pre-update validation differs from saved initial model')
    if int(first[-1]['total_updates'])!=12500 or int(second[-1]['total_updates'])!=13750:
        raise ValueError('Unexpected update counts')
    if abs(float(first[-1]['cumulative_epoch_wall_s'])-float(second[0]['cumulative_epoch_wall_s']))>1e-8:
        raise ValueError('Stage wall time discontinuity')
    summary=[]
    for stage in ['initial_training','new_data_training']:
        rr=[r for r in rows if r['stage']==stage];ends=[r for r in rr if r['event']=='epoch_end'];info=read_info(root/stage/'run_info.txt')
        summary.append(dict(stage=stage,training_samples=int(ends[0]['active_train_count']),epochs=len(ends),parameter_updates=int(ends[-1]['total_updates'])-int(rr[0]['total_updates']),validation_accuracy_before_pct=100*float(rr[0]['val_accuracy']),validation_accuracy_after_pct=100*float(ends[-1]['val_accuracy']),validation_loss_after=float(ends[-1]['val_loss']),training_event_sum_s=sum(float(r['train_gpu_ms'])/1000 for r in ends),epoch_wall_sum_s=sum(float(r['epoch_wall_s']) for r in ends),process_wall_s_before_cleanup=float(info['process_wall_s_before_cleanup']),final_test_accuracy_pct=100*float(info['final_test_accuracy']) if stage=='new_data_training' else ''))
    write_csv(out/'incremental_summary.csv',summary)
    write_csv(out/'incremental_observations.csv',rows)
    if not plots:
        return
    import matplotlib.pyplot as plt
    fig,axs=plt.subplots(1,2,figsize=(10.4,4.8),layout='constrained')
    for stage,label,color in [('initial_training','Initial 40000 x 10','#0072B2'),('new_data_training','New 8000 x 5','#E69F00')]:
        rr=[r for r in rows if r['stage']==stage and (stage=='new_data_training' or r['event']=='epoch_end')]
        axs[0].plot([float(r['cumulative_epoch_wall_s']) for r in rr],[100*float(r['val_accuracy']) for r in rr],marker='o',label=label,color=color)
    arrival=float(second[0]['cumulative_epoch_wall_s'])
    axs[0].axvline(arrival,color='gray',linestyle='--',label='New data arrives')
    axs[0].set(xlabel='Cumulative epoch wall time (s)',ylabel='Validation accuracy (%)',title='Two-stage Opt3 training')
    axs[0].legend(fontsize=8)
    axs[1].plot([float(r['cumulative_epoch_wall_s'])-arrival for r in second],[100*float(r['val_accuracy']) for r in second],marker='o',color='#E69F00')
    axs[1].set(xlabel='New-data epoch wall time (s)',ylabel='Validation accuracy (%)',title='Checkpoint reload before any update')
    for ax in axs:ax.grid(alpha=.2)
    fig.suptitle('Setup, warm-up, checkpoint I/O and pre-update evaluation excluded')
    save_figure(fig,out/'figures'/'incremental_validation_accuracy_vs_time')
    plt.close(fig)

if __name__=='__main__':
    main()
