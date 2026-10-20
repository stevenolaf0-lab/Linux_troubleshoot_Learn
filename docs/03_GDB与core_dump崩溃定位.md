# 03 GDB 与 core dump 崩溃定位

## 本章目标

程序已经退出时，利用 core 找到崩溃线程、调用链、源码行和关键参数。

## 开启 core dump

```bash
ulimit -c unlimited
cat /proc/sys/kernel/core_pattern
```

使用 systemd-coredump 的系统：

```bash
coredumpctl list crash_lab
coredumpctl info crash_lab
coredumpctl debug crash_lab
```

传统 core 文件：

```bash
gdb ./build/x86-debug/demos/03_crash_lab/crash_lab ./core
```

## Demo

```bash
cmake --build --preset x86-debug --target crash_lab
./build/x86-debug/demos/03_crash_lab/crash_lab --mode null
```

GDB 直接运行：

```gdb
gdb --args ./build/x86-debug/demos/03_crash_lab/crash_lab --mode null
run
info threads
thread apply all bt full
frame 0
info args
info locals
list
```

继续练习：

```bash
./crash_lab --mode abort
./crash_lab --mode stack
```

## 学员任务

不要先打开源码，通过调用栈回答：

1. 哪个线程收到信号？
2. 信号是什么？
3. 最靠近业务代码的栈帧是什么？
4. 哪个参数异常？

## 实战答案

`null` 模式在工作线程调用 `read_channel` 时解引用空 `DeviceState*`。应定位到最内层崩溃点，然后向上找到业务入口；只看到 libc 或线程启动函数还不够。

`abort` 是主动 `SIGABRT`，应继续寻找 abort 之前的断言或错误日志。`stack` 会出现大量重复栈帧，指向无限递归。

## 生产要求

- 使用 `RelWithDebInfo`，保留独立 debug symbol。
- 保存崩溃程序、动态库、core 和构建 ID。
- 二进制与 core 必须来自同一次构建。
- 不要在确认前清理设备上的 core。
- ARM core 可在 x86 主机上使用 `gdb-multiarch` 和对应 sysroot 分析。
