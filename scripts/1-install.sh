#!/bin/bash

ENCRYPT=true

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
if [ $(whoami) = 'root' ]; then
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

