# Time–accuracy 与 incremental retraining：已保留结果与复现

所有命令从仓库根目录执行。此次工作只做本地导入、分析、文档和测试，
没有 SSH/SCP、重新训练、本机 CUDA 验证、commit、push 或 PR。

## 输入与结果位置

输入为 `timeinc_results.tar.gz` 和 `FNN_time_accuracy_incremental_analysis.zip`。
压缩包保留在仓库外，模型 checkpoint 不导入 Git。原 TAR 含17个 checkpoint：
15个正式训练模型和2个合成恢复自检模型，原包仍是完整本地备份。
分析 ZIP 还备份于本地仓库同级的 `local_inputs/`，不是仓库内容。

- `results/cpu/wall_time_20261112/`：新CPU metrics、run_info、train.log、runner、
  status、环境、源哈希和 incremental GPU PASS；旧baseline不变。
- `results/incremental/20261112/`：b_initial/b_new、阶段日志、完整ID、
  状态、GPU PASS、环境及source_sha256。
- `results/time_accuracy/20261112/`：五组PNG/矢量PDF、逐轮观测、
  time-to-accuracy、阶段汇总、相对路径manifest和交叉核对表。
- `docs/timeinc_import_manifest.csv`：TAR成员、目标路径、原字节SHA-256及
  checkpoint排除记录；原始CSV、日志、run_info、source_sha256均未改写。

不再次复制四组CUDA正式原始数据。分析直接读取其原有results路径。
分析ZIP内11组metrics与当前保留数据逐项一致；有些旧CUDA文件仅因Windows
checkout的CRLF/LF而原字节哈希不同，CSV内容一致，记录在input_crosscheck.csv。
原始来源的绝对路径保留在原run_info/日志中，不是当前复现依赖。
当前source_manifest的输入、日志及provenance定位均使用仓库相对路径。

## 固定条件与时间范围

MNIST，784-128-64-10、FP32、SGD lr=0.01、batch=32、seed=39；
48000 training、12000 validation、10000 test；CUDA一维threads128，
selective tile16、Opt2 fusion on、Opt3 dW1 rows2。

累计时间逐轮相加真实 `epoch_wall_s`，从shuffle前至训练及post-epoch
training/validation评估结束。包含首轮和CUDA相应完成/读回，不包含加载、
setup、warm-up、最终test、导出。CPU旧clock()和CUDA train_gpu_ms不是相同指标，
不能代替该wall time。Opt3约442ms/epoch的稳态train_GPU不含评估，不能混称。

只选择一个正式CPU wall-time运行；旧CPU和重复snapshot保留但不参与正式曲线。
CUDA baseline 1次；Opt1–3各3次同seed计时重复，不是独立收敛seed实验。
排除profiling、smoke、短compare、控制组和失败broad tiling。
先逐个运行查找首次epoch末达标，再汇总。没有平滑、外推或阈值插值。

| 版本 | n | ≥95%累计秒 | ≥96%累计秒 | ≥96%首次epoch |
|---|---:|---:|---:|---:|
| CPU | 1 | 319.108336923 | 493.208834642 | 17 |
| CUDA baseline | 1 | 9.386114114 | 15.340387537 | 18 |
| Opt1 selective | 3 | 8.567541537 | 14.013447661 | 18 |
| Opt2 fusion | 3 | 7.888520655 | 12.907159669 | 18 |
| Opt3 register reuse | 3 | 7.460290254 | 12.207741468 | 18 |

上述10个数值均由原CSV复算，与给定值在1e-9秒内一致。全部版本首次95%在epoch11。
CPU/GPU的96% crossing不强行统一epoch。约42.7743×(95%)、
40.4013×(96%)是CPU相对Opt3的time-to-accuracy比率，不是train_GPU比率。
历史CUDA构建/数据哈希不完整；跨日期没有统一功耗、温度和频率遥测，
不能将这些计时重复当作严格控制的跨日期置信区间实验。

## 增量实验与checkpoint

原seed39的48000训练ID按split顺序分为初始40000、新增8000，
validation固定12000、test来自独立10000图像文件。
两阶段sample_ids文件一致；本地核查了数量、train-file ID全覆盖和三组不相交。

初始40000训练10轮，12500次SGD更新。第二阶段为新进程加载epoch10模型，
只用新增8000训练5轮，再更新1250次。第二阶段第一行是
`loaded_before_update`，loss/accuracy/累计时间和初始末行完全相同。

validation accuracy由94.4916666667%变为94.8250%，提高0.3333333333个百分点。
新增5轮训练加评估为0.760827039秒，完整进程wall time为1.68254秒；
最终test accuracy95.60%。新增阶段第2轮准确率下降也保留，未删点或平滑。
test不参与更新/停止；没有初始阶段test结果，不能声称测得test前后提升。

