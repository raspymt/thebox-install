#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

THEBOX_HOSTNAME='thebox'
THEBOX_USER='thebox'
THEBOX_TIMEZONE='Asia/Ho_Chi_Minh'

# Helpers

# install package from AUR
# $1 - the name of the package
# $2 - the url of the package
install_aur_package(){
    runuser --command="cd /home/${THEBOX_USER}/.builds && rm -rf ${1} && git clone ${2} ${1} && cd ${1} && makepkg --clean" --login $THEBOX_USER
    # install package
    pacman --upgrade --noconfirm /home/$THEBOX_USER/.builds/$1/$1*.pkg.tar.xz
}

config_hostname(){
  read -p "New hostname: " THEBOX_HOSTNAME
}
config_user(){
  read -p "New username: " THEBOX_USER
}
config_timezone(){
  read -p "New timezone: " THEBOX_TIMEZONE
}

# Change hostname, user and timezone
change_default_variables(){
    while true; do
        read -p "Hostname is set to ${THEBOX_HOSTNAME}. Do you want to change it (y/n)?" yn
        case $yn in
            y ) config_hostname; break;;
            n ) break;;
        esac
    done
    while true; do
        read -p "User is set to ${THEBOX_USER}. Do you want to change it (y/n)?" yn
        case $yn in
            y ) config_user; break;;
            n ) break;;
        esac
    done
    while true; do
        read -p "Timezone is set to ${THEBOX_TIMEZONE}. Do you want to change it (y/n)?" yn
        case $yn in
            y ) config_timezone; break;;
            n ) break;;
        esac
    done
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
    hostnamectl set-hostname $THEBOX_HOSTNAME    
}

# Set hosts
set_hosts(){
    echo "127.0.0.1 localhost.localdomain localhost" > /etc/hosts
    echo "::1 localhost.localdomain localhost" >> /etc/hosts
    echo "127.0.0.1 ${THEBOX_HOSTNAME}.localdomain ${THEBOX_HOSTNAME}" >> /etc/hosts
    echo "::1 ${THEBOX_HOSTNAME}.localdomain ${THEBOX_HOSTNAME}" >> /etc/hosts    
    echo "10.0.0.1 ${THEBOX_HOSTNAME}.localdomain ${THEBOX_HOSTNAME}" >> /etc/hosts    
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
    useradd --create-home $THEBOX_USER
    # ask for thebox user password
    echo "Enter ${$THEBOX_USER} user password:"
    passwd $THEBOX_USER

    # add theboxapi system user
    useradd --system --home-dir "/home/${THEBOX_USER}" --groups thebox,wheel theboxapi
}

# Set raspberry pi 3 b boot config
rpi_boot_config(){
    # enable onboard soundcard
    echo 'dtparam=audio=on' >> /boot/config.txt
    # remove distortion using the 3.5mm analogue output
    echo 'audio_pwm_mode=2' >> /boot/config.txt
    # enable the 1.2A current limiter
    #echo 'max_usb_current=1' >> /boot/config.txt
    # disable rainbow splash screen on boot
    echo 'disable_splash=1' >> /boot/config.txt
    # set GPU RAM to minimum (16 MB)
    sed -i 's/gpu_mem=64/gpu_mem=16/' /boot/config.txt
}

# Upgrade and install necessary packages
install_packages(){
    pacman --sync --refresh --sysupgrade --disable-download-timeout --noconfirm \
        alsa-utils \
        avahi \
        base-devel \
        cmake \
        create_ap \
        dhclient \
        dnsmasq \
        ffmpeg \
        flac \
        git \
        libexif \
        libid3tag \
        libjpeg \
        libvorbis \
        mpd \
        nftables \
        nodejs-lts-carbon \
        npm \
        nss-mdns \
        ntfs-3g \
        ntp \
        samba \
        sqlite \
        sudo \
        syncthing \
        transmission-cli \
        wget
}

