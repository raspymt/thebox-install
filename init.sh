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

#####################################
# PACKAGES UPGRADE AND INSTALLATION #
#####################################
# update packages
pacman -Syu --noconfirm
# install packages
pacman -S --noconfirm alsa-utils \
                      ntfs-3g \
                      samba \
                      avahi \
                      hostapd \
                      ntp \
                      transmission-cli \
                      mpd \
                      nodejs-lts-carbon \
                      git \
                      base-devel \
                      libexif \
                      libjpeg \
                      libid3tag \
                      flac \
                      libvorbis \
                      ffmpeg \
                      sqlite \
                      libmpdclient \
                      libmicrohttpd \
                      jsoncpp \
                      curl \
                      expat \
                      python2

#################
# SOURCES FILES #
#################
# copy source files
cp --recursive --force root/* /
# create directories
mkdir -p /home/thebox/Downloads
mkdir -p /home/thebox/.builds
# create media directory for mount points
mkdir /media
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
# start/enable transmission service
systemctl enable --now transmission.service

############
# MINIDLNA #
############
# clone minidlna repository
git clone git://git.code.sf.net/p/minidlna/git /home/thebox/.builds/minidlna-git
# copy custom icons
cp --force minidlna/icons.c /home/thebox/.builds/minidlna-git/icons.c
# set owner and group to thebox
chown -R thebox:thebox /home/thebox/.builds/minidlna-git
# autogen, configure and compile
runuser --command='cd /home/thebox/.builds/minidlna-git && ./autogen.sh && ./configure && make' --login thebox
# make binary
cd /home/thebox/.builds/minidlna-git && make install && cd "$OLDPWD"
# create minidlna cache directory
mkdir -p /var/cache/minidlna
# change minidlna cache directory user and group
chown thebox:thebox /var/cache/minidlna
# start/enable minidlna service
systemctl enable --now minidlna.service

############
# UPMPDCLI #
############
# clone upmpdcli repository
git clone https://github.com/triplem/upmpdcli.git /home/thebox/.builds/upmpdcli-git
# set owner and group to thebox
chown -R thebox:thebox /home/thebox/.builds/upmpdcli-git
# autogen, configure and compile
runuser --command='cd /home/thebox/.builds/upmpdcli-git && ./autogen.sh && ./configure && make' --login thebox
# make binary
cd /home/thebox/.builds/upmpdcli-git && make install && cd "$OLDPWD"
# create upmpdcli cache directory
mkdir -p /var/cache/upmpdcli
# change upmpdcli cache directory user and group
chown thebox:thebox /var/cache/upmpdcli
# start/enable upmpdcli service
systemctl enable --now upmpdcli.service

#######
# MPD #
#######
# add mpd user to audio group
gpasswd -a mpd audio
# start/enable minidlna service
systemctl enable --now mpd.service

######################
# TheBox API and SAP #
######################
# start/enable TheBox API and SAP service
systemctl enable --now theboxapi.service

############
# CLEANING #
############
# remove .builds directory
rm -rf /home/thebox/.builds

##########
# REBOOT #
##########
systemctl reboot