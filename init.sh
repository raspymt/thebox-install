#!/usr/bin/env bash

########
# INIT #
########
# change root user password
echo "Change root user password:"
passwd root
# add thebox user
useradd -m thebox
# ask for thebox user password
echo "Enter thebox user password:"
passwd thebox
# remove alarm user
userdel --force --remove alarm
# create media directory for mount points
mkdir /media

#####################################
# PACKAGES UPGRADE AND INSTALLATION #
#####################################
# update packages
pacman -Syu --noconfirm
# install packages
pacman -S --noconfirm ntfs-3g samba avahi hostapd ntp transmission-cli minidlna mpd

#################
# SOURCES FILES #
#################
# copy source files
cp --recursive --force root/* /
# set user on thebox home directory
chown thebox:thebox -R /home/thebox
# reload systemd daemon
systemctl daemon-reload
# reload udev rules
udevadm control --reload-rules

###########
# NETWORK #
###########
# interface eth0
systemctl enable --now dhcpcd@eth0.service
# access point for Hostapd
systemctl enable --now access-point.service

#########
# SAMBA #
#########
# create samba usershares directory
mkdir -p /var/lib/samba/usershares
# create sambashare group
groupadd -r sambashare
# change the owner of the directory to root and the group to sambashare
chown root:sambashare /var/lib/samba/usershares
# changes the permissions of the usershares directory
# so that users in the group sambashare can read, write and execute files
chmod 1770 /var/lib/samba/usershares
# add thebox user to sambashare group
gpasswd sambashare -a thebox
# ask for samba thebox user password
echo "Enter thebox samba password:"
smbpasswd -a thebox
# create log files
mkdir -p /usr/local/samba/var/
touch /usr/local/samba/var/log.smbd
touch /usr/local/samba/var/log.nmbd
# start/enable samba services
systemctl enable --now smbd.service
systemctl enable --now nmbd.service

########
# TIME #
########
# Set timezone
timedatectl set-timezone Asia/Ho_Chi_Minh
# start/enable ntpd service
systemctl enable --now ntpd.service

#########
# AVAHI #
#########
# start/enable avahi-daemon service
systemctl enable --now avahi-daemon.service

####################
# TRANSMISSION-CLI #
####################
# start/enable minidlna service
systemctl enable --now transmission.service

############
# MINIDLNA #
############
# change minidlna cache directory user and group
chown minidlna:minidlna /var/cache/minidlna
# start/enable minidlna service
systemctl enable --now minidlna.service

#######
# MPD #
#######
# start/enable minidlna service
systemctl enable --now mpd.service

##########
# REBOOT #
##########
systemctl reboot