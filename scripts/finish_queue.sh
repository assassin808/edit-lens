#!/bin/bash
# waits for queue_full_gpu.sh to finish, then summarizes screening + steering results, commits and pushes.
cd /data/behavioral-lens-fast
while pgrep -f "^bash scripts/queue_full_gpu.sh" > /dev/null; do sleep 120; done
echo "[finish] queue ended $(date -u)"
conda run -n vllm python scripts/summarize_screen.py > notes/screen/table.md 2>/dev/null
[ -f notes/steer/summary.jsonl ] && cp notes/steer/summary.jsonl notes/screen/steer_summary.jsonl
grep -E "^\[queue\]" notes/queue_full_gpu.log > notes/screen/queue_timeline.txt
git add notes/screen/table.md notes/screen/table.json notes/screen/summary.jsonl notes/screen/queue_timeline.txt notes/screen/steer_summary.jsonl 2>/dev/null
git commit -q -m "xuanqi: overnight screening results (auto-committed at queue end)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" && git push -q mine xuanqi
echo "[finish] pushed $(date -u)"
