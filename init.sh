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

# Helpers

# install package from AUR
# $1 - the name of the package
# $2 - the url of the package
install_aur_package(){
    runuser --command="cd /home/${THEBOX_USER}/.builds && git clone ${2} ${1} && cd ${1} && makepkg" --login $THEBOX_USER
    # install package
    pacman --upgrade --noconfirm /home/$THEBOX_USER/.builds/$1/$1*.pkg.tar.xz
}

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
}

# Set raspberry pi 3 b boot config
rpi_boot_config(){
    # enable onboard soundcard
    echo 'dtparam=audio=on' >> /boot/config.txt
    # remove distortion using the 3.5mm analogue output
    echo 'audio_pwm_mode=2' >> /boot/config.txt
    # set GPU RAM to minimum (16 MB)
    echo 'gpu_mem=16' >> /boot/config.txt
    # sed -i 's/gpu_mem=64/gpu_mem=16/' /boot/config.txt
}

# Upgrade and install necessary packages
install_packages(){
    pacman -Syu --noconfirm \
        alsa-utils \
        avahi \
        base-devel \
        git \
        hostapd \
        mpd \
        nftables \
        nodejs-lts-carbon \
        npm \
        nss-mdns \
        ntfs-3g \
        ntp \
        openssl \
        samba \
        sqlite \
        transmission-cli \
        wget \
        syncthing \
        libexif \
        libjpeg \
        libid3tag \
        flac \
        libvorbis \
        ffmpeg \
        cmake
        #sudo \
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
    mkdir -p "/home/${THEBOX_USER}/.sync"
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
    cd "/home/${THEBOX_USER}/.builds/thebox-minidlna" && pacman --upgrade --noconfirm thebox-minidlna*.pkg.tar.xz && cd $OLDPWD
    # change default DLNA server name
    sed -i 's/#friendly_name=My DLNA Server/friendly_name=The Box DLNA Server/' /etc/minidlna.conf
    # disable logs
    sed -i 's/#log_level=general,artwork,database,inotify,scanner,metadata,http,ssdp,tivo=warn/log_level=general=off,artwork=off,database=off,inotify=off,scanner=off,metadata=off,http=off,ssdp=off,tivo=off/' /etc/minidlna.conf
    # change default media dir
    sed -i 's/media_dir=\/opt/media_dir=\/media/' /etc/minidlna.conf
    # launch a database rebuild
    /usr/bin/minidlnad -R
}

# Install Resilio Sync
install_rslsync(){
    runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/rslsync.git && cd rslsync && makepkg" --login $THEBOX_USER
    # install package
    cd "/home/${THEBOX_USER}/.builds/rslsync" && pacman --upgrade --noconfirm rslsync*.pkg.tar.xz && cd $OLDPWD    
}

# Install YMPD
install_ympd(){
    runuser --command="cd /home/${THEBOX_USER}/.builds && git clone https://aur.archlinux.org/ympd.git && cd ympd && makepkg --ignorearch" --login $THEBOX_USER
    # install package
    cd "/home/${THEBOX_USER}/.builds/ympd" && pacman --upgrade --noconfirm ympd*.pkg.tar.xz && cd $OLDPWD    
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

# SSH config
process_ssh(){
    echo "Port 4622" >> /etc/ssh/sshd_config
}

# Add supplementary groups for thebox user
add_user_groups(){
    usermod -a -G audio,transmission $THEBOX_USER
}

# Cleaning process
process_clean(){
    # remove .builds directory
    rm -rf "/home/${THEBOX_USER}/.builds"
    # remove alarm user
    userdel --force --remove alarm    
}

# Start and enable systemd services
start_enable_services(){
    # reload services
    systemctl daemon-reload
    # enable default services
    systemctl enable \
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
    install_rslsync
    install_ympd
    install_thebox_api
    install_thebox_sap
    
    # Configuration
    config_samba

    # SSH config
    process_ssh

    # Supplemantary groups
    add_user_groups
    
    # Cleaning
    process_clean
    
    # Start and enable systemd services
    start_enable_services

    # Finishing
    reboot
}

# main "$@"
main