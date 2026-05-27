#!/usr/bin/env bash
# start.sh — launch backend + frontend in two terminals (Unix/macOS/WSL)
# Usage: bash start.sh

set -e

echo "──────────────────────────────────────────"
echo " PDF Chatbot — startup"
echo "──────────────────────────────────────────"

# Activate venv if present
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
elif [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
fi

# Create required dirs
mkdir -p uploads vector_store logs

# Start FastAPI backend in background
echo "[1/2] Starting FastAPI backend on http://localhost:8000 ..."
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

sleep 2

# Start Streamlit frontend in background
echo "[2/2] Starting Streamlit frontend on http://localhost:8501 ..."
streamlit run frontend/app.py --server.port 8501 --server.address 0.0.0.0 &
FRONTEND_PID=$!

echo ""
echo "✅ Both services running."
echo "   Backend  → http://localhost:8000/docs"
echo "   Frontend → http://localhost:8501"
echo ""
echo "Press Ctrl+C to stop."

# Wait and clean up
trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null" EXIT
wait
