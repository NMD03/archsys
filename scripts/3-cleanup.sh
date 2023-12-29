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

# Remove rights without passwd
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers