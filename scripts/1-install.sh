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
    echo -e "Usage: $0 [OPTIONS]\n"
    echo "Options:"
    echo "  -h, --help                Display this help message"
    echo "  --no-encrypt              Skip encryption"
    echo "  --non-uefi                Install in BIOS mode (non-UEFI)"
    echo "  --root PASSWORD           Set the root password"
    echo "  --username USER           Set the username for the new user"
    echo "  --user-pwd PASSWORD       Set the password for the new user"
    echo -e "\nExamples:"
    echo "  $0 --no-encrypt --root myrootpwd --username user --user-pwd userpwd"
}

UEFI=true
ENCRYPT=true
ROOT_PWD=''
USERNAME=''
USER_PWD=''

VALID_ARGS=$(getopt -o hd: --long help,no-encrypt,non-uefi,disk:,root:,username:,user-pwd: -- '$@')

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
            --root)
                ROOT_PWD=$2  
                shift 2
                ;;
            --username)
                USERNAME=$2  
                shift 2
                ;;
            --user-pwd)
                USER_PWD=$2  
                shift 2
                ;;
            *)  
                break 
                ;;
        esac
done

# Install linux kernel
pacman -S --noconfirm --needed linux linux-headers linux-lts linux-lts-headers

# Install text editor
pacman -S --noconfirm --needed vim nano

# Install base packages
pacman -S --noconfirm --needed base-devel

# Install packages for network setup 
pacman -S --noconfirm --needed networkmanager wpa_supplicant wireless_tools netctl dhclient 
systemctl enable --now NetworkManager
pacman -S --noconfirm --needed dialog 

# Install lvm
pacman -S --noconfirm --needed lvm2

if $ENCRYPT; then
    sed -i 's/^HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck/' /etc/mkinitcpio.conf
fi
mkinitcpio -p linux 
mkinitcpio -p linux-lts 

# Config locale
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# Set root pwd and create user
if [ $(whoami) = "root" ]; then
    echo 'root:${ROOT_PWD}' | sudo chpasswd
    useradd -m -g users -G wheel ${USERNAME}
    echo '${USERNAME}:{USER_PWD}' | sudo chpasswd 
fi 

# Check if sudo is installed
if ! command -v sudo >/dev/null 2>&1; then
    pacman -S --noconfirm --needed sudo
fi

# Enable sudo commands without passwd
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL' /etc/sudoers.tmp 

