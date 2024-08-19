#!/bin/bash

VERSION="1.1.06"
SCRIPT_NAME="local_update.sh"
REMOTE_USER="ageorge"
REMOTE_HOST="192.168.1.248"
BACKUP_DIR="/home/ageorge/Documents/Backups"
REMOTE_LOG="/home/ageorge/Desktop/remote_update.log"
CHANGELOG_FILE="$BACKUP_DIR/changelog.txt"
LOG_FILE="/tmp/local_update.log"
BACKUP_LOG_DIR="$HOME/Desktop"
BACKUP_REMOTE_LOG="$BACKUP_LOG_DIR/remote_update.log"
BACKUP_LOG_FILE="$BACKUP_LOG_DIR/local_update.log"
REMOTE_SCRIPT_LOCAL="/tmp/remote_update.sh"
REMOTE_SCRIPT_REMOTE="/tmp/remote_update.sh"
SUDO_ASKPASS_PATH="$HOME/sudo_askpass.sh"
RUN_LOG="/tmp/run_log.txt"
CHECKSUM_FILE="/tmp/remote_update.sh.md5"
DRY_RUN=false

# Export SUDO_ASKPASS
export SUDO_ASKPASS="$SUDO_ASKPASS_PATH"

# Initialize RUN_LOG
> "$RUN_LOG"

# Enable error trapping
set -e

