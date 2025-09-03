#!/bin/bash
echo "🧨 Killing all AI stack services..."

# ==== Kill LM Studio ====
echo "🛑 Killing LM Studio..."

# Find LM Studio main AppImage process
PIDS=$(ps aux | grep '[L]MStudio.*AppImage' | awk '{print $2}')
if [[ -n "$PIDS" ]]; then
  echo "Found LM Studio PIDs: $PIDS"
  kill $PIDS

  sleep 1

  # Check for lingering GPU processes (Electron/Chromium etc.)
  GPU_HOGS=$(nvidia-smi | grep -E 'python|LMStudio|electron|chrome' | awk '{print $5}' | sort -u)
  if [[ -n "$GPU_HOGS" ]]; then
    echo "⚠️ GPU-locked PIDs: $GPU_HOGS"
    for PID in $GPU_HOGS; do
      if kill -0 "$PID" 2>/dev/null; then
        kill -9 "$PID"
      fi
    done
  else
    echo "✅ No lingering GPU processes."
  fi
else
  echo "🔸 LM Studio not running"
fi

# Kill OpenWebUI (Python-based)
pkill -f "open-webui serve" || echo "🔸 OpenWebUI not running"

# Kill SearXNG (Python-based)
pkill -f "searx.webapp" || echo "🔸 SearXNG not running"

# Kill A1111
pkill -f "launch.py" || echo "🔸 A1111 not running"

echo "✅ All components stopped."

