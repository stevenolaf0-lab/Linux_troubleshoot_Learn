# 15 eBPF/bpftrace 进阶定位

## 本章目标

定位持续时间很短、传统轮询工具容易错过的系统调用和调度延迟。本章为选修内容。

## 前置检查

```bash
uname -r
test -e /sys/kernel/btf/vmlinux && echo BTF-ready
bpftrace --info
```

WSL、裁剪过的 ARM 内核或受限设备可能没有完整 BPF/BTF 支持。此时回退到 `strace -ff -tt -T`、perf 和程序内部时间戳。

## Demo

```bash
cmake --build --preset x86-debug --target intermittent_latency
BIN=./build/x86-debug/demos/15_intermittent_latency/intermittent_latency
$BIN --mode file-open --duration 30 &
PID=$!
```

常见工具：

```bash
sudo opensnoop-bpfcc -p "$PID"
sudo runqlat-bpfcc 1 10
sudo offcputime-bpfcc -p "$PID" 10
```

简单 bpftrace：

```bash
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat /pid == TARGET/ { @[comm] = count(); }'
```

把 `TARGET` 换成实际 PID。

## 学员任务

找出 `file-open` 模式周期性访问的文件，并用程序日志验证访问时间与延迟尖峰是否一致；再与 `sleep` 模式的 off-CPU 原因比较。

## 实战答案

`file-open` 每秒读取一次 `/etc/services`，`opensnoop` 能捕获打开行为。`sleep` 的延迟来自主动休眠，不是磁盘访问。两者在 CPU 利用率上都可能不明显，因此需要系统事件和应用时间戳关联。

## 注意事项

- 生产设备先确认权限、安全策略和性能影响。
- 内核函数和 tracepoint 可用性随版本变化。
- 不要把 QEMU 的调度延迟当作真实 ARM 板卡结论。
- 捕获数据可能包含路径和进程信息，应按现场数据规范保存。
