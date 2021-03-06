#!/usr/bin/env bash
# If you are executing this script in cron with a restricted environment,
# modify the shebang to specify appropriate path; /bin/bash in most distros.
# And, also if you aren't comfortable using(abuse?) env command.

# This script is based on https://serverfault.com/a/767079 posted
# by Mike Blackwell, modified to our needs. Credits to the author.

# This script is called from systemd unit file to mount or unmount
# a USB drive.

PATH="$PATH:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:/bin:/sbin"
log="logger -t usb-mount.sh -s "

usage()
{
    ${log} "Usage: $0 {add|remove} device_name (e.g. sdb1)"
    exit 1
}

if [[ $# -ne 2 ]]; then
    usage
fi

ACTION=$1
DEVBASE=$2
DEVICE="/dev/${DEVBASE}"

# See if this drive is already mounted, and if so where
MOUNT_POINT=$(mount | grep ${DEVICE} | awk '{ print $3 }')

DEV_LABEL=""

do_mount()
{
    if [[ -n ${MOUNT_POINT} ]]; then
        ${log} "Warning: ${DEVICE} is already mounted at ${MOUNT_POINT}"
        exit 1
    fi

    # Get info for this drive: $ID_FS_LABEL, $ID_FS_UUID, and $ID_FS_TYPE
    eval $(blkid -o udev ${DEVICE})

    # Figure out a mount point to use
    LABEL=${ID_FS_LABEL}
    if grep -q " /media/${LABEL} " /etc/mtab; then
        # Already in use, make a unique one
        LABEL+="-${DEVBASE}"
    fi
    DEV_LABEL="${LABEL}"

    # Use the device name in case the drive doesn't have label
    if [ -z ${DEV_LABEL} ]; then
        DEV_LABEL="${DEVBASE}"
    fi

    MOUNT_POINT="/media/${DEV_LABEL}"

    ${log} "Mount point: ${MOUNT_POINT}, filesystem: ${ID_FS_TYPE}"

    mkdir -p ${MOUNT_POINT}

    # Global mount options
    OPTS="rw,relatime"

    # File system type specific mount options
    if [[ ${ID_FS_TYPE} == "vfat" ]]; then
        OPTS+=",users,gid=nobody,umask=000,shortname=mixed,utf8=1,flush"
    fi

    if ! mount -o ${OPTS} ${DEVICE} ${MOUNT_POINT}; then
        ${log} "Error mounting ${DEVICE} (status = $?)"
        rmdir "${MOUNT_POINT}"
        exit 1
    else
        # Track the mounted drives
        echo "${MOUNT_POINT}:${DEVBASE}" | cat >> "/var/log/usb-mount.track" 
        if [[ ${ID_FS_TYPE} == "ext2" ]] || [[ ${ID_FS_TYPE} == "ext3" ]] || [[ ${ID_FS_TYPE} == "ext4" ]]; then
            # chown thebox ${MOUNT_POINT}
            chgrp thebox ${MOUNT_POINT}
            chmod g+w ${MOUNT_POINT}
        fi
        # Add SAMBA usershare
        ${log} "Created usershare on ${MOUNT_POINT}"
        ACLS=$(pdbedit -L -v | sed -n -e 's/User SID:             //p')
        net usershare add ${DEV_LABEL} ${MOUNT_POINT} "The Box Network share ${DEV_LABEL}" ${ACLS}:F
    fi

    ${log} "Mounted ${DEVICE} at ${MOUNT_POINT} with filesystem ${ID_FS_TYPE}"
}

do_unmount()
{
    if [[ -z ${MOUNT_POINT} ]]; then
        ${log} "Warning: ${DEVICE} is not mounted"
    else
        # Delete SAMBA usershare
        USERSHARE=${MOUNT_POINT##*/}
        net usershare delete ${USERSHARE,,}
        ${log} "Deleted usershare on ${MOUNT_POINT}"
        # Unmount device
        umount -l ${DEVICE}
        ${log} "Unmounted ${DEVICE} from ${MOUNT_POINT}"
        /bin/rmdir "${MOUNT_POINT}"
        sed -i.bak "\@${MOUNT_POINT}@d" /var/log/usb-mount.track
    fi


}

case "${ACTION}" in
    add)
        do_mount
        ;;
    remove)
        do_unmount
        ;;
    *)
        usage
        ;;
esac