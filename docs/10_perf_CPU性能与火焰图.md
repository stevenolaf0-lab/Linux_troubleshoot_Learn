# 10 perf：CPU 热点与调用栈

## 本章目标

把“CPU 高”定位到线程、函数、源码行，并判断是算法复杂度、复制还是分配问题。

## 构建

性能分析使用 `RelWithDebInfo`，保留符号并接近发布优化级别：

```bash
cmake --preset x86-release
cmake --build --preset x86-release --target spectrum_hotspot
BIN=./build/x86-release/demos/10_spectrum_hotspot/spectrum_hotspot
```

## perf stat

```bash
perf stat -d "$BIN" --mode naive --duration 5
perf stat -d "$BIN" --mode fixed --duration 5
```

关注：运行时间、cycles、instructions、IPC、branches、cache misses 和 context switches。事件支持情况取决于 CPU 和内核。

## perf top/record/report

```bash
perf top -p PID
perf record -F 99 -g -- "$BIN" --mode naive --duration 10
perf report
perf annotate slow_dft
```

若调用栈断裂，确认程序和依赖保留 frame pointer 或使用 DWARF 调用栈：

```bash
perf record -F 99 --call-graph dwarf -- COMMAND
```

## 学员任务

比较 `naive`、`copy`、`fixed`：

1. 找出最大的 CPU 热点。
2. 比较单位时间完成的迭代数。
3. 解释 `copy` 为什么算法一样但吞吐下降。

## 实战答案

- `naive` 使用 O(N²) DFT，热点集中在三角函数和复数累加。
- `fixed` 使用 O(N log N) radix-2 FFT。
- `copy` 在计算前制造三份完整数据复制，真实设备中会消耗内存带宽并增加分配压力。

性能优化必须以相同输入比较吞吐、延迟和结果正确性，不能只看某一次 CPU 百分比。

## ARM64 提醒

ARM 与 x86 的 PMU 事件和微架构不同。QEMU 的采样不代表真实 ARM；最终必须在目标 ARM CPU 上重新采集 `perf stat/record`。
