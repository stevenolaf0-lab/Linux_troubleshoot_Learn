# 04 AddressSanitizer、UBSan 与 LeakSanitizer

## 本章目标

在可控测试环境中快速定位越界、释放后使用、重复释放、未定义行为和泄漏。

## 构建

```bash
cmake --preset x86-asan
cmake --build --preset x86-asan --target sanitizer_lab
```

建议保留：

```text
-g -O1 -fno-omit-frame-pointer -fsanitize=address,undefined
```

## 运行实验

```bash
BIN=./build/x86-asan/demos/04_sanitizer_lab/sanitizer_lab
$BIN --fault oob
$BIN --fault uaf
$BIN --fault double-free
$BIN --fault overflow
$BIN --fault leak
```

常用环境变量：

```bash
ASAN_OPTIONS=abort_on_error=1:detect_leaks=1:strict_string_checks=1
UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1
```

## 如何阅读报告

按以下顺序阅读：

1. 错误类型，例如 `heap-buffer-overflow`。
2. 第一次非法读写的位置。
3. 内存最初分配的位置。
4. 如果是 UAF，再找释放位置。
5. 访问大小、线程号和目标地址。

## 学员任务

对五种故障分别记录：错误类型、首次业务源码行、分配栈、释放栈和退出码。

## 实战答案

- `oob`：在 8 元素数组上写入下标 8。
- `uaf`：`delete` 后解引用原指针。
- `double-free`：同一地址释放两次。
- `overflow`：有符号整数超过 `INT_MAX`，由 UBSan 报告。
- `leak`：分配的数组退出前未释放，由 LeakSanitizer 报告。

## 局限

- Sanitizer 会显著增加内存和运行时间。
- 不建议直接用于资源紧张的生产设备。
- ASan 与 TSan 不应放在同一次构建中。
- 自定义分配器和部分第三方库可能需要抑制规则。
- QEMU 下可做功能验证，但优先在 x86 和真实 ARM 分别运行。
