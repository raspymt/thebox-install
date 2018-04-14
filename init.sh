#!/usr/bin/env bash

########
# INIT #
########
THEBOX_USER='thebox'
THEBOX_TIMEZONE='Asia/Ho_Chi_Minh'


# change root user password
echo "Change root user password:"
passwd root
# add thebox user
useradd -m $THEBOX_USER
# ask for thebox user password
echo "Enter ${THEBOX_USER} user password:"
passwd $THEBOX_USER
# remove alarm user
userdel --force --remove alarm

################################
# RASPBERRY PI 3 B BOOT CONFIG #
################################
# enable onboard soundcard
echo 'dtparam=audio=on' >> /boot/config.txt
# remove distortion using the 3.5mm analogue output
echo 'audio_pwm_mode=2' >> /boot/config.txt

#####################################
# PACKAGES UPGRADE AND INSTALLATION #
#####################################
# update packages
pacman -Syu --noconfirm
# install packages
pacman -S --noconfirm \
    alsa-utils \
    ntfs-3g \
    samba \
    avahi \
    nss-mdns \
    dnsmasq \
    hostapd \
    ntp \
    transmission-cli \
    mpd \
    nodejs-lts-carbon \
    npm \
    git \
    base-devel \
    libexif \
    libjpeg \
    libid3tag \
    flac \
    libvorbis \
    libjpeg-turbo \
    ffmpeg \
    sqlite

#################
# SOURCES FILES #
#################
# copy source files
cp --recursive --force root/* /
# create media directory for mount points
mkdir /media
# create thebox user directories
mkdir -p "/home/${THEBOX_USER}/Downloads"
mkdir -p "/home/${THEBOX_USER}/.builds"
# set user on thebox home directory
chown $THEBOX_USER:$THEBOX_USER -R "/home/${THEBOX_USER}"
# reload systemd daemon
systemctl daemon-reload
# reload udev rules
udevadm control --reload-rules

##########
# LOCALE #
##########
# TODO: locales selection
# generate locales
echo "en_US.UTF-8 UTF-8"  > /etc/locale.gen
echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
echo "vi_VN UTF-8"       >> /etc/locale.gen
locale-gen

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
gpasswd sambashare -a $THEBOX_USER
# ask for samba thebox user password
echo "Enter ${THEBOX_USER} samba password:"
smbpasswd -a $THEBOX_USER
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
timedatectl set-timezone $THEBOX_TIMEZONE
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
# copy custom icons
cp minidlna/icons.c "/home/${THEBOX_USER}/.builds/icons.c"
chown $THEBOX_USER:$THEBOX_USER "/home/${THEBOX_USER}/.builds/icons.c"
# autogen, configure and compile
runuser --command="cd /home/${THEBOX_USER}/.builds && git clone -b v1_2_1 https://git.code.sf.net/p/minidlna/git minidlna && cd minidlna && mv --force ../icons.c ./icons.c && ./autogen.sh && ./configure && make" --login $THEBOX_USER
# make binary
cd "/home/${THEBOX_USER}/.builds/minidlna" && make install && cd $OLDPWD
# create minidlna cache directory
mkdir -p /var/cache/minidlna
# create minidlna run directory
mkdir -p /var/run/minidlna
# create minidlna log directory
mkdir -p /var/log/minidlna
# change minidlna cache directory user and group
chown $THEBOX_USER:$THEBOX_USER /var/cache/minidlna
chmod 0755 "/var/cache/minidlna"
# change minidlna run directory user and group
chown $THEBOX_USER:$THEBOX_USER /var/run/minidlna
chmod 0755 "/var/run/minidlna"
# change minidlna log directory user and group
chown $THEBOX_USER:$THEBOX_USER /var/log/minidlna
chmod 0755 "/var/log/minidlna"
# launch minidlna rebuild
runuser --command="/usr/local/sbin/minidlnad -R" --login $THEBOX_USER
# enable minidlna service, do not start the service
# minidlna has been launch with minidlnad -R by thebox user
systemctl enable minidlna.service

#######
# MPD #
#######
# add thebox user to audio group
gpasswd audio -a $THEBOX_USER
# systemctl enable --now mpd.socket
systemctl disable mpd.socket
systemctl enable --now mpd.service

######################
# TheBox API and SAP #
######################
# install NPM packages
# build sqlite3 from source
runuser --command="cd /home/${THEBOX_USER}/.thebox-api && npm install --production --build-from-source --sqlite=/usr/include" --login $THEBOX_USER
# start/enable TheBox API and SAP service
systemctl enable --now theboxapi.service

############
# CLEANING #
############
# remove .builds directory? What about the updates?
#rm -rf "/home/${THEBOX_USER}/.builds"

##########
# REBOOT #
##########
systemctl reboot