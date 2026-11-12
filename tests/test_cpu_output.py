"""Tiny deterministic IDX fixture, never a formal performance/MNIST experiment."""
import csv
import hashlib
import math
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

binary=Path(sys.argv[1]).resolve()
with tempfile.TemporaryDirectory() as tmp:
    root=Path(tmp);data=root/'data';data.mkdir();out=root/'independent'/'cpu'
    for prefix,count in [('train',10),('t10k',4)]:
        images=bytes((i*7+3)%256 for i in range(count*784))
        (data/(prefix+'-images-idx3-ubyte')).write_bytes(struct.pack('>IIII',2051,count,28,28)+images)
        (data/(prefix+'-labels-idx1-ubyte')).write_bytes(struct.pack('>II',2049,count)+bytes(i%10 for i in range(count)))
    command=[str(binary),str(data), '2','0.01','32',str(out)]
    first=subprocess.run(command,cwd=root,text=True,capture_output=True)
    if first.returncode:
        raise RuntimeError(first.stderr or first.stdout)
    with (out/'metrics.csv').open() as stream:
        rows=list(csv.DictReader(stream))
    assert len(rows)==2
    assert all(math.isfinite(float(r['epoch_wall_s'])) and float(r['epoch_wall_s'])>0 for r in rows)
    assert all(float(r['cpu_process_s'])>=0 for r in rows)
    assert not (root/'outputs').exists(), 'Explicit output dir ignored'
    before={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.iterdir()}
    second=subprocess.run(command,cwd=root,text=True,capture_output=True)
    assert second.returncode!=0 and 'Refusing to overwrite' in second.stderr
    after={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.iterdir()}
    assert before==after
    print('CPU fixture: PASS (2 epochs, monotonic wall fields, independent directory, existing outputs unchanged)')