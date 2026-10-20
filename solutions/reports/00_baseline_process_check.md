# 基线程序进程体检报告

## 1. 基本信息

- 报告整理日期：2026-10-20
- 实验环境：Ubuntu 24.04 WSL
- 处理器架构：x86-64
- Git 提交：`e6b69e0`
- 构建预设：`x86-debug`
- 可执行程序：`build/x86-debug/baseline_pipeline`
- 启动命令：`在这里填写 /proc/PID/cmdline 的真实输出`

## 2. 实验目标

建立单线程低负载程序的运行基线，并学习使用以下接口观察进程：

- `pidof`
- `ps`
- `top`
- `/proc/PID/status`
- `/proc/PID/cmdline`
- `/proc/PID/exe`

本实验不用于证明程序不存在内存泄漏，只记录一个时间点的进程状态。

## 3. 构建命令

```bash
cmake --preset x86-debug
cmake --build --preset x86-debug \
  --target baseline_pipeline \
  --parallel
```

## 4. 采集命令

查找进程：

```bash
PID=$(pidof baseline_pipeline)
echo "$PID"
```

采集进程快照：

```bash
ps -p "$PID" \
  -o pid,ppid,stat,pcpu,pmem,rss,vsz,nlwp,etime,comm,args
```

采集 `/proc` 状态：

```bash
grep -E '^(Name|State|Pid|PPid|Threads|VmSize|VmRSS|voluntary_ctxt_switches|nonvoluntary_ctxt_switches):' \
  "/proc/$PID/status"
```

检查完整命令行：

```bash
tr '\0' ' ' < "/proc/$PID/cmdline"
echo
```

检查真实可执行文件：

```bash
readlink -f "/proc/$PID/exe"
```

## 5. 原始证据

### 5.1 ps 输出

```text
PID      PPID     STAT  %CPU  %MEM  RSS   VSZ   NLWP  ELAPSED  COMMAND
2906622  2722532  S+    0.0   0.0   3596  6376  1     08:25    baseline_pipeli
```

原始终端中的 `ARGS` 列受到终端宽度限制而被截断，因此不将截断结果作为完整启动命令证据。

### 5.2 procfs 输出

```text
Name:   baseline_pipeli
State:  S (sleeping)
Pid:    2906622
PPid:   2722532
VmSize:     6376 kB
VmRSS:      3596 kB
Threads:        1
voluntary_ctxt_switches:        514
nonvoluntary_ctxt_switches:     0
```

### 5.3 可执行文件路径

```text
在这里填写 readlink -f /proc/PID/exe 的真实输出
./build/x86-debug/baseline_pipeline --duration 1000
```

### 5.4 完整启动参数

```text
在这里填写 /proc/PID/cmdline 的真实输出
/home/wl/workspace/Linux_troubleshoot_Learn/build/x86-debug/baseline_pipeline
```

如果没有保存，应明确写：

```text
本次未保存完整启动参数，无法确认实际 --duration 数值。
```

## 6. 证据解释

| 指标 | 观测值 | 解释 |
|---|---:|---|
| `STAT` | `S+` | 进程处于可中断睡眠，并属于终端前台进程组 |
| `%CPU` | `0.0` | 程序主要执行周期性休眠，没有明显 CPU 负载 |
| `RSS/VmRSS` | `3596 kB` | 当前约有 3.51 MiB 内存驻留在物理内存中 |
| `VSZ/VmSize` | `6376 kB` | 当前虚拟地址空间约为 6.23 MiB |
| `NLWP/Threads` | `1` | 进程只有一个线程 |
| `ELAPSED` | `08:25` | 采样时进程已经运行约 8 分 25 秒 |
| 主动上下文切换 | `514` | 与程序大约每秒主动休眠一次的行为基本吻合 |
| 非主动上下文切换 | `0` | 本次统计没有显示明显的调度器抢占 |

`ps` 与 `/proc` 中的以下数据相互一致：

```text
RSS     = VmRSS  = 3596 kB
VSZ     = VmSize = 6376 kB
NLWP    = Threads = 1
STAT S  = State sleeping
```

## 7. 当前结论

本次采样支持以下结论：

1. 进程仍然存在，并处于可中断睡眠状态。
2. 程序没有表现出明显的 CPU 密集行为。
3. 进程只有一个线程，符合当前基线程序设计。
4. 当前物理内存占用较小。
5. 主动上下文切换数量与周期性 `sleep_for` 行为基本吻合。
6. `Name` 和 `COMM` 因 Linux 短任务名称长度限制而显示为 `baseline_pipeli`。

## 8. 当前不能得出的结论

本次证据不能证明：

1. 程序不存在内存泄漏，因为只采集了一个时间点。
2. 程序长期运行时 RSS 始终稳定。
3. 系统不存在短时间 CPU 峰值。
4. 程序未来增加线程后仍然没有竞争或阻塞。
5. WSL 中的结果可以直接代表真实 ARM64 设备性能。

## 9. 证据缺口

本次采样存在以下不足：

- 没有在采样时记录精确时间戳。
- `ps` 的 `ARGS` 列被终端宽度截断。
- 如果没有保存 `/proc/PID/cmdline`，则无法确认实际运行参数。
- 只采集了一个时间点，没有形成时间序列。
- 没有同时记录系统整体 CPU、内存和负载。

后续实验需要同时记录：

```text
时间戳
PID
完整启动参数
CPU
VmRSS
线程数
上下文切换
心跳进度
```

## 10. 最终判断

当前证据表明，基线程序在采样时处于正常的周期性休眠状态，没有观察到明显的 CPU、内存或线程数量异常。

该结论仅适用于本次单点采样，不能替代长时间趋势监控。
