# 06 动态库、ELF、符号与 ABI

## 本章目标

定位“开发机能运行、设备上启动失败”“库明明存在却找不到符号”等部署问题。

## 核心命令

```bash
file APP LIB.so
readelf -h APP
readelf -d APP
readelf -Ws LIB.so | less
nm -D --defined-only LIB.so
objdump -p APP | grep NEEDED
ldd APP
ldconfig -p | grep NAME
```

禁止对不可信二进制直接使用 `ldd`；可用 `readelf -d` 静态检查依赖。

## Demo

```bash
cmake --build --preset x86-debug --target \
  plugin_loader signal_plugin_good signal_plugin_bad

DIR=build/x86-debug/demos/06_plugin_loader
$DIR/plugin_loader $DIR/libsignal_plugin_good.so
$DIR/plugin_loader $DIR/libsignal_plugin_bad.so
$DIR/plugin_loader $DIR/not-exist.so
```

查看符号：

```bash
nm -D "$DIR/libsignal_plugin_good.so" | grep analyze_power
nm -D "$DIR/libsignal_plugin_bad.so" | grep analyze_power
LD_DEBUG=libs,symbols "$DIR/plugin_loader" \
  "$DIR/libsignal_plugin_bad.so" 2>ld-debug.log
```

## 学员任务

解释缺失文件和缺失符号为何属于两类错误，并找出坏插件实际导出的替代符号。

## 实战答案

- 文件不存在时 `dlopen` 失败，先检查路径、RPATH/RUNPATH 和依赖库。
- 坏插件可以成功加载，但没有加载器需要的 `analyze_power`，因此 `dlsym` 失败。
- 它只导出了不兼容的 `analyze_power_v2`。

生产插件应暴露稳定的 C ABI、版本查询和能力协商，不能只依赖 C++ 符号名。

## ARM64 检查

```bash
file libxxx.so
readelf -h libxxx.so | grep Machine
```

ARM64 应显示 `AArch64`。最常见部署错误之一是应用为 ARM64、某个私有 so 却是 x86-64。
