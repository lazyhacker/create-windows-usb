#!/bin/bash

# Windows 11 Bootable USB Creator (Based on nixaid.com tutorial)
# Tailored for Fedora Linux - With Write Speed Limits

set -e # Exit immediately if a command fails

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root. Please use sudo." 
   exit 1
fi

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <path-to-windows-11-iso> <usb-drive-device>"
    echo "Example: $0 /home/user/Downloads/Win11_English_x64v1.iso /dev/sdX"
    echo "Use 'lsblk' to find your USB drive device name."
    exit 1
fi

ISO_FILE="$1"
USB_DEV="$2"

if [[ ! -f "$ISO_FILE" ]]; then
    echo "Error: ISO file '$ISO_FILE' not found."
    exit 1
fi

if [[ ! -b "$USB_DEV" ]]; then
    echo "Error: USB device '$USB_DEV' is not a valid block device."
    exit 1
fi

echo "==================== WARNING ===================="
echo "This will ERASE ALL DATA on $USB_DEV"
lsblk "$USB_DEV"
echo "================================================="
read -p "Are you absolutely sure you want to continue? (Type 'yes' to proceed): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted by user."
    exit 0
fi

REQUIRED_CMDS="wipefs parted mkfs.vfat mkfs.ntfs rsync udisksctl"
for cmd in $REQUIRED_CMDS; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: Required command '$cmd' is missing."
        echo "Run: sudo dnf install parted dosfstools ntfs-3g rsync udisks2"
        exit 1
    fi
done

echo "[*] Wiping the USB drive..."
wipefs -a "$USB_DEV"

echo "[*] Creating partition table and partitions..."
# Creating a GPT partition table, a 1GiB FAT32 boot partition, and filling the rest with NTFS
parted -s "$USB_DEV" mklabel gpt
parted -s "$USB_DEV" mkpart BOOT fat32 0% 1GiB
parted -s "$USB_DEV" mkpart INSTALL ntfs 1GiB 100%

# Update partition table in kernel
partprobe "$USB_DEV"
sleep 2

# Identify partition paths (Supports standard /dev/sdX and NVMe structures)
if [[ "$USB_DEV" == *nvme* ]] || [[ "$USB_DEV" == *mmcblk* ]]; then
    PART_BOOT="${USB_DEV}p1"
    PART_INSTALL="${USB_DEV}p2"
else
    PART_BOOT="${USB_DEV}1"
    PART_INSTALL="${USB_DEV}2"
fi

echo "[*] Setting up mount points..."
mkdir -p /mnt/iso /mnt/vfat /mnt/ntfs

echo "[*] Mounting Windows 11 ISO..."
mount "$ISO_FILE" /mnt/iso -o loop,ro

echo "[*] Formatting and mounting BOOT (FAT32) partition..."
mkfs.vfat -n BOOT "$PART_BOOT"
mount "$PART_BOOT" /mnt/vfat/

echo "[*] Copying EFI/Boot files to BOOT partition (Excluding large 'sources' directory)..."
# Changed to rsync with --bwlimit=20M for stability
rsync -r --progress --bwlimit=20M --exclude sources --delete-before /mnt/iso/ /mnt/vfat/

echo "[*] Copying required boot.wim file..."
mkdir -p /mnt/vfat/sources
# Replaced standard 'cp' with rsync to enforce the bandwidth limit here as well
rsync --progress --bwlimit=20M /mnt/iso/sources/boot.wim /mnt/vfat/sources/

echo "[*] Formatting and mounting INSTALL (NTFS) partition..."
mkfs.ntfs --quick -L INSTALL "$PART_INSTALL"
mount "$PART_INSTALL" /mnt/ntfs/

echo "[*] Copying all Windows installation files to INSTALL partition..."
# Added --bwlimit=20M for the main, heavy payload transfer
rsync -r --progress --bwlimit=20M --delete-before /mnt/iso/ /mnt/ntfs/

echo "[*] Unmounting all partitions and flushing disk cache (This may take a minute)..."
umount /mnt/ntfs /mnt/vfat /mnt/iso
sync

echo "[*] Powering off the USB flash drive safely..."
# Using || true so the script doesn't register a failure if sudo dbus complains about udisksctl
udisksctl power-off -b "$USB_DEV" || true 

echo "================================================="
echo "Success! Your Windows 11 bootable USB is ready."
echo "You can now safely unplug it and use it to install Windows 11."
