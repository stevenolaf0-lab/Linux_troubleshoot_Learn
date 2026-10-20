#include <chrono>    // 提供时间长度类型，例如 std::chrono::seconds。
#include <iostream>  // 提供标准输出对象 std::cout。
#include <thread>    // 提供 std::this_thread::sleep_for。
#include <unistd.h>  // Linux 头文件，提供 getpid()。

int main() {
    // chrono_literals 允许使用 1s 这种时间字面量。
    using namespace std::chrono_literals;

    // getpid() 返回当前进程的 PID，便于使用 ps、top 和 strace 观察程序。
    std::cout << "baseline_pipeline started, pid=" << ::getpid() << '\n';

    // 每秒输出一次心跳，连续运行十秒。
    // 这样后续可以在另一个终端中观察该进程。
    for (int second = 1; second <= 10; ++second) {
        std::this_thread::sleep_for(1s);
        std::cout << "heartbeat second=" << second << '\n';
    }

    std::cout << "baseline_pipeline finished" << '\n';

    // 返回 0 表示程序正常结束。
    return 0;
}
