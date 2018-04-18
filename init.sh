#!/usr/bin/env bash

#############
# VARIABLES #
#############
THEBOX_USER='thebox'
THEBOX_TIMEZONE='Asia/Ho_Chi_Minh'

#########
# USERS #
#########
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
    sqlite \
    wget \
    fuse2 \
    libarchive \
    vala \
    oniguruma \
    libevent \
    cmake \
    libldap \
    libmariadbclient \
    postgresql-libs \
    jansson \
    glib2 \
    freetype2 \
    libmemcached \
    openjpeg2 \
    python2 \
    python2-simplejson \
    python2-gobject2 \
    python2-virtualenv \
    python2-setuptools

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

########
# TIME #
########
# Set timezone
timedatectl set-timezone $THEBOX_TIMEZONE

###############################
# MINIDLNA WITH THE BOX ICONS #
###############################
runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://github.com/raspymt/thebox-minidlna.git && cd thebox-minidlna && makepkg" --login $THEBOX_USER
# install package
cd "/home/${THEBOX_USER}/.builds/thebox-minidlna" && pacman -U --noconfirm thebox-minidlna*.pkg.tar.xz && cd $OLDPWD
# change default DLNA server name
sed -i 's/#friendly_name=My DLNA Server/friendly_name=The Box DLNA Server/' /etc/minidlna.conf
# change default media dir
sed -i 's/media_dir=\/opt/media_dir=\/media/' /etc/minidlna.conf
# launch a rebuild
/usr/bin/minidlnad -R

#######
# MPD #
#######
# add thebox user to audio group
gpasswd audio -a $THEBOX_USER

######################
# TheBox API and SAP #
######################
# clone repository thebox-api, install NPM packages for production and build sqlite3 from source
runuser --command="mkdir /home/${THEBOX_USER}/.thebox && cd /home/${THEBOX_USER}/.thebox && git clone https://github.com/raspymt/thebox-api.git && cd thebox-api && npm install --production --build-from-source --sqlite=/usr/include" --login $THEBOX_USER
# clone repository thebox-sap, install NPM packages prod and dev, build nuxt and remove NPM dev packages
# need to remove NPM dev modules with 'npm prune --production' ?
runuser --command="cd /home/${THEBOX_USER}/.thebox && git clone https://github.com/raspymt/thebox-sap.git && cd thebox-sap && npm install && npm run build" --login $THEBOX_USER

############
# CLEANING #
############
# remove .builds directory? What about the updates?
#rm -rf "/home/${THEBOX_USER}/.builds"

#########################
# START/ENABLE SERVICES #
#########################
systemctl enable --now \
    dhcpcd@eth0.service \
    access-point.service \
    smbd.service \
    nmbd.service \
    ntpd.service \
    avahi-daemon.service \
    transmission.service \
    minidlna.service \
    mpd.service \
    theboxapi.service

##################
# SEAFILE SERVER #
##################
# DEPENDENCIES FROM AUR
# libevhtp-seafile
runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/libevhtp-seafile.git libevhtp-seafile && cd libevhtp-seafile && makepkg" --login $THEBOX_USER
# install package
cd "/home/${THEBOX_USER}/.builds/libevhtp-seafile" && pacman -U libevhtp-seafile*.pkg.tar.xz && cd $OLDPWD

# libsearpc
runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/libsearpc.git libsearpc && cd libsearpc && makepkg" --login $THEBOX_USER
# install package
cd "/home/${THEBOX_USER}/.builds/libsearpc" && pacman -U libsearpc*.pkg.tar.xz && cd $OLDPWD

# ccnet-server
runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/ccnet-server.git ccnet-server && cd ccnet-server && makepkg" --login $THEBOX_USER
# install package
cd "/home/${THEBOX_USER}/.builds/ccnet-server" && pacman -U ccnet-server*.pkg.tar.xz && cd $OLDPWD

# seafile-server
runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/seafile-server.git seafile-server && cd seafile-server && makepkg" --login $THEBOX_USER
# install package
cd "/home/${THEBOX_USER}/.builds/seafile-server" && pacman -U seafile-server*.pkg.tar.xz && cd $OLDPWD

# seahub
runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/seahub.git seahub && cd seahub && makepkg" --login $THEBOX_USER
# install package
cd "/home/${THEBOX_USER}/.builds/seahub" && pacman -U seahub*.pkg.tar.xz && cd $OLDPWD

# webdav support
# python2-seafobj
runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/python2-seafobj.git python2-seafobj && cd python2-seafobj && makepkg" --login $THEBOX_USER
# install package
cd "/home/${THEBOX_USER}/.builds/python2-seafobj" && pacman -U python2-seafobj*.pkg.tar.xz && cd $OLDPWD

# python2-wsgidav-seafile
runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/python2-wsgidav-seafile.git python2-wsgidav-seafile && cd python2-wsgidav-seafile && makepkg" --login $THEBOX_USER
# install package
cd "/home/${THEBOX_USER}/.builds/python2-wsgidav-seafile" && pacman -U python2-wsgidav-seafile*.pkg.tar.xz && cd $OLDPWD

# SETUP THE SERVER
useradd -m -r -d /srv/seafile -s /usr/bin/nologin seafile
SEAFILE_SERVER_VERSION=$(pacman -Qi seafile-server | grep 'Version' | cut -d ':' -f 2 | cut -d ' ' -f 2 | cut -d '-' -f 1)
su - seafile -s /bin/sh --command="mkdir -p /srv/seafile/${THEBOX_USER}/seafile-server && cd /srv/seafile/${THEBOX_USER} && wget -P seafile-server https://github.com/haiwen/seahub/archive/v${SEAFILE_SERVER_VERSION}-server.tar.gz && tar -xz -C seafile-server -f seafile-server/v${SEAFILE_SERVER_VERSION}-server.tar.gz && mv seafile-server/seahub-${SEAFILE_SERVER_VERSION}-server seafile-server/seahub && seafile-admin setup"
systemctl enable --now "seafile-server@${THEBOX_USER}"
su - seafile -s /bin/sh --command="cd /srv/seafile/${THEBOX_USER} && seafile-admin create-admin"

##########
# REBOOT #
##########
systemctl reboot