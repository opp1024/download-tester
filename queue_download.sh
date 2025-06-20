#!/bin/sh

# 获取第一个参数，作为循环次数
count="$1"

# 如果未传参数，默认执行 5 次
if [ -z "$count" ]; then
  count=20
fi

echo "--- 脚本将执行 $count 轮数据下载 ---"

# 用空格分隔的 URL 字符串
URLS="\
https://p16-oec-va.ibyteimg.com/tos-maliva-i-o3syd03w52-us/94b919c403c8eec72bafcfeef82cb9f4.JPG~tplv-o3syd03w52-origin-jpeg.jpeg \
https://p19-oec-va.ibyteimg.com/tos-maliva-i-o3syd03w52-us/94b919c403c8eec72bafcfeef82cb9f4.JPG~tplv-o3syd03w52-origin-jpeg.jpeg" 

# 初始化临时目录收集统计信息
tmpdir="./download_stats"
mkdir -p "$tmpdir"
rm -f "$tmpdir"/*.log

i=1
while [ "$i" -le "$count" ]; do
  echo "============= 第 $i 轮下载 ============="

  for url in $URLS; do
    echo "下载中: $url"

    curl -m 30 -s -o ./tmp_output -D ./tmp_header -L "$url" \
      -w "平均速度: %{speed_download} bytes/s\n下载时间: %{time_total} 秒\n" > ./curl_output.log

    code=$?

    echo "URL: $url"

    if [ "$code" = "0" ]; then
      status=$(grep -i "^HTTP/" ./tmp_header | tail -1 | awk '{print $2}')
      echo "状态码: $status"
      cat ./curl_output.log

      st=$(grep -i "server-timing:" ./tmp_header)
      if [ -n "$st" ]; then
        echo "Server-Timing: $st"
      else
        echo "Server-Timing: (无)"
      fi

      speed=$(grep "平均速度:" ./curl_output.log | awk '{print $2}')
      time=$(grep "下载时间:" ./curl_output.log | awk '{print $2}')
      key=$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g')
      echo "$speed $time" >> "$tmpdir/$key.log"
    else
      if [ "$code" = "28" ]; then
        echo "❌ 下载失败：超时"
      else
        echo "❌ 下载失败，curl 返回码: $code"
      fi
    fi

    echo "----------------------------------------"
  done

  i=$((i + 1))
done

# 额外统计：每个 URL 成功次数与平均速度/时间

echo "\n============= 每个 URL 平均统计 ============="
for url in $URLS; do
  key=$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g')
  logfile="$tmpdir/$key.log"

  if [ -f "$logfile" ]; then
    ok_count=$(wc -l < "$logfile")
    total_speed=$(awk '{s+=$1} END{print s}' "$logfile")
    total_time=$(awk '{t+=$2} END{print t}' "$logfile")

    avg_speed=$(awk "BEGIN {printf \"%.2f\", $total_speed/$ok_count/1024/1024}")
    avg_time=$(awk "BEGIN {printf \"%.3f\", $total_time/$ok_count}")

    echo "📦 URL: $url"
    echo "✅ 成功下载 $ok_count 次"
    echo "⏱ 平均耗时: ${avg_time} 秒"
    echo "🚀 平均速度: ${avg_speed} MB/s"
    echo "----------------------------------------"
  else
    echo "⚠️  URL: $url"
    echo "未成功下载，跳过统计"
    echo "----------------------------------------"
  fi
  
done
