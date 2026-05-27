# start.ps1 — launch backend + frontend on Windows
# Usage: .\start.ps1

Write-Host "──────────────────────────────────────────" -ForegroundColor Cyan
Write-Host " PDF Chatbot — startup" -ForegroundColor Cyan
Write-Host "──────────────────────────────────────────" -ForegroundColor Cyan

# Create required dirs
New-Item -ItemType Directory -Force -Path uploads, vector_store, logs | Out-Null

# Start FastAPI backend in a new window
Write-Host "[1/2] Starting FastAPI backend on http://localhost:8000 ..."
Start-Process powershell -ArgumentList `
    "-NoExit", "-Command", `
    "uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload"

Start-Sleep -Seconds 2

# Start Streamlit frontend in a new window
Write-Host "[2/2] Starting Streamlit frontend on http://localhost:8501 ..."
Start-Process powershell -ArgumentList `
    "-NoExit", "-Command", `
    "streamlit run frontend/app.py --server.port 8501 --server.address 0.0.0.0"

Write-Host ""
Write-Host "✅ Both services started in separate windows." -ForegroundColor Green
Write-Host "   Backend  → http://localhost:8000/docs"
Write-Host "   Frontend → http://localhost:8501"
