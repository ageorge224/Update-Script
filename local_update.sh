#!/bin/bash

VERSION="1.0.20"
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

# Function to get log information
get_log_info() {
    echo -e "\n\e[36mLog Information:\e[0m"

    # Local Update Log
    local log_size
    log_size=$(du -h "$LOG_FILE" | cut -f1)
    printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Local Update Log:" "$log_size"
    printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Path:" "$LOG_FILE"

    # Backup Log File
    log_size=$(du -h "$BACKUP_LOG_FILE" | cut -f1)
    printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Backup Log File:" "$log_size"
    printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Path:" "$BACKUP_LOG_FILE"

    # Remote Update Script (Local)
    log_size=$(du -h "$REMOTE_SCRIPT_LOCAL" | cut -f1)
    printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Remote Update Script (Local):" "$log_size"
    printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Path:" "$REMOTE_SCRIPT_LOCAL"

    # Remote Update Script (Remote)
    log_size=$(du -h "$REMOTE_SCRIPT_REMOTE" | cut -f1)
    printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Remote Update Script (Remote):" "$log_size"
    printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Path:" "$REMOTE_SCRIPT_REMOTE"

    # Pi-hole Gravity Update Log
    PIHOLE_GRAVITY_LOG="/var/log/pihole/pihole_updateGravity.log"
    remote_gravity_log=$(ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $PIHOLE_GRAVITY_LOG && du -h $PIHOLE_GRAVITY_LOG || echo 'Not found'")
    if [[ $remote_gravity_log == *"Not found"* ]]; then
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Pi-hole Gravity Update Log:" "Not found"
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Path:" "N/A"
    else
        log_size=$(echo "$remote_gravity_log" | cut -f1)
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Pi-hole Gravity Update Log:" "$log_size"
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Path:" "$PIHOLE_GRAVITY_LOG"
    fi

    # Pi-hole FTL Log
    PIHOLE_FTL_LOG="/var/log/pihole/FTL.log"
    remote_ftl_log=$(ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $PIHOLE_FTL_LOG && du -h $PIHOLE_FTL_LOG || echo 'Not found'")
    if [[ $remote_ftl_log == *"Not found"* ]]; then
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Pi-hole FTL Log:" "Not found"
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Path:" "N/A"
    else
        log_size=$(echo "$remote_ftl_log" | cut -f1)
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Pi-hole FTL Log:" "$log_size"
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Path:" "$PIHOLE_FTL_LOG"
    fi

    # Pi-hole Log
    PIHOLE_LOG="/var/log/pihole/pihole.log"
    remote_pihole_log=$(ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $PIHOLE_LOG && du -h $PIHOLE_LOG || echo 'Not found'")
    if [[ $remote_pihole_log == *"Not found"* ]]; then
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Pi-hole Log:" "Not found"
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Path:" "N/A"
    else
        log_size=$(echo "$remote_pihole_log" | cut -f1)
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Pi-hole Log:" "$log_size"
        printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "Path:" "$PIHOLE_LOG"
    fi

    echo -e "\n"
}

# Function to handle errors
handle_error() {
    log_message red "Error on line $1: $2"
    exit 1
}

# Trap errors and signals
trap 'handle_error $LINENO "$BASH_COMMAND"' ERR
trap 'log_message red "Script terminated prematurely"; exit 1' SIGINT SIGTERM

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

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

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
    
    # Disk Info
    printf "\e[36m%-18s\e[0m \e[32m" "Disk Info:"
    df -h | grep '^/dev' | awk '{printf "%-30s (%s used)\n", $1, $3}' | while IFS= read -r line; do
        printf "%-18s\e[0m \e[32m%s\e[0m\n" "" "$line"
    done

    echo -e "\n"
}

# Run system identification
get_system_identification

# Call the log info function
get_log_info

# Function to backup the script
backup_script() {
    log_message yellow "Backing up script..."
    cp "$0" "$BACKUP_DIR/$(basename $0)_$(date +%Y%m%d%H%M%S).sh"
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
    
    # Disk Info
    printf "\e[36m%-18s\e[0m \e[32m" "Disk Info:"
    df -h | grep '^/dev' | awk '{printf "%-30s (%s used)\n", $1, $3}' | while IFS= read -r line; do
        printf "%-18s\e[0m \e[32m%s\e[0m\n" "" "$line"
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

# Append to changelog
log_message blue "Updating changelog..."
cat << EOF >> "$CHANGELOG_FILE"
[$(date +"%Y-%m-%d %H:%M:%S")] Script version $VERSION
- Added run log for current script execution.
- Improved error handling and output.
- Updated changelog functionality.
EOF
