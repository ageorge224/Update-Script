#!/bin/bash

VERSION="1.0.28"
SCRIPT_NAME="local_update.sh"
BACKUP_DIR="/home/ageorge/Documents/Backups"
CHANGELOG_FILE="$BACKUP_DIR/changelog.txt"
LOG_FILE="/tmp/local_update.log"
BACKUP_LOG_DIR="$HOME/Desktop"
BACKUP_LOG_FILE="$BACKUP_LOG_DIR/local_update.log"
REMOTE_USER="ageorge"
REMOTE_HOST="192.168.1.248"
REMOTE_SCRIPT_LOCAL="/tmp/remote_update.sh"
REMOTE_SCRIPT_REMOTE="/tmp/remote_update.sh"
SUDO_ASKPASS_PATH="$HOME/sudo_askpass.sh"
RUN_LOG="/tmp/run_log.txt"
CHECKSUM_FILE="/tmp/remote_update.sh.md5"

# Export SUDO_ASKPASS
export SUDO_ASKPASS="$SUDO_ASKPASS_PATH"

# Initialize RUN_LOG
> "$RUN_LOG"

# Function to log messages with color and timestamps in logs
log_message() {
    local color=$1
    local message=$2
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    case $color in
        red) echo -e "\e[31m $message\e[0m" | tee -a "$LOG_FILE" ;;
        green) echo -e "\e[32m $message\e[0m" | tee -a "$LOG_FILE" ;;
        yellow) echo -e "\e[33m $message\e[0m" | tee -a "$LOG_FILE" ;;
        blue) echo -e "\e[34m $message\e[0m" | tee -a "$LOG_FILE" ;;
        magenta) echo -e "\e[35m $message\e[0m" | tee -a "$LOG_FILE" ;;
        cyan) echo -e "\e[36m $message\e[0m" | tee -a "$LOG_FILE" ;;
        white) echo -e " $message" | tee -a "$LOG_FILE" ;;
        *) echo " $message" | tee -a "$LOG_FILE" ;;
    esac
}

