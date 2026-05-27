# ─────────────────────────────────────────────
#  PDF Chatbot — Dockerfile (multi-stage)
# ─────────────────────────────────────────────
FROM python:3.11-slim AS base

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ── Install Python dependencies ───────────────────────────────────────────────
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Copy source ───────────────────────────────────────────────────────────────
COPY . .

# ── Create runtime directories ────────────────────────────────────────────────
RUN mkdir -p uploads vector_store logs

# ── Expose ports ──────────────────────────────────────────────────────────────
EXPOSE 8000 8501

# Default: run backend (override for frontend)
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
