#!/usr/bin/env bash

# ask for new root user password
passwd root

# add thebox user
useradd -m -G wheel thebox
# ask for thebox user password
passwd thebox

# create media directory for mount points
mkdir /media

# update packages
pacman -Syu --noconfirm

# install packages
pacman -S samba
# minidlna mpd

# copy source files
cp --recursive --force root/* /

# reload systemd daemon
systemctl daemon-reload

# reload udev rules
udevadm control --reload-rules