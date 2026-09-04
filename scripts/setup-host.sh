#!/usr/bin/env bash
# ==============================================================================
# HOMELAB AI TOOLS: OPTIONAL HOST STORAGE & KERNEL OPTIMIZATION HELPER
# Prepares workspace storage directory and I/O sysctl tuning
# ==============================================================================
set -euo pipefail

WORKSPACE_PATH="${WORKSPACE_DIR:-/srv/data/workspace}"

echo "=== 1. Setting up Workspace Storage Directory at ${WORKSPACE_PATH} ==="
sudo mkdir -p "${WORKSPACE_PATH}"
sudo chmod 775 "${WORKSPACE_PATH}"

echo -e "\n=== 2. Applying Kernel Storage I/O Optimizations ==="
SYSCTL_CONF="/etc/sysctl.d/99-homelab-io-optimization.conf"

cat << 'EOF' | sudo tee "${SYSCTL_CONF}"
# Optimize dirty page memory buffer to prevent massive I/O write queue freezes
vm.dirty_background_bytes = 16777216
vm.dirty_bytes = 67108864
vm.dirty_writeback_centisecs = 100
vm.dirty_expire_centisecs = 300
vm.swappiness = 10
EOF

sudo sysctl --system >/dev/null

echo "Kernel sysctl parameters applied successfully."
echo "=== Host Setup Complete ==="
