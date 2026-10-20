# 05 Valgrind、Massif 与 Heaptrack

## 本章目标

理解“泄漏”“仍可达”“内存峰值”是不同问题，并选择合适工具。

## Memcheck

```bash
cmake --build --preset x86-debug --target heap_lab

valgrind --leak-check=full --show-leak-kinds=all \
  --track-origins=yes --num-callers=30 \
  ./build/x86-debug/demos/05_heap_lab/heap_lab \
  --mode leak --iterations 10
```

报告分类：

- `definitely lost`：已经找不到指针，确定泄漏。
- `indirectly lost`：由已泄漏对象间接持有。
- `possibly lost`：只剩内部地址等可疑指针。
- `still reachable`：退出时仍有有效引用，不一定是错误。

## Massif

```bash
valgrind --tool=massif --stacks=yes \
  ./build/x86-debug/demos/05_heap_lab/heap_lab \
  --mode peak --iterations 5
ms_print massif.out.* | less
```

## Heaptrack

```bash
heaptrack ./build/x86-debug/demos/05_heap_lab/heap_lab \
  --mode reachable --iterations 20
heaptrack_print heaptrack.*.gz | less
```

## 学员任务

比较 `leak`、`reachable`、`peak`、`fixed`：

1. 哪个存在 `definitely lost`？
2. 哪个退出时仍持有内存但不丢失指针？
3. 哪个没有泄漏但峰值很高？

## 实战答案

- `leak` 每轮丢失 256 KiB。
- `reachable` 由全局缓存持有，属于仍可达；业务上是否合理取决于缓存上限。
- `peak` 每轮临时申请 32 MiB，退出前释放，但会制造内存峰值。
- `fixed` 使用 RAII，生命周期明确。

Valgrind 很慢，适合小规模确定性复现。长时间吞吐场景优先使用 ASan、Heaptrack 或采样型工具，再用 Valgrind 缩小后的场景复核。
