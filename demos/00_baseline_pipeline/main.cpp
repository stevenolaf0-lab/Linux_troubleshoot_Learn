#include <charconv>   // 提供 std::from_chars，用于把字符串转换成整数。
#include <chrono>     // 提供时间长度类型。
#include <iostream>   // 提供 std::cout 和 std::cerr。
#include <string_view>  // 提供只读字符串视图 std::string_view。
#include <system_error> // 提供 std::errc 错误码。
#include <thread>     // 提供 std::this_thread::sleep_for。
#include <unistd.h>   // Linux 头文件，提供 getpid()。

namespace {

// 输出程序的正确使用方式。
// program_name 通常是 argv[0]，即用户启动程序时使用的路径。
void print_usage(const char* program_name) {
    std::cerr << "Usage: " << program_name
              << " [--duration SECONDS]\n";
}

// 将字符串解析成大于 0 的整数。
// value 使用引用传出解析结果；返回值表示解析是否成功。
bool parse_positive_integer(std::string_view text, int& value) {
    const char* begin = text.data();
    const char* end = begin + text.size();

    // from_chars 尝试解析 [begin, end) 范围中的字符。
    // ptr 指向停止解析的位置，error 保存错误状态。
    const auto [ptr, error] = std::from_chars(begin, end, value);

    // 必须同时满足：
    // 1. 没有转换错误；
    // 2. 所有字符都被成功解析；
    // 3. 结果大于 0。
    return error == std::errc{} && ptr == end && value > 0;
}

}  // namespace

int main(int argc, char* argv[]) {
    using namespace std::chrono_literals;

    // 不提供参数时，默认运行 10 秒。
    int duration_seconds = 10;

    // 正确的带参数形式应有三个命令行元素：
    // argv[0]：程序路径
    // argv[1]：--duration
    // argv[2]：秒数
    if (argc == 3 && std::string_view{argv[1]} == "--duration") {
        if (!parse_positive_integer(argv[2], duration_seconds)) {
            std::cerr << "Error: SECONDS must be a positive integer.\n";
            print_usage(argv[0]);
            return 2;
        }
    } else if (argc != 1) {
        // argc == 1 表示没有额外参数，可以使用默认值。
        // 其他不符合预期的参数组合都视为使用错误。
        std::cerr << "Error: invalid command-line arguments.\n";
        print_usage(argv[0]);
        return 2;
    }

    std::cout << "baseline_pipeline started"
              << " pid=" << ::getpid()
              << " duration_seconds=" << duration_seconds
              << '\n';

    for (int second = 1; second <= duration_seconds; ++second) {
        std::this_thread::sleep_for(1s);
        std::cout << "heartbeat second=" << second << '\n';
    }

    std::cout << "baseline_pipeline finished\n";
    return 0;
}
