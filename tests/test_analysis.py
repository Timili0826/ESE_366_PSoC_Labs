import csv
import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
spec=importlib.util.spec_from_file_location('analysis',ROOT/'scripts/analyze_time_accuracy.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
class AnalysisTests(unittest.TestCase):
    def test_first_epoch_not_subtracted_and_no_extrapolation(self):
        with tempfile.TemporaryDirectory() as tmp:
            out=Path(tmp)
            manifest=[dict(version='cpu',run_id='fixture',eligible_accuracy=True,eligible_time=True)]
            data=[dict(version='cpu',run_id='fixture',epoch=1,val_accuracy_pct=90.5,val_loss=.3,epoch_wall_s=3.0,cumulative_epoch_wall_s=3.0),dict(version='cpu',run_id='fixture',epoch=2,val_accuracy_pct=94.0,val_loss=.2,epoch_wall_s=4.0,cumulative_epoch_wall_s=7.0)]
            a.analyze(manifest,data,out,False)
            with (out/'time_to_accuracy.csv').open() as stream:
                rows=list(csv.DictReader(stream))
            self.assertEqual(rows[0]['epoch'],'1');self.assertEqual(float(rows[0]['cumulative_epoch_wall_s']),3)
            self.assertEqual(rows[1]['status'],'not_reached');self.assertEqual(rows[2]['status'],'not_reached')
    def test_history_selection(self):
        manifest,data=a.audit(list((ROOT/'results').rglob('metrics.csv')))
        for v,n in [('cpu',1 if a.CPU_RUN.exists() else 0),('baseline',1),('opt1',3),('opt2',3),('opt3',3)]:
            self.assertEqual(sum(m['version']==v and m['eligible_time'] for m in manifest),n)
        self.assertFalse(any(m['eligible_time'] and any(x in m['metrics_path'] for x in ['profiling','tiling_attempt','smoke','outputs_snapshot']) for m in manifest))
        for v in ['cpu','baseline','opt1','opt2','opt3']:
            rows=[r for r in data if r['version']==v]
            for run_id in set(r['run_id'] for r in rows):
                rr=[r for r in rows if r['run_id']==run_id]
                self.assertEqual(rr[0]['epoch_wall_s'],rr[0]['cumulative_epoch_wall_s'])
                self.assertAlmostEqual(sum(r['epoch_wall_s'] for r in rr),rr[-1]['cumulative_epoch_wall_s'])
if __name__=='__main__':unittest.main()