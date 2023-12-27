#!/bin/bash

# Define ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

setVars(){

}

setDefault(){
    ENCRYPTION_PASSWD=''
    DESKTOP_ENVS=('dwm' 'kde')
    UEFI=true
    ENCRYPT=true
    DISK=''
}

error(){
    local msg=$1
    echo '${RED}Error: ${msg}${NC}'
}

warn(){
    local msg=$1
    echo '${YELLOW}Warning: ${msg}${NC}'
}

okay(){
    local msg=$1
    echo '${GREEN}Okay: ${msg}${NC}'
}

info(){
    local msg=$1
    echo '${BLUE}Info: ${msg}${NC}'
}

usage(){

}

checkInternetConnection(){
    if ! ping -c 1 archlinux.org &> /dev/null
    then
        error "Network is not connected. Please check your network connection."
        exit 1
    fi 
}

partitionDisk(){
    info 'Partitioning disk...'
    if $UEFI && $ENCRYPT; then
        fdisk << EOF
g
n


+500M
t 
1
n


+500M
n



t 

44
w
EOF
    fi
}

formatPartitions(){
    info 'Formatting partitions...'
    if $ENCRYPT && $UEFI; then
        mkfs.fat -F32 ${DISK}1
        mkfs.ext4 ${DISK}2 
        cryptsetup luksFormat ${DISK}3 << EOF
YES
$ENCRYPTION_PASSWD
$ENCRYPTION_PASSWD
EOF
        echo -n $ENCRYPTION_PASSWD | cryptsetup open --type ${DISK}3 lvm
        pvcreate --dataalignment 1m /dev/mapper/lvm
        vgcreate volgroup0 /dev/mapper/lvm
        lvcreate -L 30GB volgroup0 -n lv_root
        lvcreate -l 100%FREE volgroup0 -n lv_home
        modprobe dm_mod
        vgscan
        vgchange -ay
        mkfs.ext4 /dev/volgroup0/lv_root
        mkfs.ext4 /dev/volgroup0/lv_home
    fi    
}

mountFilesystems(){
    info 'Mount partitions...'
    if $ENCRYPT && $UEFI; then
        mount /dev/volgroup0/lv_root /mnt
        mkdir /mnt/boot
        mount ${DISK}2 /mnt/boot
        mkdir /mnt/home
        mount /dev/volgroup0/lv_home /mnt/home
}

setupFstab(){
    info 'Setup fstab...'
    mkdir /mnt/etc
    genfstab -U -p /mnt >> /mnt/etc/fstab
}

installArch(){

}

setupBoot(){

}

installPackages(){

}

checkConfig(){

}

interactiveConfig(){

}

nonInteractiveConfig(){
    VALID_ARGS=$(getopt -o hd: --long help,no-encrypt,non-uefi,encryption-passwd:,disk: -- '$@')

    if [[ $? -ne 0 ]]; then 
            exit 1;
    fi 

    eval set --  '$VALID_ARGS'

    while [ $# -gt 0 ]; do
            case "$1" in
                -h | --help)
                    usage
                    exit 0
                    shift 
                    ;;
                --no-encrypt)
                    ENCRYPT=false
                    shift 
                    ;;
                --non-uefi)
                    UEFI=false
                    shift 
                    ;;
                --encryption-passwd)
                    ENCRYPTION_PASSWD=$2
                    shift 2 
                    ;;
                -d | --disk)
                    DISK=$2  
                    shift 2 
                    ;;
            esac
    done
}

# -- Main -- 
if [ -z '$1' ]; then
    usage
    exit 0
fi

# Check for interactive installation
interactive=false
for arg in "$@"; do
    if [[ $arg == "-i" ]] || [[ $arg == "--interactive" ]]; then
        interactive=true
        break
    fi
done
if $interactive; then
    interactiveConfig
else
    nonInteractiveConfig '$@'
fi
checkConfig

checkInternetConnection

