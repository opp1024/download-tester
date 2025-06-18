 #!/bin/sh
count="$1"
[ -z "$count" ] && count=20

echo "--- 脚本将执行 $count 轮数据下载 ---"

URLS="\
https://p16-oec-ttp.tiktokcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p19-oec-ttp.tiktokcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p16-oec-ttp-useast5.ttcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg \
https://p19-oec-ttp-useast5.ttcdn-us.com/tos-useast5-i-omjb5zjo8w-tx/b1c62d6406395542c4d5dc9601347199.JPG~tplv-omjb5zjo8w-origin-jpeg.jpeg"

logdir=$(mktemp -d)
trap "rm -rf $logdir" EXIT

i=1
while [ "$i" -le "$count" ]; do
  echo "============= 第 $i 轮下载 ============="

  for url in $URLS; do
    echo "下载中: $url"
    result=$(curl -m 30 -s -o /dev/null -D ./tmp_header -L "$url" \
      -w "%{speed_download} %{time_total}")
    code=$?
    echo "URL: $url"

    if [ "$code" = 0 ]; then
      speed=$(printf "%s" "$result" | awk '{print $1}')
      ttime=$(printf "%s" "$result" | awk '{print $2}')
      echo "✅ 成功 下载时间: $ttime 秒, 速度: $speed bytes/s"

      key=$(printf "%s" "$url" | sed 's/[^a-zA-Z0-9]/_/g')
      printf "%s %s\n" "$speed" "$ttime" >> "$logdir/$key.log"
    else
      echo "❌ 下载失败 (curl code $code)"
    fi

    echo "----------------------------------------"
  done
  i=$((i + 1))
done

echo "\n============= 每个 URL 平均统计 ============="
total_ok=0
url_count=0

for url in $URLS; do
  key=$(printf "%s" "$url" | sed 's/[^a-zA-Z0-9]/_/g')
  logfile="$logdir/$key.log"

  if [ -s "$logfile" ]; then
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

    total_ok=$((total_ok + ok_count))
    url_count=$((url_count + 1))
  else
    echo "⚠️  URL: $url 未成功下载，跳过"
    echo "----------------------------------------"
  fi
done

