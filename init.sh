#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
# __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
# __base="$(basename ${__file} .sh)"
# __root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app

# arg1="${1:-}"

THEBOX_USER='thebox'
THEBOX_TIMEZONE='Asia/Ho_Chi_Minh'


# Set logs to ram
logs_to_ram() {
    # create tmp 
    echo "tmpfs /var/log tmpfs nodev,nosuid,noatime,mode=1777,size=20m 0 0" >> /etc/fstab
    # remount partitions
    mount -o remount /
}

# Configure timezone
set_timezone(){
    timedatectl set-timezone $THEBOX_TIMEZONE    
}

# Set hostname
set_hostname(){
    hostnamectl set-hostname $THEBOX_USER    
}

# Set hosts
set_hosts(){
    echo "127.0.0.1 localhost.localdomain localhost" > /etc/hosts
    echo "::1 localhost.localdomain localhost" >> /etc/hosts
    echo "127.0.0.1 ${THEBOX_USER}.localdomain ${THEBOX_USER}" >> /etc/hosts
    echo "::1 ${THEBOX_USER}.localdomain ${THEBOX_USER}" >> /etc/hosts    
}

# Set locales
set_locales(){
    # TODO: locales selection
    echo "en_US.UTF-8 UTF-8"  > /etc/locale.gen
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
    echo "vi_VN UTF-8"       >> /etc/locale.gen
    # generate locales
    locale-gen    
}

# Process root and main users
process_users(){
    # change root user password
    echo "Change root password:"
    passwd root
    # add thebox user
    useradd -m $THEBOX_USER
    # ask for thebox user password
    echo "Enter $(echo $THEBOX_USER | tr 'a-z' 'A-Z') user password:"
    passwd $THEBOX_USER
    # remove alarm user
    userdel --force --remove alarm    
}

# Set raspberry pi 3 b boot config
rpi_boot_config(){
    # enable onboard soundcard
    echo 'dtparam=audio=on' >> /boot/config.txt
    # remove distortion using the 3.5mm analogue output
    echo 'audio_pwm_mode=2' >> /boot/config.txt
}

# Upgrade and install necessary packages
install_packages(){
    pacman -Syu --noconfirm \
        sudo \
        openssl \
        alsa-utils \
        ntfs-3g \
        samba \
        avahi \
        nss-mdns \
        hostapd \
        ntp \
        transmission-cli \
        mpd \
        libmpdclient \
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
        python2-setuptools \
        nftables
}

# Copy sources files, create necessary directories, set main user directory permissions
# reload systemd daemon and reload udev rules 
process_source_files(){
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
}

# Install Minidlna
install_minidlna(){
    runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://github.com/raspymt/thebox-minidlna.git && cd thebox-minidlna && makepkg" --login $THEBOX_USER
    # install package as root
    cd "/home/${THEBOX_USER}/.builds/thebox-minidlna" && pacman -U --noconfirm thebox-minidlna*.pkg.tar.xz && cd $OLDPWD
    # change default DLNA server name
    sed -i 's/#friendly_name=My DLNA Server/friendly_name=The Box DLNA Server/' /etc/minidlna.conf
    # disable logs
    sed -i 's/#log_level=general,artwork,database,inotify,scanner,metadata,http,ssdp,tivo=warn/log_level=general=off,artwork=off,database=off,inotify=off,scanner=off,metadata=off,http=off,ssdp=off,tivo=off/' /etc/minidlna.conf
    # change default media dir
    sed -i 's/media_dir=\/opt/media_dir=\/media/' /etc/minidlna.conf
    # launch a database rebuild
    /usr/bin/minidlnad -R
}

# Install YMPD
install_ympd(){
    runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/ympd.git && cd ympd && makepkg" --login $THEBOX_USER
    # install package
    cd "/home/${THEBOX_USER}/.builds/ympd" && pacman -U --noconfirm ympd*.pkg.tar.xz && cd $OLDPWD    
}

# Install The Box API
install_thebox_api(){
    # clone repository thebox-api, install NPM packages for production and build sqlite3 from source
    runuser --command="mkdir /home/${THEBOX_USER}/.thebox && cd /home/${THEBOX_USER}/.thebox && git clone https://github.com/raspymt/thebox-api.git && cd thebox-api && npm install --production --build-from-source --sqlite=/usr/include" --login $THEBOX_USER
}

