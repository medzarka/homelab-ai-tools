# Homelab AI Tools Stack

This repository contains the orchestration logic for the core AI inference, search, and compute toolstack in the homelab environment. It is designed to be high-performance, modular, and container-native across host architectures.

## Included Services

- **Ollama**: Local AI engine tuned for parallel model execution and Vision/Chat models (`qwen2.5vl:3b`, `hermes3:8b`).
- **OnlyOffice**: Lean, single-user edition for fast document processing and previewing.
- **SearXNG**: Private, privacy-respecting metasearch engine configured for AI agent tool calling and search retrieval.
- **Firecrawl**: A complete web scraping and crawling stack (Playwright, Redis, Postgres, API, Queue Worker).
- **Speaches**: OpenAI-compatible TTS (Kokoro-82M) and STT (Whisper Large v3) inference server.
- **Hugging Face TEI**: High-throughput Text Embeddings Inference running CPU-optimized Rust engines for semantic search and reranking (`BAAI/bge-m3` and `BAAI/bge-reranker-v2-m3`).

## Architecture & Storage Design

- **Storage Abstraction (`WORKSPACE_DIR`)**: All services persist caches, databases, and model weights to a configurable `${WORKSPACE_DIR}` mount point (e.g. `/srv/data/workspace` or any high-speed host mount).
- **Automated Storage Guard (`tools-workspace-init`)**: Prepares required service subdirectories and initializes baseline configurations before dependent services start.
- **Network Isolation**: All services communicate across dedicated overlay networks (`shared_net` and `homelab_swarm_net`). Containers expose internal ports without binding to host interfaces, ensuring edge security and preventing port collisions.
- **Ingress & Proxy**: Built-in Traefik labels allow automated routing through the homelab edge gateway with TLS and Fail2ban protection.
- **Thread & Concurrency Tuning**: Pre-configured for multi-core CPUs using `OMP_NUM_THREADS` and `RAYON_NUM_THREADS` to eliminate thread starvation during concurrent inference.

## Getting Started

### 1. Configure Environment
Copy `.env.example` to `.env` and fill out your required parameters and secure keys:
```bash
cp .env.example .env
```

Ensure you set strong random tokens:
- `ONLYOFFICE_JWT_SECRET`: `openssl rand -hex 32`
- `SEARXNG_SECRET`: `openssl rand -hex 16`
- `FIRECRAWL_API_KEY`: Strong API key for scraper access
- `OLLAMA_API_KEY`, `TEI_API_KEY`, `SPEACHES_API_KEY`: API keys for inference services
- `NUQ_PASSWORD`, `RABBITMQ_ERLANG_COOKIE`: Internal database credentials

### 2. Prepare Storage Directory
Ensure the configured `WORKSPACE_DIR` exists on the host with write permissions for the container runtime:
```bash
mkdir -p /srv/data/workspace
chmod 775 /srv/data/workspace
```

*(Optional)* Run the host tuning helper script to apply kernel I/O write buffer optimizations:
```bash
./scripts/setup-host.sh
```

### 3. Deploy Stack
Start the services in detached mode:
```bash
docker compose up -d
```

Check the status of running containers:
```bash
docker compose ps
```

### 4. Verify Services
- **Ollama**: Verify models are loaded:
  ```bash
  docker compose exec ollama ollama list
  ```
- **SearXNG**: Test internal health check or query via Traefik:
  ```bash
  curl -s http://searxng:8080/healthz
  ```
- **Firecrawl**: Check API status:
  ```bash
  docker compose logs firecrawl-api
  ```
- **Speaches**: Check STT/TTS engine logs:
  ```bash
  docker compose logs speaches
  ```
- **TEI Embeddings & Reranker**: Check model readiness:
  ```bash
  docker compose logs embeddings
  docker compose logs reranker
  ```
