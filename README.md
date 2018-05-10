# Installation of The Box on Arch linux

## Requirements
A working Archlinux ARMv7 Installation on Raspberry PI 3. See https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3

## Installation
Connect by SSH to your Raspberry, then type :
```bash
cd /tmp && pacman -Sy --noconfirm git && git clone https://github.com/raspymt/thebox-install.git && cd thebox-install && ./init.sh
```
## TODO
- nftables
- bluetooth connection