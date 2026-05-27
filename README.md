# 📄 PDF Chatbot

A production-ready RAG (Retrieval-Augmented Generation) application that lets you upload any PDF and have a full conversation with it — powered by **LangChain**, **LangGraph**, **OpenAI**, **FAISS**, **FastAPI**, and **Streamlit**.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      USER BROWSER                       │
│               Streamlit UI  (port 8501)                 │
└───────────────────────┬─────────────────────────────────┘
                        │  HTTP (REST)
┌───────────────────────▼─────────────────────────────────┐
│               FastAPI Backend  (port 8000)              │
│  POST /api/v1/upload       POST /api/v1/ask             │
└──────────┬─────────────────────────┬────────────────────┘
           │                         │
  ┌────────▼──────────┐    ┌─────────▼──────────┐
  │  IngestionGraph   │    │     QAGraph         │
  │  (LangGraph)      │    │  (LangGraph)        │
  │                   │    │                     │
  │ load_and_split    │    │ retrieve_and_       │
  │ embed_and_store   │    │ generate            │
  └────────┬──────────┘    └─────────┬──────────┘
           │                         │
  ┌────────▼─────────────────────────▼──────────┐
  │         FAISS Vector Store (local disk)     │
  │   text-embedding-3-small  (OpenAI)          │
  └─────────────────────────────────────────────┘
                        │
  ┌─────────────────────▼───────────────────────┐
  │         ChatOpenAI  gpt-4o-mini             │
  │   ConversationalRetrievalChain              │
  │   + ConversationBufferMemory                │
  └─────────────────────────────────────────────┘
```

### Flow Summary
1. **Upload** — PDF is saved, loaded page-by-page, split into overlapping chunks, embedded, and stored in FAISS.
2. **Ask** — Question + chat history → FAISS retrieves top-k relevant chunks → LLM generates a grounded answer → response + source chunks returned.

---

## 📁 Folder Structure

```
pdf-chatbot/
├── backend/
│   ├── __init__.py
│   ├── main.py                  # FastAPI app entry point
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes.py            # /upload, /ask, /health endpoints
│   │   └── schemas.py           # Pydantic request/response models
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py            # Settings (pydantic-settings + .env)
│   │   └── logger.py            # Loguru structured logging
│   ├── services/
│   │   ├── __init__.py
│   │   ├── pdf_processor.py     # PyPDFLoader + RecursiveCharacterTextSplitter
│   │   ├── vector_store.py      # FAISS build / load / persist
│   │   └── graph.py             # LangGraph IngestionGraph + QAGraph
│   └── utils/
│       ├── __init__.py
│       └── helpers.py           # File hashing, text truncation helpers
├── frontend/
│   └── app.py                   # Streamlit chat UI
├── tests/
│   ├── __init__.py
│   ├── test_pdf_processor.py
│   └── test_routes.py
├── uploads/                     # Saved PDFs (auto-created)
├── vector_store/                # FAISS index files (auto-created)
├── logs/                        # Rotating log files (auto-created)
├── .env.example                 # Copy to .env and fill in secrets
├── .gitignore
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── pytest.ini
├── start.sh                     # Unix/macOS/WSL one-command start
└── start.ps1                    # Windows PowerShell one-command start
```

---

## ⚡ Quick Start (Local)

### 1. Clone / copy the project

```bash
# If cloning from git
git clone <your-repo-url>
cd pdf-chatbot

# Or just open the folder in VS Code
```

### 2. Create and activate a virtual environment

**Windows (PowerShell)**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

**macOS / Linux**
```bash
python -m venv .venv
source .venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure environment variables

```bash
# Windows
copy .env.example .env

# macOS / Linux
cp .env.example .env
```

Open `.env` and set your OpenAI API key:

```
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

All other values have sensible defaults and do not need to be changed.

### 5. Create required directories

```bash
# Windows
mkdir uploads, vector_store, logs

