WARNING: Work in progress - DO NOT USE...

# Installation of The Box on Arch linux

## Requirements
A working Archlinux ARMv7 Installation on Raspberry PI 3. See https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3

## Installation
Connect to your Raspberry by SSH, then (you must be root):
```bash
pacman-key --init && pacman-key --populate archlinuxarm && pacman --sync --refresh --sysupgrade --needed --disable-download-timeout --noconfirm git && git clone https://github.com/raspymt/thebox-install.git /tmp/thebox-install && cd /tmp/thebox-install && ./init.sh
```