# Copy sources files, create necessary directories, set main user directory permissions
# reload systemd daemon and reload udev rules 
process_source_files(){
    # copy source files
    cp --recursive --force root/etc/* /etc/
    cp --recursive --force root/usr/* /usr/
    cp --recursive --force root/home/thebox/* "/home/${THEBOX_USER}/"
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
    install_aur_package "thebox-minidlna" "https://github.com/raspymt/thebox-minidlna.git"
    # change default DLNA server name
    sed -i 's/#friendly_name=My DLNA Server/friendly_name=The Box DLNA Server/' /etc/minidlna.conf
    # change network interface
    sed -i 's/#network_interface=eth0/network_interface=bond0,uap0/' /etc/minidlna.conf
    # disable logs
    sed -i 's/#log_level=general,artwork,database,inotify,scanner,metadata,http,ssdp,tivo=warn/log_level=general=off,artwork=off,database=off,inotify=off,scanner=off,metadata=off,http=off,ssdp=off,tivo=off/' /etc/minidlna.conf
    # change default media dir
    sed -i 's/media_dir=\/opt/media_dir=\/media/' /etc/minidlna.conf
}

# Install Resilio Sync
install_rslsync(){
    install_aur_package "rslsync" "https://aur.archlinux.org/rslsync.git"
}

# Install YMPD
install_ympd(){
    install_aur_package "ympd" "https://aur.archlinux.org/ympd.git"
}

# Install The Box API
install_thebox_api(){
    # clone repository thebox-api, install NPM packages for production and build sqlite3 from source
    runuser --command="cd /home/${THEBOX_USER}/.thebox && git clone https://github.com/raspymt/thebox-api.git && cd thebox-api && npm install --production --build-from-source --sqlite=/usr/include" --login $THEBOX_USER
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
    # change netbios name
    sed -i "s/netbios name = thebox/netbios name = ${THEBOX_HOSTNAME}/" /etc/samba/smb.conf
}

# Syncthing configuration
config_syncthing(){
    systemctl start "syncthing@${THEBOX_USER}.service" && systemctl stop "syncthing@${THEBOX_USER}.service" && sed -i 's/127.0.0.1:8384/0.0.0.0:8384/' "/home/${THEBOX_USER}/.config/syncthing/config.xml"
}

# SSH configuration
config_ssh(){
    echo "Port 4622" >> /etc/ssh/sshd_config
}

# MPD configuration
config_mpd(){
    sed -i "s/\"thebox\"/\"${THEBOX_USER}\"/" /etc/mpd.conf
    sed -i "s/thebox/${THEBOX_USER}/" /usr/lib/systemd/system/mpd.service.d/override.conf
}

# dhclient configuration
config_dhclient(){
    sed -i "s/thebox/${THEBOX_HOSTNAME}/" /etc/dhclient.conf
}

# The Box API configuration
config_thebox_api(){
    sed -i "s/\/home\/thebox/\/home\/${THEBOX_USER}/" /etc/systemd/system/theboxapi.service
}

# Configure sudoers
config_sudoers(){
    sed -i "s/thebox=/${THEBOX_USER}=/" /etc/sudoers.d/theboxapi
}

# Configure Resilio Sync
config_rslsync(){
    sed -i "s/thebox/${THEBOX_USER}/" /usr/lib/systemd/system/rslsync.service.d/override.conf
    sed -i "s/thebox/${THEBOX_USER}/" "/home/${THEBOX_USER}/.config/rslsync/rslsync.conf"
}

# Configure Transmission
config_transmission(){
    sed -i "s/thebox/${THEBOX_USER}/" /usr/lib/systemd/system/transmission.service.d/override.conf

    sed -i "s/thebox\/Downloads/${THEBOX_USER}\/Downloads/" "/home/${THEBOX_USER}/.config/transmission-daemon/settings.json"
}

# Configure usb-mount.sh
config_usb_mount_script(){
    sed -i "s/thebox/${THEBOX_USER}/" /usr/local/bin/usb-mount.sh
}

# Create_ap script configuration
config_create_ap(){
    echo 'CHANNEL=6
GATEWAY=10.0.0.1
WPA_VERSION=2
ETC_HOSTS=1
DHCP_DNS=gateway
NO_DNS=0
HIDDEN=0
MAC_FILTER=0
MAC_FILTER_ACCEPT=/etc/hostapd/hostapd.accept
ISOLATE_CLIENTS=0
SHARE_METHOD=nat
IEEE80211N=1
IEEE80211AC=0
HT_CAPAB=[HT40][SHORT-GI-20][DSSS_CCK-40]
VHT_CAPAB=
DRIVER=nl80211
NO_VIRT=1
COUNTRY=
FREQ_BAND=2.4
NEW_MACADDR=
DAEMONIZE=1
NO_HAVEGED=0
WIFI_IFACE=uap0
INTERNET_IFACE=bond0
SSID=thebox
PASSPHRASE=theboxap
USE_PSK=0' > /etc/create_ap.conf
}

# WIFI network configuration
config_wifi_network(){
  read -p "Enter WIFI SSID: " WIFI_SSID
  read -p "Enter WIFI password: " WIFI_PWD

  wpa_passphrase "${WIFI_SSID}" "${WIFI_PWD}" | grep -E $'network={|}|\tssid|\tpsk' >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
}

config_wifi(){
    while true; do
        read -p "Do you want to configure a WIFI network (y/n)?" yn
        case $yn in
            y ) config_wifi_network; break;;
            n ) break;;
        esac
    done
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

    # disable systemd-networkd-wait-online, systemd-networkd and systemd-resolved services
    systemctl disable \
        systemd-networkd-wait-online.service \
        systemd-networkd.service systemd-networkd.socket \
        systemd-resolved.service

    # enable default services
    systemctl enable \
        avahi-daemon.service \
        create_ap \
        dnsmasq.service \
        nftables.service \
        minidlna.service \
        mpd.service \
        nmb.service \
        ntpd.service \
        smb.service \
        theboxapi.service \
        transmission.service \
        virtual_ap.service

    # Wireless bonding (see: https://wiki.archlinux.org/index.php/Wireless_bonding)
    ln /etc/systemd/system/slave@.service /etc/systemd/system/eth0@.service
    ln /etc/systemd/system/slave@.service /etc/systemd/system/wlan0@.service

    systemctl enable supplicant@wlan0
    systemctl enable eth0@bond0 wlan0@bond0 master@bond0
    systemctl enable dhclientbond@bond0

    # dnsmasq need to be started to create a new /etc/resolv.conf file
    systemctl start dnsmasq.service
}

# Send reboot signal
reboot(){
    systemctl reboot   
}


main(){
    # Change default variables if needed
    change_default_variables

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
    config_syncthing
    config_rslsync
    config_ssh
    config_sudoers
    config_mpd
    config_transmission
    config_dhclient
    config_thebox_api
    config_create_ap
    config_usb_mount_script
    config_wifi

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