# macOS / Linux
mkdir -p uploads vector_store logs
```

### 6. Start the backend

```bash
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```

Open http://localhost:8000/docs to see the interactive Swagger UI.

### 7. Start the frontend (new terminal)

```bash
streamlit run frontend/app.py
```

Open http://localhost:8501 in your browser.

### One-command start (both services)

**Windows**
```powershell
.\start.ps1
```

**macOS / Linux**
```bash
bash start.sh
```

---

## 🐳 Docker (recommended for production)

```bash
# Copy and fill in .env first
cp .env.example .env
# Edit OPENAI_API_KEY in .env

# Build and start both services
docker-compose up --build

# Stop
docker-compose down
```

- Backend: http://localhost:8000/docs  
- Frontend: http://localhost:8501

---

## 🧪 Running Tests

```bash
pytest tests/ -v
```

---

## 🔌 API Reference

### `GET /api/v1/health`
Returns API status and whether a FAISS index exists.

```json
{ "status": "ok", "index_exists": true }
```

### `POST /api/v1/upload`
Upload a PDF file.

**Request:** `multipart/form-data` with field `file` (PDF)

**Response:**
```json
{
  "message": "PDF processed and indexed successfully.",
  "filename": "report.pdf",
  "num_chunks": 48
}
```

### `POST /api/v1/ask`
Ask a question about the uploaded PDF.

**Request:**
```json
{
  "question": "What are the main findings?",
  "chat_history": [
    { "role": "user", "content": "Who wrote this report?" },
    { "role": "assistant", "content": "The report was written by..." }
  ]
}
```

**Response:**
```json
{
  "answer": "The main findings include...",
  "source_chunks": [
    {
      "content": "...relevant excerpt...",
      "source": "report.pdf",
      "page": 3,
      "chunk_id": 12
    }
  ]
}
```

---

## ⚙️ Configuration Reference (`.env`)

| Variable | Default | Description |
|---|---|---|
| `OPENAI_API_KEY` | *(required)* | Your OpenAI API key |
| `LLM_MODEL` | `gpt-4o-mini` | OpenAI chat model |
| `LLM_TEMPERATURE` | `0` | LLM temperature (0 = deterministic) |
| `LLM_MAX_RETRIES` | `3` | Retry attempts on rate-limit errors |
| `EMBEDDING_MODEL` | `text-embedding-3-small` | OpenAI embedding model |
| `CHUNK_SIZE` | `1000` | Characters per chunk |
| `CHUNK_OVERLAP` | `200` | Overlap between chunks |
| `RETRIEVAL_K` | `4` | Top-k chunks retrieved per query |
| `MAX_UPLOAD_SIZE_MB` | `50` | Max PDF file size |
| `LOG_LEVEL` | `INFO` | Logging level |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| LLM | OpenAI `gpt-4o-mini` via `langchain-openai` |
| Embeddings | OpenAI `text-embedding-3-small` |
| Orchestration | LangGraph (IngestionGraph + QAGraph) |
| RAG Chain | LangChain `ConversationalRetrievalChain` |
| Vector Store | FAISS (local, persisted to disk) |
| PDF Loading | `PyPDFLoader` + `RecursiveCharacterTextSplitter` |
| Backend | FastAPI + Uvicorn |
| Frontend | Streamlit |
| Logging | Loguru (console + rotating file) |
| Retry | Tenacity (exponential backoff on OpenAI errors) |
| Config | pydantic-settings + `.env` |

---

## 📝 Notes

- The FAISS index is **persistent** — it survives restarts. Uploading a new PDF **appends** to the existing index.
- To start fresh, delete the `vector_store/` directory.
- Chat history is stored in **Streamlit session state** (browser tab) — not in a database. Each new tab starts a fresh conversation.
- For production deployment, consider replacing the in-memory `ConversationBufferMemory` with a Redis- or Postgres-backed store.
