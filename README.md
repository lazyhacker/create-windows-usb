# create-windows-usb

A script for creating a Windows 11 installation USB drive on Fedora Linux.

This script utilizes a split-partition method (a FAT32 partition for UEFI boot files and an NTFS partition to bypass the 4GB file size limit for the main Windows installer) to ensure compatibility with modern UEFI systems. It also includes write speed limits (`--bwlimit=20M` via `rsync`) to ensure data stability and prevent USB controller overheating or caching crashes during large file transfers.

*Based on the tutorial from [nixaid.com](https://nixaid.com/archive/article/bootable-usb-windows-linux?era=ghost).*

## Context

Microsoft provides an official Media Creation Tool to easily build bootable Windows USB drives, but this tool is exclusively available for Windows. There is no official equivalent for Linux users.

When Linux users need to create a Windows bootable USB, the most common suggestion is to download various third-party applications. Rather than downloading and trusting unverified third-party software to handle your operating system installation media, this script allows you to create the drive simply and securely using standard, trusted command-line tools already available in the Fedora distribution.

## ⚠️ Warning

**This script will completely erase all data on the target USB drive.** Please ensure you select the correct device, or you risk overwriting your system drive.

## Prerequisites

Before running the script, ensure you have the necessary tools installed on your Fedora system. You can install the required packages by running:

`sudo dnf install parted dosfstools ntfs-3g rsync udisks2`

## Download & Verify the ISO

1. **Download:** Obtain the official Windows 11 ISO directly from [Microsoft's Software Download page](https://www.microsoft.com/software-download/windows11). Scroll down to the **"Download Windows 11 Disk Image (ISO) for x64 devices"** section.

2. **Verify:** It is highly recommended to validate your download to ensure the file isn't corrupted or incomplete. Microsoft provides the expected SHA256 hash on their download page (look for the "Verify your download" dropdown after selecting your language). Run the following command in your terminal and ensure the output matches the hash provided by Microsoft:

   `sha256sum /path/to/Win11_English_x64v1.iso`

## How to Run the Script

1. **Identify your USB Drive:**
   Plug in your USB drive and identify its device path (e.g., `/dev/sdb`, `/dev/nvme0n1`, etc.) by running:

   `lsblk`

   *Take careful note of your USB drive's letter or name (e.g., `sdb`, not the partition `sdb1`).*

2. **Make the script executable:**
   Navigate to the directory where you downloaded the script and grant it execution permissions:

   `chmod +x create-win11-usb.sh`

3. **Execute the script as root:**
   Run the script using `sudo`, followed by the exact path to your verified Windows 11 ISO and the path to your USB block device.

   `sudo ./create-win11-usb.sh /path/to/Win11_English_x64v1.iso /dev/sdX`

   *(Example: `sudo ./create-win11-usb.sh ~/Downloads/Win11_English_x64v1.iso /dev/sdb`)*

4. **Confirm the wipe:**
   The script will display the partition layout of the selected drive. Type `yes` when prompted to confirm the wipe and proceed with the creation.

5. **Wait for completion:**
   The script will format the drive, copy the required files, and safely flush the disk cache. Once it displays **"Success!"**, the script will automatically power off the USB drive safely, and it is ready to be unplugged.

## How It Works

1. **Wipes** the target USB drive.

2. **Creates a GPT partition table** with two partitions:

   * **BOOT (FAT32, 1GiB):** Stores the necessary UEFI boot files and the `boot.wim` environment.

   * **INSTALL (NTFS, Remaining Space):** Stores the actual Windows installation payload, which contains files larger than the 4GB FAT32 limit.

3. **Mounts the Windows ISO** and extracts the contents.

4. **Uses `rsync`** with a bandwidth limit to safely copy the boot files to the FAT32 partition and the installation payload to the NTFS partition.

5. **Syncs and powers off** the drive safely using `udisksctl`.
