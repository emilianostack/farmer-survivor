#!/bin/bash
# Bot playthroughs across stages and upgrade levels: tools/balance.sh "<godot>" stage:rad:char:meta ...
G="$1"; shift
for spec in "$@"; do
  IFS=: read -r st rad ch meta <<<"$spec"
  ( out=$(timeout 280 "$G" --headless --path . --fixed-fps 60 -- --dev=sim:$st:$rad:$ch:1:$meta 2>&1)
    echo "== $spec :: $(echo "$out" | grep -E '^t=' | tail -1 | cut -c1-120)"
    echo "$out" | grep -E 'SCRIPT ERROR|Invalid' | sort | uniq -c | head -5
    echo "$out" | grep RESULT | sed -E 's/.*"coins":([0-9.]+).*"kills":([0-9]+),"level":([0-9]+).*"time":([0-9.]+),"win":(true|false).*/   coins=\1 kills=\2 lvl=\3 time=\4 win=\5/' ) &
done
wait
