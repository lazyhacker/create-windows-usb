# create-windows-usb

A script for creating a Windows 11 installation USB drive on Fedora Linux.

This script utilizes a split-partition method (a FAT32 partition for UEFI boot files and an NTFS partition to bypass the 4GB file size limit for the main Windows installer) to ensure compatibility with modern UEFI systems. It also includes write speed limits (`--bwlimit=20M` via `rsync`) to ensure data stability and prevent USB controller overheating or caching crashes during large file transfers.

*Based on the tutorial from [nixaid.com](https://nixaid.com/archive/article/bootable-usb-windows-linux?era=ghost).*

---

## Context
Microsoft provides an official Media Creation Tool to easily build bootable Windows USB drives, but this tool is exclusively available for Windows. There is no official equivalent for Linux users.

When Linux users need to create a Windows bootable USB, the most common suggestion is to download various third-party applications. Rather than downloading and trusting unverified third-party software to handle your operating system installation media, this script allows you to create the drive simply and securely using standard, trusted command-line tools already available in the Fedora distribution.

---

## ⚠️ Warning
**This script will completely erase all data on the target USB drive.** Please ensure you select the correct device, or you risk overwriting your system drive.

---

## Prerequisites

Before running the script, ensure you have the necessary tools installed on your Fedora system. You can install the required packages by running:

```bash
sudo dnf install parted dosfstools ntfs-3g rsync udisks2