# Function to log messages with color
log_message() {
    local color=$1
    local message=$2
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
# Function to create remote update script
create_remote_script() {
    local available_space=$(df -P "$(dirname "$REMOTE_SCRIPT_LOCAL")" | awk 'NR==2 {print $4}')
    if (( available_space < 1024 )); then  # Less than 1MB
        log_message red "Error: Insufficient disk space to create remote script"
        return 1
    fi

    # Add additional logic for the create_remote_script function here
    
    # Writing the remote script content to file
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
EOF

} || handle_error "create_remote_script" "$?"

# Invoke remote script creation
create_remote_script

# Function to handle errors
handle_error() {
    local func_name="$1"
    local err="$2"
    log_message red "Error in function '${func_name}': ${err}"
    exit 1
}

# Function to handle dry-run mode
dry_run_mode() {
    if $DRY_RUN; then
        echo -e "\e[33m[DRY-RUN MODE] The following actions will be taken (no actual changes will be made):\e[0m"
        return 0
    fi
    return 1
}

# Function to display usage information
usage() {
    echo -e "Usage: $SCRIPT_NAME [OPTIONS]"
    echo -e "Options:"
    echo -e "  --dry-run        Simulate the script's execution without making changes"
    echo -e "  --help           Display this help message"
}

get_log_info() {
    { 
        echo -e "\n\e[36mLog Information:\e[0m"
        
        local logs=(
            "$LOG_FILE:Local Update Log:local"
            "$BACKUP_LOG_FILE:Backup Log File:local"
            "$REMOTE_SCRIPT_LOCAL:Remote Update Script (Local):local"
            "$REMOTE_SCRIPT_REMOTE:Remote Update Script (Remote):remote"
            "/var/log/pihole/pihole_updateGravity.log:Pi-hole Gravity Update Log:remote"
            "/var/log/pihole/FTL.log:Pi-hole FTL Log:remote"
            "/var/log/pihole/pihole.log:Pi-hole Log:remote"
            "/var/log/auth.log:Auth Log:local"
            "/var/log/boot.log:Boot Log:local"
            "/var/log/dpkg.log:DPKG Log:local"
            "/var/log/fail2ban.log:Fail2Ban Log:local"
            "/var/log/gpu-manager.log:GPU Manager Log:local"
            "/var/log/kern.log:Kernel Log:local"
            "/var/log/mintsystem.log:Mint System Log:local"
            "/var/log/syslog:System Log:local"
        )

        for log in "${logs[@]}"; do
            IFS=':' read -r path name location <<< "$log"
            if [ "$location" = "local" ]; then
                if [ -f "$path" ]; then
                    log_size=$(du -h "$path" | cut -f1)
                    printf "   \e[32m✓\e[0m \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "$name" "$log_size"
                else
                    printf "   \e[31m✗\e[0m \e[36m%-30s\e[0m : \e[31mNot Found\e[0m\n" "$name"
                fi
            else
                remote_log=$(ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $path && du -h $path || echo 'Not Found'")
                if [[ $remote_log == *"Not Found"* ]]; then
                    printf "   \e[31m✗\e[0m \e[36m%-30s\e[0m : \e[31mNot Found\e[0m\n" "$name"
                else
                    log_size=$(echo "$remote_log" | cut -f1)
                    printf "   \e[32m✓\e[0m \e[36m%-30s\e[0m : \e[32m%s\e[0m\n" "$name" "$log_size"
                fi
            fi
        done
        echo -e "\n"
    } || handle_error "get_log_info" "$?"
}

# Trap errors and signals
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >> "$RUN_LOG"' ERR
trap 'echo "Script terminated prematurely" >> "$RUN_LOG"; exit 1' SIGINT SIGTERM

# Function to check the RUN_LOG for errors
check_run_log() {
    {
        if [ -s "$RUN_LOG" ]; then
            log_message red "Errors were encountered during the script execution:"
            cat "$RUN_LOG"
            > "$RUN_LOG"  # Clear the RUN_LOG after displaying errors
        else
            log_message green "No errors detected during the script execution."
        fi
    } || handle_error "check_run_log" "$?"
}

# Function to ensure checksum utility is available
ensure_checksum_utility() {
    { 
        if ! command -v md5sum &> /dev/null; then
            log_message red "md5sum is not installed. Please install it and try again."
            exit 1
        fi
    } || handle_error "ensure_checksum_utility" "$?"
}

# Function to create checksum
create_checksum() {
    { 
        md5sum "$REMOTE_SCRIPT_LOCAL" | awk '{ print $1 }' > "$CHECKSUM_FILE"
    } || handle_error "create_checksum" "$?"
}

# Function to verify checksum
verify_checksum() {
    {
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
    } || handle_error "verify_checksum" "$?"
}

# Parse command-line arguments
while [[ "$1" != "" ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo -e "\e[31mInvalid option: $1\e[0m"
            usage
            exit 1
            ;;
    esac
    shift
done

# Function to validate log files
validate_log_files() {
    {
        local log_files=("$LOG_FILE" "$BACKUP_LOG_FILE" "$REMOTE_LOG" "$BACKUP_REMOTE_LOG")
        for file in "${log_files[@]}"; do
            local dir=$(dirname "$file")
            if [[ ! -d "$dir" ]]; then
                log_message red "Error: Directory for log file does not exist: $dir"
                exit 1
            fi
            if [[ ! -w "$dir" ]]; then
                log_message red "Error: Cannot write to log directory: $dir"
                exit 1
            fi
        done
    } || handle_error "validate_log_files" "$?"
}

# Function to validate SSH connection
validate_ssh_connection() {
    {
        if ! ssh -q -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_USER@$REMOTE_HOST" exit; then
            log_message red "Error: Cannot establish SSH connection to $REMOTE_USER@$REMOTE_HOST"
            exit 1
        fi
    } || handle_error "validate_ssh_connection" "$?"
}

# Function to validate required commands
validate_commands() {
    {
        local required_commands=("ssh" "scp" "md5sum" "sudo" "apt-get")
        for cmd in "${required_commands[@]}"; do
            if ! command -v "$cmd" &> /dev/null; then
                log_message red "Error: Required command not found: $cmd"
                exit 1
            fi
        done
    } || handle_error "validate_commands" "$?"
}

# Function to validate changelog
validate_changelog() {
    {
        if [[ ! -f "$CHANGELOG_FILE" ]]; then
            log_message yellow "Warning: CHANGELOG_FILE does not exist. Creating it."
            touch "$CHANGELOG_FILE" || {
                log_message red "Error: Failed to create CHANGELOG_FILE"
                exit 1
            }
        elif [[ ! -w "$CHANGELOG_FILE" ]]; then
            log_message red "Error: CHANGELOG_FILE is not writable"
            exit 1
        fi
    } || handle_error "validate_changelog" "$?"
}

# Function to validate IP addresses
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a ip_parts <<< "$ip"
        for part in "${ip_parts[@]}"; do
            if [[ $part -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Function to validate variables
validate_variables() {
    validate_log_files
    validate_ssh_connection
    validate_commands
    validate_changelog

    # Additional variable checks
    if [[ -z "$VERSION" ]]; then
        log_message red "Error: VERSION is not set"
        exit 1
    fi

    if [[ -z "$SCRIPT_NAME" ]]; then
        log_message red "Error: SCRIPT_NAME is not set"
        exit 1
    fi

    if [[ -z "$REMOTE_USER" ]]; then
        log_message red "Error: REMOTE_USER is not set"
        exit 1
    fi

    if [[ -z "$REMOTE_HOST" ]]; then
        log_message red "Error: REMOTE_HOST is not set"
        exit 1
    fi

    if ! validate_ip "$REMOTE_HOST"; then
        log_message red "Error: Invalid IP address for REMOTE_HOST"
        exit 1
    fi

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_message red "Error: BACKUP_DIR does not exist"
        exit 1
    fi

    if [[ ! -f "$SUDO_ASKPASS_PATH" ]]; then
        log_message red "Error: SUDO_ASKPASS_PATH file does not exist"
        exit 1
    fi
}

# Validate variables
validate_variables

# Announce the version
log_message cyan "Starting script version $VERSION"

# Backup log file if it exists
if [ -f "$LOG_FILE" ]; then
    {
        log_message yellow "Backing up existing log file..."
        cp "$LOG_FILE" "$BACKUP_LOG_FILE"
    } || handle_error "backup_log_file" "$?"
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

# Call the log info function
get_log_info

# Function to backup the script only if it's changed
backup_script() {
    {
        log_message yellow "Backing up script..."
        
        # Get the latest backup file if it exists
        latest_backup=$(ls -t "$BACKUP_DIR/$(basename "$0")_"*.sh 2>/dev/null | head -n 1)
        
        # Compare the current script with the latest backup
        if [ -f "$latest_backup" ] && cmp -s "$0" "$latest_backup"; then
            log_message green "No changes detected. Backup not needed."
        else
            cp "$0" "$BACKUP_DIR/$(basename "$0")_backup.sh"
            log_message green "Script backed up successfully."
        fi
    } || handle_error "backup_script" "$?"
}

# Backup the script
backup_script

# Function to check sudo permissions
check_sudo_permissions() {
    {
        if ! sudo -A true 2>/dev/null; then
            log_message red "Error: Sudo permissions required but not available"
            log_message yellow "Please ensure SUDO_ASKPASS is properly configured"
            exit 1
        fi
    } || handle_error "check_sudo_permissions" "$?"
}

# Function to perform local update
perform_local_update() {
    {
        check_sudo_permissions

        log_message blue "$(printf '\e[3mUpdating package list...\e[0m')"
        if ! sudo -A apt-get update 2>&1 | tee -a "$LOG_FILE"; then
            log_message red "Error: Failed to update package list"
            return 1
        fi

        log_message blue "$(printf '\e[3mUpgrading packages...\e[0m')"
        if ! sudo -A apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"; then
            log_message red "Error: Failed to upgrade packages"
            return 1
        fi

        log_message blue "$(printf '\e[3mPerforming distribution upgrade...\e[0m')"
        if ! sudo -A apt-get dist-upgrade -y 2>&1 | tee -a "$LOG_FILE"; then
            log_message red "Error: Failed to perform distribution upgrade"
            return 1
        fi

        log_message blue "$(printf '\e[3mRemoving unnecessary packages...\e[0m')"
        if ! sudo -A apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"; then
            log_message red "Error: Failed to remove unnecessary packages"
            return 1
        fi

        log_message blue "$(printf '\e[3mCleaning up...\e[0m')"
        if ! sudo -A apt-get clean 2>&1 | tee -a "$LOG_FILE"; then
            log_message red "Error: Failed to clean up"
            return 1
        fi

        return 0
    } || handle_error "perform_local_update" "$?"
}

# Main execution
check_sudo_permissions

if ! perform_local_update; then
    log_message red "Local update process failed"
    exit 1
fi

log_message cyan "Remote script completed."


# Function to copy the remote script
copy_remote_script() {
    if dry_run_mode; then
        echo "scp $REMOTE_USER@$REMOTE_HOST:$REMOTE_SCRIPT_REMOTE $REMOTE_SCRIPT_LOCAL"
        echo "ssh $REMOTE_USER@$REMOTE_HOST 'md5sum $REMOTE_SCRIPT_REMOTE'"
    else
        scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SCRIPT_REMOTE" "$REMOTE_SCRIPT_LOCAL"
        ssh "$REMOTE_USER@$REMOTE_HOST" "md5sum $REMOTE_SCRIPT_REMOTE" > "$CHECKSUM_FILE"
    fi
}

# Function to verify checksum
verify_checksum() {
    if [ -f "$CHECKSUM_FILE" ]; then
        remote_checksum=$(awk '{print $1}' "$CHECKSUM_FILE")
        local_checksum=$(md5sum "$REMOTE_SCRIPT_LOCAL" | awk '{print $1}')

        if [ "$remote_checksum" = "$local_checksum" ]; then
            log_message green "Checksum verification successful: Checksums match."
        else
            log_message red "Checksum verification failed: Checksums do not match."
            exit 1
        fi
    else
        log_message red "Checksum file not found."
        exit 1
    fi
}

# Run Copy Remote Script
copy_remote_script

# Verify the checksum
log_message blue "$(printf '\e[3mVerifying script checksum on remote server...\e[0m')"
verify_checksum

# Run the script on the remote server
log_message blue "$(printf '\e[3mExecuting remote update script...\e[0m')"
ssh "$REMOTE_USER@$REMOTE_HOST" "$REMOTE_SCRIPT_REMOTE"

# Retrieve remote log
log_message blue "$(printf '\e[3mRetrieving remote log file...\e[0m')"
scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_LOG" "$BACKUP_REMOTE_LOG"

log_message cyan "Remote system updated successfully. Check log at $BACKUP_LOG_FILE"

# Final log and backup
log_message green "Creating backups..."
cp "$LOG_FILE" "$BACKUP_DIR/$(basename $LOG_FILE)_$(date +%Y%m%d%H%M%S).log"
cp "$LOG_FILE" "$BACKUP_LOG_FILE"

log_message cyan "Update process completed successfully!"

# Check for errors
check_run_log

# Append to changelog if version is new
log_message blue "Checking for new version..."
LAST_LOGGED_VERSION=$(grep -oP '(?<=Script version )\S+' "$CHANGELOG_FILE" | tail -1)
if [ "$VERSION" != "$LAST_LOGGED_VERSION" ]; then
    log_message blue "Updating changelog..."
    cat << EOF >> "$CHANGELOG_FILE"
[$(date +"%Y-%m-%d %H:%M:%S")] Script version $VERSION
- Change sytem Information display formatting.
EOF
else
    log_message blue "Version $VERSION is already logged. No changes made to changelog."

fi

