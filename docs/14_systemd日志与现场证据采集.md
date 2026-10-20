# 14 systemd、日志与现场证据采集

## 本章目标

排查只在后台服务中发生的崩溃、重启循环、挂死和日志缺失。

## Demo

```bash
cmake --build --preset x86-debug --target device_service
BIN=$(realpath build/x86-debug/demos/14_device_service/device_service)
$BIN --mode normal
$BIN --mode crash
$BIN --mode hang
```

服务文件模板位于：

```text
demos/14_device_service/device-service.service.in
```

把 `@BINARY@` 替换为绝对路径后，复制到测试系统的 `/etc/systemd/system/device-service.service`。

```bash
sudo systemctl daemon-reload
sudo systemctl start device-service
systemctl status device-service
journalctl -u device-service -f -o short-precise
```

## 崩溃与重启

```bash
systemctl show device-service \
  -p MainPID -p ExecMainCode -p ExecMainStatus -p NRestarts
coredumpctl list device_service
coredumpctl info device_service
```

## 挂死

```bash
PID=$(systemctl show -p MainPID --value device-service)
ps -L -p "$PID" -o tid,comm,stat,wchan:24
gdb -q -batch -ex 'thread apply all bt' -p "$PID"
```

## 学员任务

解释退出码、信号、自动重启次数和最后一条心跳日志之间的关系；为 hang 模式设计外部 watchdog，但不要通过无限重启掩盖根因。

## 生产建议

- 日志包含版本、配置摘要、时间戳、线程和状态转换。
- 设置合理的 `Restart=` 和启动频率限制。
- 开启 core，并限制磁盘占用和保留周期。
- watchdog 监控“业务进展”，不只是进程是否存在。
- 证据采集脚本避免输出口令、令牌和完整用户数据。
