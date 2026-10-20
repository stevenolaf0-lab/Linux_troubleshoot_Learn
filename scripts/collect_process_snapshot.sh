#!/usr/bin/env bash

# 遇到未处理的错误、未定义变量或管道错误时，让脚本尽早失败。
set -euo pipefail

# 输出脚本的正确使用方式。
print_usage() {
    printf 'Usage: %s PID\n' "$0" >&2
}

# $# 表示用户传给脚本的参数数量。
# 本脚本只接受一个参数，因此参数数量必须等于 1。
if [[ $# -ne 1 ]]; then
    print_usage
    exit 2
fi

# $1 表示用户传入的第一个参数。
pid="$1"

# PID 必须完全由数字组成。
if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
    printf 'Error: PID must contain digits only: %s\n' "$pid" >&2
    print_usage
    exit 2
fi

# Linux 会为每个正在运行的进程创建 /proc/PID 目录。
proc_dir="/proc/$pid"

# 如果目录不存在，说明进程不存在或已经退出。
if [[ ! -d "$proc_dir" ]]; then
    printf 'Error: process %s does not exist.\n' "$pid" >&2
    exit 1
fi

# 一个时间戳用于报告正文，另一个用于安全的文件名。
timestamp_iso="$(date --iso-8601=seconds)"
timestamp_file="$(date +%Y%m%d_%H%M%S)"

# 所有运行时证据统一保存到这个目录。
output_dir="evidence/runtime"
mkdir -p "$output_dir"

# 文件名同时包含 PID 和采集时间，避免多次运行互相覆盖。
output_file="$output_dir/process_${pid}_${timestamp_file}.txt"

# 花括号把多条命令组合成一个输出流。
# tee 将输出同时显示在终端并写入证据文件。
{
    printf '[metadata]\n'
    printf 'collected_at=%s\n' "$timestamp_iso"
    printf 'hostname=%s\n' "$(hostname)"
    printf 'pid=%s\n' "$pid"

    printf 'kernel='
    uname -a

    printf '\n[process]\n'
    ps -ww -p "$pid" \
        -o pid,ppid,stat,pcpu,pmem,rss,vsz,nlwp,etime,comm,args

    printf '\n[proc_status]\n'
    grep -E \
        '^(Name|State|Pid|PPid|Threads|VmSize|VmRSS|voluntary_ctxt_switches|nonvoluntary_ctxt_switches):' \
        "$proc_dir/status"

    printf '\n[executable]\n'
    readlink -f "$proc_dir/exe"

    printf '\n[command_line]\n'
    tr '\0' ' ' < "$proc_dir/cmdline"
    printf '\n'

    printf '\n[threads]\n'
    ps -L -p "$pid" \
        -o pid,tid,nlwp,stat,pcpu,comm
} | tee "$output_file"

# >&2 将这条提示写到标准错误，避免它混入上面的采集数据。
printf 'Snapshot saved to: %s\n' "$output_file" >&2
