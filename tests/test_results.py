"""Local evidence checks only: these do not execute CUDA or train a model."""
import csv
import importlib.util
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
spec=importlib.util.spec_from_file_location('analysis',ROOT/'scripts/analyze_time_accuracy.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
def read(path):
    with path.open(newline='',encoding='utf-8-sig') as f:return list(csv.DictReader(f))
class ResultEvidenceTests(unittest.TestCase):
    def test_checkpoint_payloads_not_committed_with_results(self):
        self.assertFalse(list((ROOT/'results').rglob('*.ckpt')))
    def test_jetson_pass_evidence_not_local_gpu_execution(self):
        for folder in [ROOT/'results/cpu/wall_time_20261112',a.INCREMENTAL_RUN]:
            self.assertEqual((folder/'status.txt').read_text().strip(),'COMPLETED')
            log=(folder/'runner.log').read_text()
            self.assertEqual(log.count('Overall CPU/GPU check: PASS'),4)
            for text in ['CPU fixture: PASS','Host checkpoint validation: PASS','Incremental GPU checks: PASS']:self.assertIn(text,log)
            self.assertIn('exact parameter/logits/loss roundtrip',(folder/'incremental_checks/PASS.txt').read_text())
            env=(folder/'environment.txt').read_text();self.assertIn('Orin Nano',env);self.assertIn('ARCH=sm_87',env)
    def test_ids_and_stage_continuity(self):
        root=a.INCREMENTAL_RUN
        self.assertEqual((root/'initial_training/sample_ids.csv').read_bytes(),(root/'new_data_training/sample_ids.csv').read_bytes())
        rows=read(root/'initial_training/sample_ids.csv')
        sets={name:{int(r['sample_id']) for r in rows if r['subset']==name} for name in {r['subset'] for r in rows}}
        for name,n in [('initial_40000',40000),('new_8000',8000),('validation_12000',12000),('test_10000',10000)]:self.assertEqual(len(sets[name]),n)
        train=[sets[n] for n in ['initial_40000','new_8000','validation_12000']]
        self.assertFalse(train[0]&train[1] or train[0]&train[2] or train[1]&train[2]);self.assertEqual(set.union(*train),set(range(60000)))
        initial=read(root/'initial_training/metrics.csv');new=read(root/'new_data_training/metrics.csv')
        for key in ['val_accuracy','val_loss','total_updates','cumulative_epoch_wall_s']:self.assertEqual(initial[-1][key],new[0][key])
        self.assertEqual(int(new[-1]['total_updates']),13750)
        self.assertAlmostEqual(sum(float(r['epoch_wall_s']) for r in new),.760827039,places=12)
        self.assertAlmostEqual(100*(float(new[-1]['val_accuracy'])-float(new[0]['val_accuracy'])),1/3,places=8)
    def test_one_cpu_and_actual_threshold_epochs(self):
        manifest,data=a.select_runs(list((ROOT/'results').rglob('metrics.csv')))
        counts={v:sum(m['version']==v and m['eligible_time'] for m in manifest) for v in a.VERSIONS}
        self.assertEqual(counts,dict(cpu=1,baseline=1,opt1=3,opt2=3,opt3=3))
        expected={'cpu':(319.108336923,493.208834642),'baseline':(9.386114114,15.340387537),'opt1':(8.567541537,14.013447661),'opt2':(7.888520655,12.907159669),'opt3':(7.460290254,12.207741468)}
        for version,targets in expected.items():
            for threshold,time in zip([95,96],targets):
                runs={r['run_id'] for r in data if r['version']==version};hits=[]
                for run in runs:
                    hit=next(r for r in data if r['run_id']==run and r['val_accuracy_pct']>=threshold);hits.append(hit['cumulative_epoch_wall_s'])
                    if threshold==96:self.assertEqual(hit['epoch'],17 if version=='cpu' else 18)
                self.assertAlmostEqual(sum(hits)/len(hits),time,places=8)
        for m in manifest:
            if m['eligible_time']:
                self.assertFalse(Path(m['metrics_path']).is_absolute());self.assertTrue((ROOT/m['metrics_path']).is_file())
    def test_report_figures(self):
        folder=ROOT/'results/time_accuracy/figures'
        names=['accuracy_vs_epoch','validation_accuracy_vs_time','validation_accuracy_vs_time_cuda','validation_accuracy_vs_time_log','incremental_validation_accuracy_vs_time']
        for name in names:
            data=(folder/(name+'.pdf')).read_bytes()
            self.assertTrue(data.startswith(b'%PDF'));self.assertNotRegex(data,rb'/Subtype\s*/Image\b');self.assertIn(b'/Font',data)
            self.assertTrue((folder/(name+'.png')).read_bytes().startswith(b'\x89PNG'))
        self.assertEqual(len(list(folder.glob('*.pdf'))),5)
if __name__=='__main__':unittest.main()
