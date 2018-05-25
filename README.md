WARNING: Work in progress - DO NOT USE...

# Installation of The Box on Arch linux

## Requirements
A working Archlinux ARMv7 Installation on Raspberry PI 3. See https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3

## Installation
Connect to your Raspberry by SSH, then:
```bash
cd /tmp && pacman -Syu --noconfirm git && git clone https://github.com/raspymt/thebox-install.git && cd thebox-install && ./init.sh
```
