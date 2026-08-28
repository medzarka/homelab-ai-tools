#!/usr/bin/env bash
# ==============================================================================
# HOMELAB-SRV-COMPUTE: HOST SETUP SCRIPT FOR ZAP-SRV
# Configures 16GB tmpfs RAM-disk and Kernel Anti-Freeze Sysctl Optimizations
# ==============================================================================
set -euo pipefail

RAMDISK_PATH="/mnt/ramdisk"
RAMDISK_SIZE="24G"

echo "=== 1. Setting up Host RAM-Disk (${RAMDISK_SIZE} at ${RAMDISK_PATH}) ==="
sudo mkdir -p "${RAMDISK_PATH}"

# Add to /etc/fstab if not present
if ! grep -q "${RAMDISK_PATH}" /etc/fstab; then
    echo "Adding ${RAMDISK_PATH} to /etc/fstab..."
    echo "tmpfs  ${RAMDISK_PATH}  tmpfs  rw,nosuid,nodev,noatime,size=${RAMDISK_SIZE},mode=1777  0  0" | sudo tee -a /etc/fstab
fi

# Mount if not already mounted
if ! mountpoint -q "${RAMDISK_PATH}"; then
    echo "Mounting ${RAMDISK_PATH}..."
    sudo mount "${RAMDISK_PATH}"
fi

# Ensure permissions
sudo chmod 1777 "${RAMDISK_PATH}"
sudo chown root:root "${RAMDISK_PATH}"

echo "RAM-Disk mounted successfully:"
df -h "${RAMDISK_PATH}"

echo -e "\n=== 2. Applying Kernel Anti-Freeze I/O Optimizations ==="
SYSCTL_CONF="/etc/sysctl.d/99-homelab-slow-disk-optimization.conf"

cat << 'EOF' | sudo tee "${SYSCTL_CONF}"
# Cap dirty page memory buffer to prevent massive I/O write queue freezes on slow disks
vm.dirty_background_bytes = 16777216
vm.dirty_bytes = 67108864
vm.dirty_writeback_centisecs = 100
vm.dirty_expire_centisecs = 300
vm.swappiness = 5
EOF

sudo sysctl --system >/dev/null

echo "Kernel sysctl parameters applied successfully."
echo "=== Host Setup Complete ==="