# Function to get log information
get_log_info() {
    echo -e "\n\e[36mLog Information:\e[0m"

    # Local Update Log
    local log_size
    log_size=$(du -h "$LOG_FILE" | cut -f1)
    printf "   \e[32m✓\e[0m \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Local Update Log:" "$log_size"
    printf "   \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Path:" "$LOG_FILE"

    # Backup Log File
    log_size=$(du -h "$BACKUP_LOG_FILE" | cut -f1)
    printf "   \e[32m✓\e[0m \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Backup Log File:" "$log_size"
    printf "   \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Path:" "$BACKUP_LOG_FILE"

    # Remote Update Script (Local)
    log_size=$(du -h "$REMOTE_SCRIPT_LOCAL" | cut -f1)
    printf "   \e[32m✓\e[0m \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Remote Update Script (Local):" "$log_size"
    printf "   \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Path:" "$REMOTE_SCRIPT_LOCAL"

    # Remote Update Script (Remote)
    log_size=$(du -h "$REMOTE_SCRIPT_REMOTE" | cut -f1)
    printf "   \e[32m✓\e[0m \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Remote Update Script (Remote):" "$log_size"
    printf "   \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Path:" "$REMOTE_SCRIPT_REMOTE"

    # Pi-hole Gravity Update Log
    PIHOLE_GRAVITY_LOG="/var/log/pihole/pihole_updateGravity.log"
    remote_gravity_log=$(ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $PIHOLE_GRAVITY_LOG && du -h $PIHOLE_GRAVITY_LOG || echo 'Not Found'")
    if [[ $remote_gravity_log == *"Not Found"* ]]; then
        printf "   \e[31m✗\e[0m \e[36m%-30s\e[0m : \e[31mNot Found\e[0m\n" "Pi-hole Gravity Update Log:"
        printf "   \e[36m%-30s\e[0m : \e[31mN/A\e[0m\n" "Path:"
    else
        log_size=$(echo "$remote_gravity_log" | cut -f1)
        printf "   \e[32m✓\e[0m \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Pi-hole Gravity Update Log:" "$log_size"
        printf "   \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Path:" "$PIHOLE_GRAVITY_LOG"
    fi

    # Pi-hole FTL Log
    PIHOLE_FTL_LOG="/var/log/pihole/FTL.log"
    remote_ftl_log=$(ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $PIHOLE_FTL_LOG && du -h $PIHOLE_FTL_LOG || echo 'Not Found'")
    if [[ $remote_ftl_log == *"Not Found"* ]]; then
        printf "   \e[31m✗\e[0m \e[36m%-30s\e[0m : \e[31mNot Found\e[0m\n" "Pi-hole FTL Log:"
        printf "   \e[36m%-30s\e[0m : \e[31mN/A\e[0m\n" "Path:"
    else
        log_size=$(echo "$remote_ftl_log" | cut -f1)
        printf "   \e[32m✓\e[0m \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Pi-hole FTL Log:" "$log_size"
        printf "   \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Path:" "$PIHOLE_FTL_LOG"
    fi

    # Pi-hole Log
    PIHOLE_LOG="/var/log/pihole/pihole.log"
    remote_pihole_log=$(ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $PIHOLE_LOG && du -h $PIHOLE_LOG || echo 'Not Found'")
    if [[ $remote_pihole_log == *"Not Found"* ]]; then
        printf "   \e[31m✗\e[0m \e[36m%-30s\e[0m : \e[31mNot Found\e[0m\n" "Pi-hole Log:"
        printf "   \e[36m%-30s\e[0m : \e[31mN/A\e[0m\n" "Path:"
    else
        log_size=$(echo "$remote_pihole_log" | cut -f1)
        printf "   \e[32m✓\e[0m \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Pi-hole Log:" "$log_size"
        printf "   \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "Path:" "$PIHOLE_LOG"
    fi

    # Additional System Logs
    printf "\e[36m%-30s\e[0m\n" "Additional System Logs:"
    
    local logs=(
        "/var/log/auth.log"
        "/var/log/boot.log"
        "/var/log/dpkg.log"
        "/var/log/fail2ban.log"
        "/var/log/gpu-manager.log"
        "/var/log/kern.log"
        "/var/log/mintsystem.log"
        "/var/log/syslog"
    )

    for log in "${logs[@]}"; do
        if [ -f "$log" ]; then
            log_size=$(du -h "$log" | cut -f1)
            printf "   \e[32m✓\e[0m \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "$log" "$log_size"
        else
            printf "   \e[31m✗\e[0m \e[36m%-30s\e[0m : \e[31mNot Found\e[0m\n" "$log"
        fi
    done

    echo -e "\n"
}


# Trap errors and signals
trap 'handle_error $LINENO "$BASH_COMMAND"' ERR
trap 'log_message red "Script terminated prematurely"; exit 1' SIGINT SIGTERM

# Function to check the RUN_LOG for errors
check_run_log() {
    if [ -s "$RUN_LOG" ]; then
        log_message red "Errors were encountered during the script execution:"
        cat "$RUN_LOG"
    else
        log_message green "No errors detected during the script execution."
    fi
}

# Ensure checksum utility is available
if ! command -v md5sum &> /dev/null; then
    log_message red "md5sum is not installed. Please install it and try again."
    exit 1
fi

# Function to create and verify checksums
create_checksum() {
    md5sum "$REMOTE_SCRIPT_LOCAL" | awk '{ print $1 }' > "$CHECKSUM_FILE"
}

verify_checksum() {
    local remote_checksum
    ssh "$REMOTE_USER@$REMOTE_HOST" "md5sum $REMOTE_SCRIPT_REMOTE | awk '{ print \$1 }'" > /tmp/remote_checksum.txt
    remote_checksum=$(cat /tmp/remote_checksum.txt)
    local local_checksum
    local_checksum=$(cat "$CHECKSUM_FILE")

    if [ "$local_checksum" != "$remote_checksum" ]; then
        log_message red "Checksum mismatch! The script may have been altered."
        exit 1
    else
        log_message green "Checksum verification successful."
    fi
}

# Create checksum of the local script
create_checksum

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Ensure required commands are available
for cmd in apt-get ssh scp; do
    if ! command_exists "$cmd"; then
        log_message red "Error: $cmd is not installed."
        exit 1
    fi
done

# Announce the version
log_message cyan "Starting script version $VERSION"

# Backup log file if it exists
if [ -f "$LOG_FILE" ]; then
    log_message yellow "Backing up existing log file..."
    cp "$LOG_FILE" "$BACKUP_LOG_FILE"
fi

# Function to get system identification
get_system_identification() {
    echo -e "\n\e[36mSystem Identification:\e[0m"
    echo -e "\n"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Hostname:" "$(hostname)"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Operating System:" "$(lsb_release -d | cut -f2)"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Kernel Version:" "$(uname -r)"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "CPU Info:" "$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "GPU Info:" "$(lspci | grep -i vga | awk -F: '{print $3}' | xargs)"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Memory Info:" "$(free -h | grep 'Mem:' | awk '{print $2 " / " $3}')"
    
    # Disk Info formatted like inxi --disk output
    echo -e "\e[36mDisk Info:\e[0m"
    echo -e "  \e[36mDrives:\e[0m"
    echo -e "    \e[32mLocal Storage: total: $(df --total -h | grep 'total' | awk '{print $2}') used: $(df --total -h | grep 'total' | awk '{print $3}') ($(df --total -h | grep 'total' | awk '{print $5}') used)\e[0m"

    lsblk -dn -o NAME,MODEL,SIZE | while IFS= read -r line; do
        name=$(echo $line | awk '{print $1}')
        model=$(echo $line | awk '{print $2}')
        size=$(echo $line | awk '{print $NF}')
        echo -e "    \e[32mID-1: /dev/$name vendor: $model size: $size\e[0m"
    done

    echo -e "\n"
}

# Run system identification
get_system_identification

# Call the log info function
get_log_info

# Function to backup the script only if it's changed
backup_script() {
    log_message yellow "Backing up script..."
    
    # Get the latest backup file if it exists
    latest_backup=$(ls -t "$BACKUP_DIR/$(basename "$0")_"*.sh 2>/dev/null | head -n 1)
    
    # Compare the current script with the latest backup
    if [ -f "$latest_backup" ] && cmp -s "$0" "$latest_backup"; then
        log_message green "No changes detected. Backup not needed."
    else
        cp "$0" "$BACKUP_DIR/$(basename "$0")_$(date +%Y%m%d%H%M%S).sh"
        log_message green "Script backed up successfully."
    fi
}

# Backup the script
backup_script


# Function to perform local update
perform_local_update() {
    log_message blue "$(printf '\e[3mUpdating package list...\e[0m')"
    sudo -A apt-get update 2>&1 | tee -a "$LOG_FILE"

    log_message blue "$(printf '\e[3mUpgrading packages...\e[0m')"
    sudo -A apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"

    log_message blue "$(printf '\e[3mPerforming distribution upgrade...\e[0m')"
    sudo -A apt-get dist-upgrade -y 2>&1 | tee -a "$LOG_FILE"

    log_message blue "$(printf '\e[3mRemoving unnecessary packages...\e[0m')"
    sudo -A apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"

    log_message blue "$(printf '\e[3mCleaning up...\e[0m')"
    sudo -A apt-get clean 2>&1 | tee -a "$LOG_FILE"
}

# Perform local update
perform_local_update

# Function to create remote update script
create_remote_script() {
    cat << 'EOF' > "$REMOTE_SCRIPT_LOCAL"
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
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    case $color in
        red) echo -e "\e[31m $message\e[0m" | tee -a "$LOG_FILE" ;;
        green) echo -e "\e[32m $message\e[0m" | tee -a "$LOG_FILE" ;;
        yellow) echo -e "\e[33m $message\e[0m" | tee -a "$LOG_FILE" ;;
        blue) echo -e "\e[34m $message\e[0m" | tee -a "$LOG_FILE" ;;
        magenta) echo -e "\e[35m $message\e[0m" | tee -a "$LOG_FILE" ;;
        cyan) echo -e "\e[36m $message\e[0m" | tee -a "$LOG_FILE" ;;
        white) echo -e "\e[37m $message\e[0m" | tee -a "$LOG_FILE" ;;
        *) echo " $message" | tee -a "$LOG_FILE" ;;
    esac
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
    echo -e "\n\e[36mSystem Identification:\e[0m"
    echo -e "\n"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Hostname:" "$(hostname)"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Operating System:" "$(lsb_release -d | cut -f2)"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Kernel Version:" "$(uname -r)"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "CPU Info:" "$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "GPU Info:" "$(lspci | grep -i vga | awk -F: '{print $3}' | xargs)"
    printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Memory Info:" "$(free -h | grep 'Mem:' | awk '{print $2 " / " $3}')"
    
    # Disk Info formatted like inxi --disk output
    echo -e "\e[36mDisk Info:\e[0m"
    echo -e "  \e[36mDrives:\e[0m"
    echo -e "    \e[32mLocal Storage: total: $(df --total -h | grep 'total' | awk '{print $2}') used: $(df --total -h | grep 'total' | awk '{print $3}') ($(df --total -h | grep 'total' | awk '{print $5}') used)\e[0m"

    lsblk -dn -o NAME,MODEL,SIZE | while IFS= read -r line; do
        name=$(echo $line | awk '{print $1}')
        model=$(echo $line | awk '{print $2}')
        size=$(echo $line | awk '{print $NF}')
        echo -e "    \e[32mID-1: /dev/$name vendor: $model size: $size\e[0m"
    done

    echo -e "\n"
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

