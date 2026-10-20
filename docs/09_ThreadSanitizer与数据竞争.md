# 09 ThreadSanitizer 与数据竞争

## 本章目标

定位不一定导致崩溃、但会产生偶发错误的数据竞争。

## 构建

```bash
cmake --preset x86-tsan
cmake --build --preset x86-tsan --target race_queue
BIN=./build/x86-tsan/demos/09_race_queue/race_queue
```

## 实验

```bash
$BIN --mode stop-flag
$BIN --mode vector
$BIN --mode fixed
```

在部分 WSL2 环境中，TSan 启动时可能报告 `unexpected memory mapping`。可以只对当前实验进程关闭地址随机化后重试，不修改系统全局配置：

```bash
setarch "$(uname -m)" -R "$BIN" --mode vector
```

该命令只用于本地 TSan 实验；真实 ARM64 环境仍需单独验证。

## 阅读 TSan 报告

重点找：

1. `WARNING: ThreadSanitizer: data race`。
2. 当前读或写的源码栈。
3. 与它冲突的前一次写入栈。
4. 两个线程的创建位置。
5. 涉及的内存地址或全局变量。

## 学员任务

解释为什么 `volatile bool` 也不能修复停止标志，以及为什么给 `vector::push_back` 前的元素赋值加锁仍不够。

## 实战答案

- 普通 `bool` 被一个线程写、另一个线程读，没有 happens-before 关系。
- `std::vector` 的扩容和内部大小修改不能由多个线程并发执行。
- 修复模式使用 `std::atomic<bool>` 管理停止状态，并用互斥锁保护容器。

`volatile` 只限制某些编译器优化，不提供原子性、互斥或线程间内存顺序。

## ARM64 提醒

ARM 内存模型比 x86 更弱，错误同步更容易暴露。TSan 应先在 x86 压测，再在原生 ARM64 构建验证；不要用 QEMU 下的偶然成功代替正确同步。
