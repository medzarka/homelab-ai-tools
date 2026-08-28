# Homelab AI Tools Stack

This repository contains the heavily optimized orchestration logic for the core AI compute stack in your homelab. It leverages an ephemeral 24GB Host OS RAM disk to ensure all models and inference operations execute at blazing speeds with virtually zero disk I/O bottleneck.

## Included Services

- **Ollama**: Local AI engine tuned for parallel model loading (Vision/Chat models).
- **OnlyOffice**: Lean, single-user edition for fast document processing.
- **SearXNG**: Private metasearch engine configured with internal APIs for agent tool use.
- **Firecrawl**: A complete web scraping stack (Playwright, Redis, Postgres, API/Worker) running entirely in RAM.
- **Speaches**: High-performance TTS and STT (Whisper Large v3 + Kokoro-82M).
- **TEI Embeddings & Reranker**: HuggingFace Text Embeddings Inference running CPU-optimized Rust engines for rapid semantic searches (BAAI/bge-m3 and BAAI/bge-reranker-v2-m3).

## Architecture Details

- **RAM Disk Mount**: All containers mount `/mnt/ramdisk` from the host. A standalone `tools-ramdisk-init` container prepares all specific sub-directories (like `/ramdisk/ollama` and `/ramdisk/searxng`) automatically before the stack boots.
- **Zero Custom Images**: This repository does not compile custom Python packages or require Docker build contexts. It strictly orchestrates official Docker Hub/GHCR images, meaning deployment is incredibly fast.
- **Concurrency & Threads**: Configured precisely for high core-count CPUs using variables like `OMP_NUM_THREADS` and `RAYON_NUM_THREADS` to prevent thread-starvation on large workloads.

## Getting Started

1. **Clone the repository.**
2. **Configure Environment:**
   Copy `.env.example` to `.env` and fill out your required parameters and secure keys:
   ```bash
   cp .env.example .env
   # Edit .env with your favorite editor
   ```
3. **Ensure Host Preparation:**
   Ensure the host machine has actually provisioned a RAM disk at `/mnt/ramdisk` (usually via `/etc/fstab`).
4. **Deploy:**
   If using Arcane (or standard Docker Swarm):
   ```bash
   docker compose up -d
   ```
