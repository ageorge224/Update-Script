#!/bin/bash

LOG_FILE="/tmp/remote_update.log"
SUMMARY_LOG="/tmp/remote_update_summary.log"
BACKUP_LOG_DIR="$HOME/Desktop"
BACKUP_LOG_FILE="$BACKUP_LOG_DIR/remote_update.log"
SUDO_ASKPASS_PATH="$HOME/sudo_askpass.sh"

# Export SUDO_ASKPASS
export SUDO_ASKPASS="$SUDO_ASKPASS_PATH"

# Function to log messages with color and timestamps in logs
log_message() {
    local color=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    case $color in
        red) color_code="\e[31m";;
        green) color_code="\e[32m";;
        yellow) color_code="\e[33m";;
        blue) color_code="\e[34m";;
        magenta) color_code="\e[35m";;
        cyan) color_code="\e[36m";;
        white) color_code="";;
        *) color_code="";;
    esac
    echo -e "${color_code}${message}\e[0m" | tee -a "$LOG_FILE"
}


# Function to handle errors
handle_error() {
    log_message red "Error on line $1: $2"
    exit 1
}

# Trap errors and signals
trap 'handle_error $LINENO "$BASH_COMMAND"' ERR
trap 'log_message red "Script terminated prematurely"; exit 1' SIGINT SIGTERM

# Backup log file if it exists
if [ -f "$LOG_FILE" ]; then
    log_message yellow "Backing up existing log file..."
    cp "$LOG_FILE" "$BACKUP_LOG_FILE"
fi

# Function to get system identification
get_system_identification() {
    { 
        echo -e "\n\e[36mSystem Identification:\e[0m"
        echo -e "\n"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Hostname:" "$(hostname)"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Operating System:" "$(lsb_release -d | cut -f2)"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Kernel Version:" "$(uname -r)"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "CPU Info:" "$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "GPU Info:" "$(lspci | grep -i vga | awk -F: '{print $3}' | xargs)"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Memory Info:" "$(free -h | grep 'Mem:' | awk '{print $2 " / " $3}')"
        
        echo -e "\e[36mDisk Info:\e[0m"
        echo -e "  \e[36mDrives:\e[0m"
        printf "  \e[36m%-20s %-20s %-10s\e[0m\n" "Device" "Model" "Size"
        lsblk -dn -o NAME,MODEL,SIZE | while IFS= read -r line; do
            name=$(echo "$line" | awk '{print $1}')
            model=$(echo "$line" | awk '{print $2}')
            size=$(echo "$line" | awk '{print $NF}')
            printf "  \e[32m%-20s %-20s %-10s\e[0m\n" "$name" "$model" "$size"
        done

        echo -e "\n"
    } || handle_error "get_system_identification" "$?"
}

# Run system identification
get_system_identification

# Function to perform remote update
perform_remote_update() {
    log_message blue "$(printf '\e[3mUpdating remote package list...\e[0m')"
    sudo -A apt-get update 2>&1 | tee -a "$LOG_FILE"

    log_message blue "$(printf '\e[3mUpgrading remote packages...\e[0m')"
    sudo -A apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"

    log_message blue "$(printf '\e[3mPerforming remote distribution upgrade...\e[0m')"
    sudo -A apt-get dist-upgrade -y 2>&1 | tee -a "$LOG_FILE"

    log_message blue "$(printf '\e[3mRemoving unnecessary remote packages...\e[0m')"
    sudo -A apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"

    log_message blue "$(printf '\e[3mCleaning up remote system...\e[0m')"
    sudo -A apt-get clean 2>&1 | tee -a "$LOG_FILE"

    log_message blue "$(printf '\e[3mUpdating Pi-hole...\e[0m')"
    sudo -A pihole -up 2>&1 | tee -a "$LOG_FILE"

    log_message blue "$(printf '\e[3mUpdating Pi-hole gravity (less verbose)...\e[0m')"
    sudo -A pihole -g > /tmp/pihole_gravity.log 2>&1
    if grep -q "FTL is listening" /tmp/pihole_gravity.log; then
        log_message green "Pi-hole gravity update completed successfully!"
    else
        log_message red "Pi-hole gravity update encountered an issue. Check /tmp/pihole_gravity.log for details."
        echo -e "Pi-hole gravity update encountered an issue" >> "$SUMMARY_LOG"
    fi
}

# Perform remote update
perform_remote_update
