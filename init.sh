#!/usr/bin/env bash

########
# INIT #
########
THEBOX_USER='thebox'
THEBOX_TIMEZONE='Asia/Ho_Chi_Minh'


# change root user password
echo "#########################"
echo "# Change ROOT password: #"
echo "#########################"
passwd root
# add thebox user
useradd -m $THEBOX_USER
# ask for thebox user password
echo "###############################"
echo "# Enter $(echo $THEBOX_USER | tr 'a-z' 'A-Z') user password: #"
echo "###############################"
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
echo "################################"
echo "# Enter $(echo $THEBOX_USER | tr 'a-z' 'A-Z') samba password: #"
echo "################################"
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

###############################
# MINIDLNA WITH THE BOX ICONS #
###############################
runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://github.com/raspymt/thebox-minidlna.git && cd thebox-minidlna && makepkg" --login $THEBOX_USER
# install package
cd "/home/${THEBOX_USER}/.builds/thebox-minidlna" && pacman -U --noconfirm thebox-minidlna*.pkg.tar.xz && cd $OLDPWD
# change default DLNA server name
sed -i 's/#friendly_name=My DLNA Server/friendly_name=The Box DLNA Server/' /etc/minidlna.conf
# start/enable minidlna service
systemctl enable --now minidlna.service

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
# clone repository thebox-api, install NPM packages for production and build sqlite3 from source
runuser --command="mkdir /home/${THEBOX_USER}/.thebox && cd /home/${THEBOX_USER}/.thebox && git clone https://github.com/raspymt/thebox-api.git && cd thebox-api && npm install --production --build-from-source --sqlite=/usr/include" --login $THEBOX_USER
# clone repository thebox-sap, install NPM packages prod and dev, build nuxt and remove NPM dev packages
# need to remove NPM dev modules with 'npm prune --production' ?
runuser --command="cd /home/${THEBOX_USER}/.thebox && git clone https://github.com/raspymt/thebox-sap.git && cd thebox-sap && npm install && npm run build" --login $THEBOX_USER
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