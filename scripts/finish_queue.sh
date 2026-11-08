#!/bin/bash
# waits for queue_full_gpu.sh to finish, then summarizes screening + steering results, commits and pushes.
cd /data/behavioral-lens-fast
while pgrep -f "^bash scripts/queue_full_gpu.sh" > /dev/null; do sleep 120; done
echo "[finish] queue ended $(date -u)"
conda run -n vllm python scripts/summarize_screen.py > results/01_behaviour/screen/table.md 2>/dev/null
[ -f results/02_loops/steering/steer/summary.jsonl ] && cp results/02_loops/steering/steer/summary.jsonl results/01_behaviour/screen/steer_summary.jsonl
grep -E "^\[queue\]" results/logs/queue_full_gpu.log > results/01_behaviour/screen/queue_timeline.txt
git add results/01_behaviour/screen/table.md results/01_behaviour/screen/table.json results/01_behaviour/screen/summary.jsonl results/01_behaviour/screen/queue_timeline.txt results/01_behaviour/screen/steer_summary.jsonl 2>/dev/null
git commit -q -m "xuanqi: overnight screening results (auto-committed at queue end)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" && git push -q mine xuanqi
echo "[finish] pushed $(date -u)"
