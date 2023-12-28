#!/bin/bash

# Installing GRUB
if $UEFI; then 
    pacman -S --noconfirm --needed grub dosfstools os-prober mtools efibootmgr
    mkdir /boot/EFI
    mount ${DISK}1 /boot/EFI
    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
fi

if [ ! -d /boot/grub/locale ]; then
    mkdir /boot/grub/locale 
fi
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo 

if $UEFI && $ENCRYPT; then
    sed -i 's/^#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y'
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=${DISK}3:volgroup0:allow-discards loglevel=3 quiet"'
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Setup swap
dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
chmod 600 /swapfile
mkswap /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab 
mount -a
swapon -a

# Set timezone
timedatectl set-timezone Europe/Berlin
systemctl enable systemd-timesyncd

# Set hostname
hostnamectl set-hostname archsys

# Install microcode
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type}; then
    echo "Installing Intel microcode"
    pacman -S --noconfirm --needed intel-ucode
elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    echo "Installing AMD microcode"
    pacman -S --noconfirm --needed amd-ucode
fi

# Install xorg
pacman -S --noconfirm --needed xorg-server

# Install video driver
gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed nvidia nvidia-lts
	nvidia-xconfig
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacman -S --noconfirm --needed xf86-video-amdgpu
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacman -S --needed --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
fi 
# ATTENTION FOR VBOX OTHER DRIVER!!!

# Install desktop environmen