# Install The Box SAP
install_thebox_sap(){
    # clone repository thebox-sap, install NPM packages prod and dev and build nuxt
    # TODO: Do we need to remove NPM dev modules with the command 'npm prune --production'?
    runuser --command="cd /home/${THEBOX_USER}/.thebox && git clone https://github.com/raspymt/thebox-sap.git && cd thebox-sap && npm install && npm run build" --login $THEBOX_USER
}

# Install Seafile server
install_seafile_server(){
    # TODO: cutomizations (view: https://manual.seafile.com/config/seahub_customization.html)

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

    # Webdav support
    # python2-seafobj
    #runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/python2-seafobj.git python2-seafobj && cd python2-seafobj && makepkg" --login $THEBOX_USER
    # install package
    #cd "/home/${THEBOX_USER}/.builds/python2-seafobj" && pacman -U python2-seafobj*.pkg.tar.xz && cd $OLDPWD

    # python2-wsgidav-seafile
    #runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/python2-wsgidav-seafile.git python2-wsgidav-seafile && cd python2-wsgidav-seafile && makepkg" --login $THEBOX_USER
    # install package
    #cd "/home/${THEBOX_USER}/.builds/python2-wsgidav-seafile" && pacman -U python2-wsgidav-seafile*.pkg.tar.xz && cd $OLDPWD
}

# Configure Samba
config_samba(){
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
    echo "# Enter $(echo $THEBOX_USER | tr 'a-z' 'A-Z') samba password:"
    smbpasswd -a $THEBOX_USER
    # create log directory and files
    mkdir -p /usr/local/samba/var/
    touch /usr/local/samba/var/log.smb
    touch /usr/local/samba/var/log.nmb    
}

# Configure MPD
config_mpd(){
    # add thebox user to audio group
    gpasswd audio -a $THEBOX_USER    
}

# Configure Seafile server
config_seafile_server(){
    # add Seafile user
    useradd -m -r -d /srv/seafile -s /usr/bin/nologin seafile
    # get Seafile version number
    SEAFILE_SERVER_VERSION=$(pacman -Qi seafile-server | awk -F ': ' '/Version/ {print $2}' | cut -d '-' -f 1)
    # As Seafile user: 
    # create Seafile server directory, cd into it, download Seahub, extract it and rename the extracted directory
    # then launch the initial setup
    su - seafile -s /bin/sh --command="mkdir -p /srv/seafile/${THEBOX_USER}/seafile-server && cd /srv/seafile/${THEBOX_USER} && wget -P seafile-server https://github.com/haiwen/seahub/archive/v${SEAFILE_SERVER_VERSION}-server.tar.gz && tar -xz -C seafile-server -f seafile-server/v${SEAFILE_SERVER_VERSION}-server.tar.gz && mv seafile-server/seahub-${SEAFILE_SERVER_VERSION}-server seafile-server/seahub && seafile-admin setup"
    # start systemd Seafile server service
    systemctl start "seafile-server@${THEBOX_USER}"
    # as Seafile user, cd into Seafile server directory and create an admin user 
    su - seafile -s /bin/sh --command="cd /srv/seafile/${THEBOX_USER} && seafile-admin create-admin"
    # Seafile is not enabled by default so we must stop the service 
    systemctl stop "seafile-server@${THEBOX_USER}"
}

# Cleaning process
process_clean(){
    # remove .builds directory? What about the updates?
    rm -rf "/home/${THEBOX_USER}/.builds"
}

# Start and enable systemd services
start_enable_services(){
    systemctl enable --now \
        nftables.service \
        dhcpcd@eth0.service \
        access-point.service \
        smb.service \
        nmb.service \
        ntpd.service \
        avahi-daemon.service \
        transmission.service \
        minidlna.service \
        mpd.service \
        ympd.service \
        theboxapi.service
}

# Send reboot signal
reboot(){
    systemctl reboot   
}

main(){
    # Initial setup
    logs_to_ram
    set_timezone
    set_hostname
    set_hosts
    set_locales

    # Users setup
    process_users
    
    # Configure RPI boot parameters
    rpi_boot_config
    
    # Install and update packages
    install_packages
    
    # Copy source config files 
    process_source_files
    
    # Packages installation
    install_minidlna
    install_ympd
    install_thebox_api
    install_thebox_sap
    install_seafile_server
    
    # Configuration
    config_samba
    config_mpd
    config_seafile_server
    
    # Cleaning
    #process_clean
    
    # Start and enable systemd services
    start_enable_services

    # Finishing
    reboot
}

# main "$@"
main