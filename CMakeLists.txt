# 指定运行本项目所需的最低 CMake 版本。
# 版本过低时，CMake 会停止并给出明确错误。
cmake_minimum_required(VERSION 3.20)

# 定义项目名称、版本，以及本项目使用的编程语言。
# LANGUAGES CXX 表示只启用 C++，暂时不检测 C 编译器。
project(
    LinuxTroubleshootLearn
    VERSION 0.1.0
    LANGUAGES CXX
)

# 从 main.cpp 创建名为 baseline_pipeline 的可执行程序。
# 第一个参数是目标名称，后面的参数是组成该目标的源文件。
add_executable(
    baseline_pipeline
    demos/00_baseline_pipeline/main.cpp
)

# 要求 baseline_pipeline 使用至少 C++17 标准。
# PRIVATE 表示这个要求只作用于当前目标，不传播给其他目标。
target_compile_features(
    baseline_pipeline
    PRIVATE
    cxx_std_17
)

# 为这个目标开启常用编译警告。
# 这些参数会传递给 GCC 或 Clang。
target_compile_options(
    baseline_pipeline
    PRIVATE
    -Wall
    -Wextra
    -Wpedantic
)