`incremental/fnn_incremental.cu`直接include最终Opt3计算实现，
没有复制或修改kernel。checkpoint保存W[in,out]、bias、网络/激活结构、
训练配置、阶段/epoch、更新次数、shuffle RNG、active顺序、完整split ID、
数据指纹和累计epoch时间。普通SGD没有momentum。加载检查格式版本、长度、
完整消费、checksum、形状、有限值、配置与数据/ID一致性。
独占创建防止覆盖已有checkpoint。FNV-1a是意外损坏检测，不是加密认证。

warm-up只forward/loss/backward，确认不更新参数；每轮checkpoint写入在epoch计时外。
new模式显式开始新增数据阶段；resume恢复同一阶段的RNG和顺序。
增量入口省略旧benchmark的online monitoring reduction，因此其training_event_sum_s
也不能直接当作旧Opt3的相同train_GPU范围。完整进程wall另含setup、
载入、warm-up、checkpoint、pre-update评估和最终test。

这证明能够加载已有模型并从新数据继续训练；不能证明优于从头训练、
解决catastrophic forgetting，或整个课程作业所有要求都已满足。

## 已有Jetson验证与本次本地检查

**Jetson已有执行证据**：Orin Nano CC8.7，sm_87，CUDA12.6，GCC11.4。
两个status均COMPLETED；各runner含CPU编译/小样本输出PASS、host checkpoint
PASS、四个Overall CPU/GPU PASS及incremental GPU PASS。
PASS文件说明数值参考、warm-up不更新、checkpoint参数/logits/loss roundtrip，
以及连续3轮等于1轮+保存加载+2轮。正式CPU20轮和增量10+5轮均有原始CSV/日志。
这不是此次本机GPU执行。原环境记录的HEAD是dirty构建基准，
不能仅用HEAD代替完整源哈希。

计算源码/Makefile与Jetson记录原哈希一致，或仅有换行差异；
后续分析脚本/测试维护变更单独标注在source_hash_comparison.csv。
CUDA kernel、CPU src/include、checkpoint实现和训练算法未改。

**此次本地执行**：输入包/导入原始文件哈希、11组metrics交叉核对、阈值复算、
单一CPU计数、sample ID不相交、阶段连续性、相对来源路径、7项Python测试，
以及统一分析入口的CSV和PNG复现。五组矢量PDF/PNG按分析包原文件保留并验证，
PDF包含字体资源且没有Image资源。没有声称本机重新绘制了矢量PDF；
当前主脚本默认支持直接Matplotlib矢量导出，受限环境可用--png-only。
`checkpoint_audit_supplied.csv`是输入分析包的15个模型审计记录，
路径指向本地备份包中的模型，不是仓库中保留checkpoint的声明。

## 编译、训练与后台运行（可选复现，不由本次整合执行）

详见根README的构建/checkpoint命令。所有命令仍从仓库根目录开始：

```bash
make -C cpu
make -C incremental host-check
python3 tests/test_cpu_output.py cpu/fnn
mkdir -p outputs
LAUNCH=$(mktemp outputs/launch_XXXXXX.log)
nohup env ARCH=sm_87 DATA="$PWD/data/mnist" bash scripts/jetson_experiments.sh incremental > "$LAUNCH" 2>&1 &
echo "PID=$! launch_log=$LAUNCH"
```

检查完成状态，而不是把后台启动当作完成：

```bash
RUN=$(cat outputs/experiments/latest_incremental.txt)
cat "$RUN/pid.txt" "$RUN/status.txt"
tail -n 60 "$RUN/runner.log"
```

补跑CPU可使用cpu-only，全部五版本使用all-five；runner先编译/检查再串行训练，
失败停止并记录日志，flock防止同一目录runner并行。不要另开benchmark干扰计时。
现有原始模型只在本地输入压缩包里；需要恢复旧实验时先在本地解压到outputs
等忽略目录，并保留原archive_member路径关系，不要将模型提交Git。

## 单一分析入口

```bash
python3 -m pip install -r requirements-analysis.txt
python3 scripts/analyze_time_accuracy.py --out "outputs/reproduced_$(date +%Y%m%d_%H%M%S)"
python3 -m unittest discover -s tests -p 'test_analysis.py'
python3 -m unittest discover -s tests -p 'test_results.py'
```

需要CSV-only时加--no-plots；仅本机PNG重绘时加--png-only。输出目录必须不存在。
脚本自动使用results/cpu/wall_time_20261112和results/incremental/20261112，
不依赖下载ZIP中的data副本、C盘路径或原/workspace路径，也不需要模型checkpoint。
分析包的reproduce_analysis.py未安装为第二套正式计算逻辑。
保留的源manifest列出11个实际源CSV，selection_audit同时记录未选中的历史候选。
