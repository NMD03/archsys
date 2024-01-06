#!/bin/bash

setDefault(){
    ENCRYPTION_PASSWD=''
    UEFI=true
    ENCRYPT=true
    DISK=''
    ROOT_PWD=''
    USERNAME=''
    USER_PWD=''
    DESKTOP_ENVS=('kde')
}

usage(){
    echo -e "Usage: $0 [OPTIONS]\n"
    echo "Options:"
    echo "  -h, --help                Display this help message"
    echo "  --no-encrypt              Skip encryption"
    echo "  --non-uefi                Install in BIOS mode (non-UEFI)"
    echo "  --encryption-passwd PASS  Set the encryption password"
    echo "  -d, --disk DISK           Specify the target disk for installation"
    echo "  --desktop ENV             Specify desktop environment(s) (e.g., --desktop kde)"
    echo "  --root PASSWORD           Set the root password"
    echo "  --username USER           Set the username for the new user"
    echo "  --user-pwd PASSWORD       Set the password for the new user"
    echo -e "\nExamples:"
    echo "  $0 --no-encrypt --disk /dev/sda --desktop kde --root myrootpwd --username user --user-pwd userpwd"
}

checkInternetConnection(){
    if ! ping -c 1 archlinux.org &> /dev/null
    then
        echo "Error: Network is not connected. Please check your network connection."
        exit 1
    fi 
}

checkConfig(){
    echo 'TODO'
}

interactiveConfig(){
    echo "TODO"
    usage
    exit 0
}

nonInteractiveConfig(){
    VALID_ARGS=$(getopt -o hd: --long help,no-encrypt,non-uefi,encryption-passwd:,disk:,desktop:,root:,username:,user-pwd: -- "$@")

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
                --desktop)
                    shift
                    while [ $# -gt 0 ] && ! [[ $1 == -* ]]; do
                        DESKTOP_ENVS+=("$1")
                        shift
                    done
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
}

# -- Main -- 
if [ -z "$1" ]; then
    usage
    exit 0
fi
checkInternetConnection

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
    nonInteractiveConfig "$@"
fi
checkConfig

# Run scripts
# add non args -> config file
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
( bash $SCRIPT_DIR/scripts/0-pre-install.sh --encryption-passwd $ENCRYPTION_PASSWD -d $DISK)|& tee 0-pre-install.log
cp -r $HOME/archsys /mnt/root
chmod +x /mnt/root/archsys/scripts/*.sh
( arch-chroot /mnt $HOME/archsys/scripts/1-install.sh --root $ROOT_PWD --username $USERNAME --user-pwd $USER_PWD)|& tee 1-install.log
( arch-chroot /mnt $HOME/archsys/scripts/2-post-install.sh --desktop $DESKTOP_ENVS)|& tee 2-post-install.log
( arch-chroot /mnt $HOME/archsys/scripts/3-cleanup.sh )|& tee 3-cleanup.log