log_message cyan "Remote script completed."
EOF

    chmod +x "$REMOTE_SCRIPT_LOCAL"
}

# Create remote script
create_remote_script

# Copy the script to the remote server
log_message blue "$(printf '\e[3mCopying script to remote server...\e[0m')"
scp "$REMOTE_SCRIPT_LOCAL" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SCRIPT_REMOTE"

# Verify the checksum on the remote server
log_message blue "$(printf '\e[3mVerifying script checksum on remote server...\e[0m')"
verify_checksum

# Run the script on the remote server
log_message blue "$(printf '\e[3mExecuting remote update script...\e[0m')"
ssh "$REMOTE_USER@$REMOTE_HOST" "$REMOTE_SCRIPT_REMOTE"

# Retrieve remote log
log_message blue "$(printf '\e[3mRetrieving remote log file...\e[0m')"
scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SCRIPT_REMOTE" "$BACKUP_LOG_FILE"

log_message cyan "Remote system updated successfully. Check log at $BACKUP_LOG_FILE"

# Final log and backup
log_message green "Creating backups..."
cp "$LOG_FILE" "$BACKUP_DIR/$(basename $LOG_FILE)_$(date +%Y%m%d%H%M%S).log"
cp "$LOG_FILE" "$BACKUP_LOG_FILE"

log_message cyan "Update process completed successfully!"

# Append to changelog if version is new
log_message blue "Checking for new version..."

LAST_LOGGED_VERSION=$(grep -oP '(?<=Script version )\S+' "$CHANGELOG_FILE" | tail -1)

if [ "$VERSION" != "$LAST_LOGGED_VERSION" ]; then
    log_message blue "Updating changelog..."
    cat << EOF >> "$CHANGELOG_FILE"
[$(date +"%Y-%m-%d %H:%M:%S")] Script version $VERSION
- Changed Disk Info output to better align and color.
- Added to the script backup function a check if file same.
EOF
else
    log_message blue "Version $VERSION is already logged. No changes made to changelog."
fi

# Check for errors
check_run_log

