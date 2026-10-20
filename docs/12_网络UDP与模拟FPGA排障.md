# 12 网络、UDP 与模拟 FPGA 排障

## 本章目标

根据包序号和分层计数判断丢包发生在发送端、链路、内核还是应用消费者。

## Demo

先启动接收端：

```bash
cmake --build --preset x86-debug --target fpga_udp_sim
BIN=./build/x86-debug/demos/12_fpga_udp_sim/fpga_udp_sim
$BIN --role receiver --mode fixed --duration 30
```

另一终端启动模拟 FPGA：

```bash
$BIN --role sender --mode normal --duration 20
$BIN --role sender --mode loss --duration 20
$BIN --role sender --mode flood --duration 20
```

## 核心命令

```bash
ss -u -a -n -p
ss -u -a -n -m
ip -s link
ethtool -S eth0
netstat -su
tcpdump -i lo -nn -tt udp port 39012
```

内核 UDP 统计：

```bash
grep -A1 '^Udp:' /proc/net/snmp
nstat -az | grep -i udp
```

## 学员任务

1. `loss` 模式缺失序号是否同时出现在 `tcpdump`？
2. `flood` 模式下接收缓冲区大小如何影响丢包？
3. 应用缺包而网卡无丢包能否直接判定 FPGA 故障？

## 实战答案

`loss` 是发送端主动跳过序号；抓包同样看不到该序号。`flood` 可能使 socket receive queue 或内核 UDP 缓冲区溢出，需要对照 `RcvbufErrors`、抓包计数和应用计数。

正确证据链至少包含：

```text
FPGA 已发送包数
→ 网卡接收包数/错误数
→ 内核 UDP 统计
→ socket 队列和丢包
→ 应用 recv 包数
→ 协议序号缺口
→ 业务队列消费数
```

综合项目会把真实单音 IQ 文件按包循环发送，并增加乱序、CRC、消费者积压和端到端延迟。
