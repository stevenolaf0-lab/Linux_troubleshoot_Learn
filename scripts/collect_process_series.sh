#!/usr/bin/env bash

# 开启 Bash 严格模式。
set -euo pipefail

# 使用稳定的英文数字格式，避免小数点受本地语言环境影响。
export LC_ALL=C

print_usage() {
    printf 'Usage: %s PID [INTERVAL_SECONDS] [SAMPLE_COUNT]\n' "$0" >&2
}

# 判断参数是否为大于 0 的整数。
is_positive_integer() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

# 脚本最少接收一个参数，最多接收三个参数。
if [[ $# -lt 1 || $# -gt 3 ]]; then
    print_usage
    exit 2
fi

pid="$1"

# ${变量:-默认值} 表示变量不存在或为空时使用默认值。
interval_seconds="${2:-1}"
sample_count="${3:-10}"

if ! is_positive_integer "$pid"; then
    printf 'Error: PID must be a positive integer: %s\n' "$pid" >&2
    exit 2
fi

if ! is_positive_integer "$interval_seconds"; then
    printf 'Error: interval must be a positive integer: %s\n' \
        "$interval_seconds" >&2
    exit 2
fi

if ! is_positive_integer "$sample_count"; then
    printf 'Error: sample count must be a positive integer: %s\n' \
        "$sample_count" >&2
    exit 2
fi

proc_dir="/proc/$pid"

if [[ ! -d "$proc_dir" ]]; then
    printf 'Error: process %s does not exist.\n' "$pid" >&2
    exit 1
fi

timestamp_file="$(date +%Y%m%d_%H%M%S)"
output_dir="evidence/runtime"
output_file="$output_dir/process_series_${pid}_${timestamp_file}.csv"

mkdir -p "$output_dir"

# CSV 第一行是字段名称。
printf '%s\n' \
    'sample,timestamp,pid,cpu_percent,rss_kb,vsz_kb,threads,state,voluntary_ctxt_switches,nonvoluntary_ctxt_switches' \
    | tee "$output_file"

# 使用算术 for 循环执行指定次数的采样。
for ((sample = 1; sample <= sample_count; ++sample)); do
    # 采样期间进程可能退出，因此每轮都重新检查。
    if [[ ! -r "$proc_dir/status" ]]; then
        printf 'Process %s exited before sample %s.\n' \
            "$pid" "$sample" >&2
        break
    fi

    timestamp_iso="$(date --iso-8601=seconds)"

    # 从 ps 的一行输出中依次读取五个字段。
    read -r cpu_percent rss_kb vsz_kb threads state < <(
        ps -p "$pid" -o pcpu=,rss=,vsz=,nlwp=,stat=
    )

    # 从 /proc/PID/status 中提取上下文切换累计值。
    voluntary_switches="$(
        awk '/^voluntary_ctxt_switches:/ {print $2}' "$proc_dir/status"
    )"

    nonvoluntary_switches="$(
        awk '/^nonvoluntary_ctxt_switches:/ {print $2}' "$proc_dir/status"
    )"

    # tee -a 表示在文件末尾追加，而不是覆盖已有内容。
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$sample" \
        "$timestamp_iso" \
        "$pid" \
        "$cpu_percent" \
        "$rss_kb" \
        "$vsz_kb" \
        "$threads" \
        "$state" \
        "$voluntary_switches" \
        "$nonvoluntary_switches" \
        | tee -a "$output_file"

    # 最后一次采样后不再额外等待。
    if ((sample < sample_count)); then
        sleep "$interval_seconds"
    fi
done

printf 'Series saved to: %s\n' "$output_file" >&2
