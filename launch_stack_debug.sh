#!/bin/bash

# ========== CONFIG ==========
LM_MODEL="daring-mythalion-13b"
LM_PORT=41345

LM_CMD_PORT="--port $LM_PORT --model $LM_MODEL --headless"

# ========== HELPERS ==========

open_term () {
  gnome-terminal -- bash -c "$1; exec bash"
}

echo "🧠 Launching Full AI Stack..."

# ========== LM Studio ==========
echo "🧠 Launching LM Studio..."

APP=$(find ~/AI_Stack -type f -iname 'LMStudio*.AppImage' | head -n 1)

if [[ -x "$APP" ]]; then
  echo "✅ LM Studio found: $APP"
  "$APP" &
else
  echo "❌ LM Studio AppImage not found in ~/AI_Stack"
fi


# ========== Cloudflare Tunnel ==========
echo "🌐 Launching Cloudflare Tunnel..."

CF_DIR=~/AI_Stack/cloudflared
CF_BIN="$CF_DIR/cloudflared"
CF_CONFIG="$CF_DIR/config.yml"

if [[ -x "$CF_BIN" && -f "$CF_CONFIG" ]]; then
  open_term "cd \"$CF_DIR\" && \"$CF_BIN\" tunnel --config \"$CF_CONFIG\" run"
else
  echo "❌ Cloudflared binary or config.yml not found."
fi


# ========== OpenWebUI ==========
echo "🌐 Launching OpenWebUI..."
OPENWEBUI_DIR=~/AI_Stack/open-webui
OPENWEBUI_VENV=~/AI_Stack/venv_py311

if [ -d "$OPENWEBUI_DIR" ] && [ -f "$OPENWEBUI_VENV/bin/activate" ]; then
  open_term "cd \"$OPENWEBUI_DIR\" && source \"$OPENWEBUI_VENV/bin/activate\" && open-webui serve --host 127.0.0.1 --port 8082"
else
  echo "❌ OpenWebUI or its venv not found."
fi

# ========== SearXNG ==========
echo "🔎 Launching SearXNG..."

SEARXNG_DIR=~/AI_Stack/searxng
VENV_DIR="$SEARXNG_DIR/venv"

if [ -d "$SEARXNG_DIR" ] && [ -f "$VENV_DIR/bin/activate" ]; then
  open_term "
    cd \"$SEARXNG_DIR\" &&
    source \"$VENV_DIR/bin/activate\" &&
    export PYTHONPATH=. &&
    python3 -m searx.webapp
  "
else
  echo "❌ SearXNG directory or venv not found."
fi

# ========== Chatterbox TTS ==========
echo "🎤 Launching Chatterbox TTS..."

CHATTERBOX_DIR=~/AI_Stack/chatterbox
CHATTERBOX_VENV=~/AI_Stack/venv_py311

if [ -d "$CHATTERBOX_DIR" ] && [ -f "$CHATTERBOX_VENV/bin/activate" ]; then
  open_term "
    cd \"$CHATTERBOX_DIR\" &&
    source \"$CHATTERBOX_VENV/bin/activate\" &&
    uvicorn main:app --host 0.0.0.0 --port 4123
  "
else
  echo "❌ Chatterbox directory or venv not found."
fi

# ========== A1111 ==========
echo "🛑 Killing any running A1111 instances..."
pkill -f "launch.py"

# Wait a moment to ensure clean kill
sleep 2

# Navigate to the project root
cd "$(dirname "$0")"

# Activate portable venv
source venv_linux/bin/activate

# Check for CUDA GPU
CUDA_AVAILABLE=$(python -c "import torch; print(torch.cuda.is_available())")

if [ "$CUDA_AVAILABLE" != "True" ]; then
  echo "❌ CUDA not available. Aborting launch."
  echo "Make sure your NVIDIA drivers and CUDA runtime are correctly installed."
  deactivate
  exit 1
fi

# Optional: Show GPU name
echo -n "✅ CUDA GPU detected: "
python -c "import torch; print(torch.cuda.get_device_name(0))"

# Launch A1111 with xFormers and API enabled, terminal stays open
cd A1111
echo "🚀 Launching A1111..."
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
exec python launch.py --xformers --api --skip-torch-cuda-test
