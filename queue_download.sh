 #!/bin/sh

# 获取第一个参数，作为循环次数
count="$1"

# 如果未传参数，默认执行 20 次
if [ -z "$count" ]; then
  count=20
fi

echo "--- 脚本将执行 $count 轮数据下载 ---"

# 用空格分隔的 URL 字符串
URLS="\
https://p16-oec-ttp.tiktokcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p19-oec-ttp.tiktokcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p16-oec-ttp-useast5.ttcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p19-oec-ttp-useast5.ttcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg"

# 初始化統計變數（兼容 POSIX shell）
declare_all_vars() {
  for url in $URLS; do
    key=$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g')
    eval time_total_$key=0
    eval speed_total_$key=0
    eval count_ok_$key=0
  done
}

declare_all_vars

i=1
while [ "$i" -le "$count" ]; do
  echo "============= 第 $i 轮下载 ============="

  for url in $URLS; do
    echo "下载中: $url"
    result=$(curl -m 30 -s -o ./tmp_output -D ./tmp_header -L "$url" -w "%{speed_download} %{time_total}")
    code=$?
    echo "URL: $url"

    if [ "$code" = "0" ]; then
      speed=$(echo "$result" | awk '{print $1}')
      time=$(echo "$result" | awk '{print $2}')
      status=$(grep -i "^HTTP/" ./tmp_header | tail -1 | awk '{print $2}')
      echo "状态码: $status"
      echo "平均速度: $speed bytes/s"
      echo "下载时间: $time 秒"

      key=$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g')
      eval current_time=\$time_total_$key
      eval current_speed=\$speed_total_$key
      eval current_count=\$count_ok_$key

      total_time=$(awk "BEGIN {print $current_time + $time}")
      total_speed=$(awk "BEGIN {print $current_speed + $speed}")
      total_count=$(($current_count + 1))

      eval time_total_$key=$total_time
      eval speed_total_$key=$total_speed
      eval count_ok_$key=$total_count

      st=$(grep -i "server-timing:" ./tmp_header)
      if [ -n "$st" ]; then
        echo "Server-Timing: $st"
      else
        echo "Server-Timing: (无)"
      fi
    else
      if [ "$code" = "28" ]; then
        echo "❌ 下载失败：超时"
      else
        echo "❌ 下载失败，curl 返回码: $code"
      fi
    fi

    echo "----------------------------------------"
  done

  i=$(($i + 1))
done

# 統計輸出
echo "\n============= 每个 URL 平均统计 ============="
total_ok=0
url_count=0

for url in $URLS; do
  key=$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g')
  eval sum_time=\$time_total_$key
  eval sum_speed=\$speed_total_$key
  eval ok_count=\$count_ok_$key

  total_ok=$(($total_ok + $ok_count))
  url_count=$(($url_count + 1))

  if [ "$ok_count" -gt 0 ]; then
    avg_time=$(awk "BEGIN {printf \"%.3f\", $sum_time / $ok_count}")
    avg_speed=$(awk "BEGIN {printf \"%.2f\", $sum_speed / $ok_count / 1024 / 1024}")
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
