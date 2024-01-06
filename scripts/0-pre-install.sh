#!/bin/bash

usage(){
    echo -e "Usage: $0 [OPTIONS]\n"
    echo "Options:"
    echo "  -h, --help                Display this help message"
    echo "  --no-encrypt              Skip encryption"
    echo "  --non-uefi                Install in BIOS mode (non-UEFI)"
    echo "  --encryption-passwd PASS  Set the encryption password"
    echo "  -d, --disk DISK           Specify the target disk for installation"
    echo -e "\nExamples:"
    echo "  $0 --no-encrypt --disk /dev/sda"
}

ENCRYPTION_PASSWD=''
UEFI=true
ENCRYPT=true
DISK=''

# Set config
VALID_ARGS=$(getopt -o hd: --long help,no-encrypt,non-uefi,encryption-passwd:,disk: -- "$@")

if [[ $? -ne 0 ]]; then 
        exit 1;
fi 

eval set --  "$VALID_ARGS"

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
            *)  
                break 
                ;;
        esac
done

# Partition Disk 
echo 'Partitioning disk...'
if $UEFI && $ENCRYPT; then
    fdisk $DISK << EOF
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


# Format partitions
echo 'Formatting partitions...'
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


# Mount partitions
echo 'Mount partitions...'
if $ENCRYPT && $UEFI; then
    mount /dev/volgroup0/lv_root /mnt
    mkdir /mnt/boot
    mount ${DISK}2 /mnt/boot
    mkdir /mnt/home
    mount /dev/volgroup0/lv_home /mnt/home


# Setup fstab
echo 'Setup fstab...'
mkdir /mnt/etc
genfstab -U -p /mnt >> /mnt/etc/fstab
