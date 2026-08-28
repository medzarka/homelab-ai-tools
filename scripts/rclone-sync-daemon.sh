#!/bin/sh
# ==============================================================================
# HOMELAB-SRV-COMPUTE: RCLONE SYNC DAEMON
# Handles boot-time workspace pull, 5-minute periodic sync, and graceful exit flush
# ==============================================================================
set -e

LOCAL_DIR="${LOCAL_SYNC_DIR:-/workspace}"
REMOTE_TARGET="${RCLONE_REMOTE_TARGET:-}"
INTERVAL="${RCLONE_SYNC_INTERVAL:-300}"

echo "========================================================"
echo ">>> [Rclone Daemon] Initializing Sync Engine"
echo ">>> Local Source:  ${LOCAL_DIR}"
echo ">>> Remote Target: ${REMOTE_TARGET}"
echo ">>> Sync Interval: ${INTERVAL}s (5 minutes)"
echo "========================================================"

if [ -z "${REMOTE_TARGET}" ]; then
    echo ">>> [Rclone Daemon] ERROR: RCLONE_REMOTE_TARGET is not defined! Exiting."
    exit 1
fi

# Exit hook for graceful shutdown / container stop
sync_and_exit() {
    echo ""
    echo ">>> [Rclone Daemon] SIGTERM/SIGINT received. Flushing workspace to remote storage..."
    rclone sync "${LOCAL_DIR}" "${REMOTE_TARGET}" \
        --fast-list \
        --transfers 4 \
        --checkers 8 \
        --exclude ".git/**" \
        --exclude "__pycache__/**" \
        --exclude ".cache/**" \
        --verbose || true
    echo ">>> [Rclone Daemon] Final flush complete. Safe to terminate."
    exit 0
}

trap 'sync_and_exit' SIGTERM SIGINT

# ------------------------------------------------------------------------------
# 1. BOOT-TIME SYNC (Pull remote workspace into RAM if remote has data)
# ------------------------------------------------------------------------------
echo ">>> [Rclone Daemon] Checking remote workspace status..."
if rclone lsf "${REMOTE_TARGET}" >/dev/null 2>&1; then
    echo ">>> [Rclone Daemon] Pulling initial workspace from ${REMOTE_TARGET} to ${LOCAL_DIR}..."
    rclone copy "${REMOTE_TARGET}" "${LOCAL_DIR}" \
        --fast-list \
        --transfers 4 \
        --checkers 8 \
        --update \
        --verbose || echo ">>> [Rclone Daemon] Initial copy returned with warning (proceeding)."
    echo ">>> [Rclone Daemon] Boot-time pull complete."
else
    echo ">>> [Rclone Daemon] Remote target is empty or new. Initial pull skipped."
fi

# ------------------------------------------------------------------------------
# 2. CONTINUOUS PERIODIC SYNC LOOP (Every 5 minutes)
# ------------------------------------------------------------------------------
echo ">>> [Rclone Daemon] Entering periodic synchronization loop (Interval: ${INTERVAL}s)..."

while true; do
    sleep "${INTERVAL}" &
    WAIT_PID=$!
    wait "${WAIT_PID}"

    echo ">>> [Rclone Daemon] [$(date '+%Y-%m-%d %H:%M:%S')] Starting periodic sync to ${REMOTE_TARGET}..."
    rclone sync "${LOCAL_DIR}" "${REMOTE_TARGET}" \
        --fast-list \
        --transfers 4 \
        --checkers 8 \
        --exclude ".git/**" \
        --exclude "__pycache__/**" \
        --exclude ".cache/**" \
        --verbose || echo ">>> [Rclone Daemon] Periodic sync encountered a non-fatal warning."
    echo ">>> [Rclone Daemon] [$(date '+%Y-%m-%d %H:%M:%S')] Periodic sync complete."
done
