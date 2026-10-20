# 07 strace：系统调用与阻塞点

## 本章目标

程序没有崩溃但无响应时，判断它在等待网络、文件、锁、定时器还是设备。

## 常用命令

```bash
strace -f -tt -T -p PID
strace -f -tt -T -e trace=network,poll,read,write -p PID
strace -ff -o trace.log COMMAND
lsof -p PID
ls -l /proc/PID/fd
cat /proc/PID/stack
```

参数含义：

- `-f`：跟踪线程和子进程。
- `-tt`：微秒级绝对时间。
- `-T`：显示系统调用耗时。
- `-ff -o`：每个线程写独立文件。
- `-e trace=`：只保留目标调用。

## Demo：永久 recv

```bash
cmake --build --preset x86-debug --target blocking_io
./build/x86-debug/demos/07_blocking_io/blocking_io --mode recv &
PID=$!
strace -f -tt -T -p "$PID"
```

使用 `timeout` 防止实验永久挂住：

```bash
timeout 3s ./build/x86-debug/demos/07_blocking_io/blocking_io --mode recv
./build/x86-debug/demos/07_blocking_io/blocking_io --mode fixed
```

## Demo：FD 泄漏

```bash
./build/x86-debug/demos/07_blocking_io/blocking_io --mode fd-leak &
PID=$!
watch -n 1 "ls /proc/$PID/fd | wc -l"
lsof -p "$PID" | tail
```

## 学员任务

确定 `recv` 模式阻塞的系统调用、文件描述符类型以及是否设置超时；再计算 FD 增长速度。

## 实战答案

`recv` 模式在无发送方的 UDP socket 上无限等待。修复模式先用 `poll` 等待 1 秒，使线程能定期检查停止条件。`fd-leak` 不关闭 `/dev/null`，最终会达到 `RLIMIT_NOFILE`。

`strace` 只能说明线程当前处于哪个系统调用，业务上为何没有数据仍需结合包计数、设备状态和程序日志判断。
