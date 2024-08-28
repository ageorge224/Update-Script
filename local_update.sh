#!/bin/bash

# Variables
VERSION="1.1.42"
SCRIPT_NAME="local_update.sh"
REMOTE_USER="ageorge"
REMOTE_HOST="192.168.1.248"
BACKUP_DIR="/home/ageorge/Documents/Backups"
BACKUP_DIR2="/media/ageorge/Nvme500Data/Update Backups"
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
LOCAL_UPDATE_ERROR="$BACKUP_LOG_DIR/local_update_error.log"
LOCAL_UPDATE_DEBUG="$BACKUP_LOG_DIR/local_update_debug.log"
centralized_error_log="$BACKUP_LOG_DIR/centralized_error_log.log"
SEEN_ERRORS_FILE="$BACKUP_LOG_DIR/seen_errors.log"
DRY_RUN=false
CHAOS_MONKEY_ENABLED=false
CHAOS_MONKEY_PROBABILITY=30 # Percentage chance of chaos occurring
CACHE_DIR="$HOME/.logscan_cache"
LAST_RUN_FILE="$CACHE_DIR/last_run"

# Function to log messages with color
log_message() {
    local color=$1
    local message=$2
    case $color in
        red) color_code="\e[31m" ;;
        green) color_code="\e[32m" ;;
        yellow) color_code="\e[33m" ;;
        blue) color_code="\e[34m" ;;
        magenta) color_code="\e[35m" ;;
        cyan) color_code="\e[36m" ;;
        white) color_code="\e[37m" ;;
        gray) color_code="\e[90m" ;;
        light_red) color_code="\e[91m" ;;
        light_green) color_code="\e[92m" ;;
        light_yellow) color_code="\e[93m" ;;
        light_blue) color_code="\e[94m" ;;
        light_magenta) color_code="\e[95m" ;;
        light_cyan) color_code="\e[96m" ;;
        *) color_code="" ;;
    esac
    echo -e "${color_code}${message}\e[0m" | tee -a "$LOG_FILE"
}
# Export SUDO_ASKPASS
export SUDO_ASKPASS="$SUDO_ASKPASS_PATH"

# Initialize RUN_LOG
> "$RUN_LOG"

# Enable error trapping
set -e

# Parse command-line arguments
while [[ "$1" != "" ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            ;;
        --chaos)
            CHAOS_MONKEY_ENABLED=true
            log_message yellow "🙈🙉🙊 Chaos Monkey mode activated! Expect some mischief..."
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

# Function to handle errors
handle_error() {
    local func_name="$1"
    local err="$2"

    # Log the error message
    log_message red "Error in function '${func_name}': ${err}"

    # Optionally, write the error to a specific error log file
    echo "Error in function '${func_name}': ${err}" >> "$LOCAL_UPDATE_ERROR"

    # Perform additional actions if needed, such as:
    # - Sending a notification
    # - Retrying the operation
    # - Logging more details

    # Exit the script
    exit 1
}

# Header creation and display function
print_header() {
    local script_name="local_update.sh"
    local version="1.1.40"
    local author="Anthony George"
    local description="A script for performing local and remote system updates with backup functionality"
    local date=$(date +"%Y-%m-%d")
    local width=80

    # Function to print a line
    print_line() {
        local char="$1"
        printf "\e[36m%s\e[0m\n" "$(printf "%${width}s" | tr ' ' "$char")"
    }

    # Top of the box
    echo -e "\e[36m╭$(printf "%${width}s" | tr ' ' '─')╮\e[0m"

    # Script name and version
    printf "\e[36m│\e[1;33m %-$((width - 2))s \e[36m│\e[0m\n" "$script_name v$version"
    print_line "─"

    # Date and author
    printf "\e[36m│\e[0m %-15s\e[32m%-$((width - 19))s\e[36m│\e[0m\n" "Date:" "$date"
    printf "\e[36m│\e[0m %-15s\e[32m%-$((width - 19))s\e[36m│\e[0m\n" "Author:" "$author"

    # Description
    print_line "─"
    printf "\e[36m│\e[0m \e[1mDescription:\e[0m%-$((width - 14))s\e[36m│\e[0m\n" " "
    local desc_words=($description)
    local line=""
    for word in "${desc_words[@]}"; do
        if ((${#line} + ${#word} + 1 > width - 4)); then
            printf "\e[36m│\e[0m %-$((width - 2))s \e[36m│\e[0m\n" "$line"
            line="$word"
        else
            [[ -n $line ]] && line+=" "
            line+="$word"
        fi
    done
    [[ -n $line ]] && printf "\e[36m│\e[0m %-$((width - 2))s \e[36m│\e[0m\n" "$line"

    # Configuration Variables
    print_line "─"
    printf "\e[36m│\e[0m \e[1mConfiguration Variables:\e[0m%-$((width - 26))s\e[36m│\e[0m\n" " "
    printf "\e[36m│\e[0m %-20s \e[32m%-$((width - 24))s\e[36m│\e[0m\n" "REMOTE_USER:" "$REMOTE_USER"
    printf "\e[36m│\e[0m %-20s \e[32m%-$((width - 24))s\e[36m│\e[0m\n" "REMOTE_HOST:" "$REMOTE_HOST"
    printf "\e[36m│\e[0m %-20s \e[32m%-$((width - 24))s\e[36m│\e[0m\n" "BACKUP_DIR:" "$BACKUP_DIR"
    printf "\e[36m│\e[0m %-20s \e[32m%-$((width - 24))s\e[36m│\e[0m\n" "BACKUP_DIR2:" "$BACKUP_DIR2"
    printf "\e[36m│\e[0m %-20s \e[32m%-$((width - 24))s\e[36m│\e[0m\n" "LOG_FILE:" "$LOG_FILE"
    printf "\e[36m│\e[0m %-20s \e[32m%-$((width - 24))s\e[36m│\e[0m\n" "BACKUP_LOG_FILE:" "$BACKUP_LOG_FILE"
    printf "\e[36m│\e[0m %-20s \e[32m%-$((width - 24))s\e[36m│\e[0m\n" "DRY_RUN:" "$DRY_RUN"
    printf "\e[36m│\e[0m %-20s \e[32m%-$((width - 24))s\e[36m│\e[0m\n" "CHAOS_MONKEY:" "$CHAOS_MONKEY_ENABLED"

    # Bottom of the box
    echo -e "\e[36m╰$(printf "%${width}s" | tr ' ' '─')╯\e[0m"
    echo
}

print_header

# Function to validate log files
validate_log_files() {
    {
        local log_files=("$LOG_FILE" "$BACKUP_LOG_FILE" "$REMOTE_LOG" "$BACKUP_REMOTE_LOG" "$centralized_error_log" "$LOCAL_UPDATE_ERROR" "$LOCAL_UPDATE_DEBUG")
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

# Function to validate the SEEN_ERRORS_FILE
validate_seen_errors_file() {
    {
        if [[ ! -f "$SEEN_ERRORS_FILE" ]]; then
            log_message yellow "SEEN_ERRORS_FILE does not exist. Creating it."
            touch "$SEEN_ERRORS_FILE" || {
                log_message red "Error: Failed to create SEEN_ERRORS_FILE"
                exit 1
            }
        elif [[ ! -w "$SEEN_ERRORS_FILE" ]]; then
            log_message red "Error: SEEN_ERRORS_FILE is not writable"
            exit 1
        fi
    } || handle_error "validate_seen_errors_file" "$?"
}

# Function to validate variables
validate_variablesv2() {
    validate_log_files
    validate_ssh_connection
    validate_commands
    validate_changelog
    validate_seen_errors_file

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

    if [[ ! -d "$BACKUP_DIR2" ]]; then
        log_message red "Error: BACKUP_DIR2 does not exist"
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

if [ -f /var/run/reboot-required ]; then
    echo 'Local Machine needs restarting'
fi

# Function to validate IP address
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

# Function to verify and create directories if they don't exist
verify_and_create_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_message yellow "Directory $dir does not exist. Creating it..."
        mkdir -p "$dir" || {
            log_message red "Failed to create directory: $dir"
            exit 1
        }
    fi
    if [[ ! -w "$dir" ]]; then
        log_message red "Cannot write to directory: $dir"
        exit 1
    fi
}

# Function to verify file paths
verify_file_path() {
    local file="$1"
    local dir=$(dirname "$file")
    verify_and_create_directory "$dir"
    if [[ ! -f "$file" && "$2" != "create" ]]; then
        log_message red "File does not exist: $file"
        exit 1
    fi
    if [[ "$2" == "create" && ! -f "$file" ]]; then
        touch "$file" || {
            log_message red "Failed to create file: $file"
            exit 1
        }
    fi
    if [[ ! -w "$file" ]]; then
        log_message red "Cannot write to file: $file"
        exit 1
    fi
}

# Function to validate variables
validate_variables() {
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

    # Additional checks for remote paths
    ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $REMOTE_LOG && test -w $REMOTE_LOG" || {
        log_message red "Error: REMOTE_LOG does not exist or is not writable"
        exit 1
    }

    ssh "$REMOTE_USER@$REMOTE_HOST" "test -w $(dirname $REMOTE_LOG)" || {
        log_message red "Error: Cannot write to remote directory for REMOTE_LOG"
        exit 1
    }

    ssh "$REMOTE_USER@$REMOTE_HOST" "test -d $(dirname $REMOTE_SCRIPT_REMOTE)" || {
        log_message red "Error: Remote directory for REMOTE_SCRIPT_REMOTE does not exist"
        exit 1
    }

    ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $REMOTE_SCRIPT_REMOTE && test -w $REMOTE_SCRIPT_REMOTE" || {
        log_message red "Error: REMOTE_SCRIPT_REMOTE does not exist or is not writable"
        exit 1
    }
}

if [[ ! -d "$BACKUP_DIR2" ]]; then
    log_message red "Error: BACKUP_DIR2 does not exist"
    exit 1
fi

# Verify and create necessary directories and files
verify_and_create_directory "$BACKUP_DIR"
verify_and_create_directory "$BACKUP_DIR2"
verify_and_create_directory "$BACKUP_LOG_DIR"
verify_file_path "$CHANGELOG_FILE" "create"
verify_file_path "$LOG_FILE" "create"
verify_file_path "$BACKUP_REMOTE_LOG" "create"
verify_file_path "$BACKUP_LOG_FILE" "create"
verify_file_path "$centralized_error_log" "create"
verify_file_path "$SUDO_ASKPASS_PATH"
verify_file_path "$RUN_LOG" "create"
verify_file_path "$CHECKSUM_FILE" "create"
verify_file_path "$SEEN_ERRORS_FILE" "create"
verify_file_path "$LOCAL_UPDATE_ERROR" "create"
verify_file_path "$LOCAL_UPDATE_DEBUG" "create"

# Call validate_variables after setting up all paths
validate_variables

# Function for Chaos Monkey
chaos_monkey() {
    if ! $CHAOS_MONKEY_ENABLED; then
        return
    fi

    if [ $((RANDOM % 100)) -lt $CHAOS_MONKEY_PROBABILITY ]; then
        log_message magenta "🐒 Chaos Monkey is feeling mischievous..."
        local chaos_type=$((RANDOM % 5))
        case $chaos_type in
            0)
                log_message magenta "🙈 Chaos Monkey is temporarily hiding some system files..."
                sudo find /etc -type f -print0 | shuf -z -n 5 | xargs -0 sudo mv -t /tmp
                sleep 10
                sudo find /tmp -maxdepth 1 -type f -print0 | xargs -0 -I {} sudo mv {} $(dirname $(readlink -f {}))
                log_message magenta "🙉 Chaos Monkey returned the hidden files."
                ;;
            1)
                log_message magenta "🙊 Chaos Monkey is filling up your disk space..."
                sudo dd if=/dev/zero of=/tmp/bigfile bs=1M count=1024
                sleep 10
                sudo rm /tmp/bigfile
                log_message magenta "💾 Chaos Monkey freed up the disk space."
                ;;
            2)
                log_message magenta "🐵 Chaos Monkey is scrambling your hostname..."
                original_hostname=$(hostname)
                new_hostname=$(echo "$original_hostname" | rev)
                sudo hostnamectl set-hostname "$new_hostname"
                sleep 10
                sudo hostnamectl set-hostname "$original_hostname"
                log_message magenta "🏠 Chaos Monkey restored your hostname."
                ;;
            3)
                log_message magenta "🍌 Chaos Monkey is messing with your system time..."
                sudo date -s "2 years ago"
                sleep 10
                sudo hwclock --hctosys
                log_message magenta "⏰ Chaos Monkey reset your system time."
                ;;
            4)
                log_message magenta "🎭 Chaos Monkey is impersonating other users..."
                original_user=$(whoami)
                sudo useradd -m tempuser
                sudo -u tempuser bash -c 'echo "Hello from tempuser" >> /tmp/chaos_monkey_was_here.txt'
                sudo userdel -r tempuser
                log_message magenta "👤 Chaos Monkey stopped impersonating other users."
                ;;
        esac
    else
        log_message green "🐒 Chaos Monkey is behaving... for now."
    fi
}

if [[ "$1" == "--chaos" ]]; then
    CHAOS_MONKEY_ENABLED=true
    log_message yellow "🙈🙉🙊 Chaos Monkey mode activated! Expect some mischief..."
fi

# Validate variables
chaos_monkey
validate_variablesv2

# Set DRY_RUN to false by default if not provided
DRY_RUN=${DRY_RUN:-false}

# Function to make Remote_Script
create_remote_script() {
    local available_space=$(df -P "$(dirname "$REMOTE_SCRIPT_LOCAL")" | awk 'NR==2 {print $4}')
    if ((available_space < 1024)); then # Less than 1MB
        log_message red "Error: Insufficient disk space to create remote script"
        return 1
    fi

    # Writing the remote script content to file
    cat << 'EOF' > "$REMOTE_SCRIPT_LOCAL"
#!/bin/bash

VERSION="1.1.07"
LOG_FILE="/tmp/remote_update.log"
SUMMARY_LOG="/tmp/remote_update_summary.log"
BACKUP_LOG_DIR="$HOME/Desktop"
BACKUP_LOG_FILE="$BACKUP_LOG_DIR/remote_update.log"
SUDO_ASKPASS_PATH="$HOME/sudo_askpass.sh"
RUN_LOG="/tmp/remote_run_log.txt"
ERROR_LOG="/tmp/remote_error_log.txt"
DRY_RUN="$DRY_RUN"  # Pass DRY_RUN from the main script

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
        white) color_code="\e[37m";;
        gray) color_code="\e[90m";;
        light_red) color_code="\e[91m";;
        light_green) color_code="\e[92m";;
        light_yellow) color_code="\e[93m";;
        light_blue) color_code="\e[94m";;
        light_magenta) color_code="\e[95m";;
        light_cyan) color_code="\e[96m";;
        *) color_code="";;
    esac
    echo -e "${color_code}${message}\e[0m" | tee -a "$LOG_FILE"
}

# Export SUDO_ASKPASS
export SUDO_ASKPASS="$SUDO_ASKPASS_PATH"

# Initialize RUN_LOG and ERROR_LOG
> "$RUN_LOG"
> "$ERROR_LOG"

# Enable error trapping
set -e

# Function to handle errors
handle_error() {
    local function_name="$1"
    local error_message="$2"
    log_message red "Error in ${function_name}: ${error_message}"
    echo "${function_name}: ${error_message}" >> "$ERROR_LOG"
}

# Trap to catch and log any unexpected errors
trap 'handle_error "${FUNCNAME[0]:-main}" "Unexpected error on line $LINENO"' ERR

# Validation functions
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

verify_and_create_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_message yellow "Directory $dir does not exist. Creating it..."
        if [[ "$DRY_RUN" != "true" ]]; then
            if ! mkdir -p "$dir"; then
                handle_error "verify_and_create_directory" "Failed to create directory: $dir"
                return 1
            fi
        else
            log_message yellow "[DRY RUN] Would create directory: $dir"
        fi
    fi
    if [[ ! -w "$dir" && "$DRY_RUN" != "true" ]]; then
        handle_error "verify_and_create_directory" "Cannot write to directory: $dir"
        return 1
    fi
}

verify_file_path() {
    local file="$1"
    local dir=$(dirname "$file")
    if ! verify_and_create_directory "$dir"; then
        handle_error "verify_file_path" "Failed to verify/create directory for file: $file"
        return 1
    fi
    if [[ ! -f "$file" && "$2" != "create" ]]; then
        handle_error "verify_file_path" "File does not exist: $file"
        return 1
    fi
    if [[ "$2" == "create" && ! -f "$file" ]]; then
        if [[ "$DRY_RUN" != "true" ]]; then
            if ! touch "$file"; then
                handle_error "verify_file_path" "Failed to create file: $file"
                return 1
            fi
        else
            log_message yellow "[DRY RUN] Would create file: $file"
        fi
    fi
    if [[ ! -w "$file" && "$DRY_RUN" != "true" ]]; then
        handle_error "verify_file_path" "Cannot write to file: $file"
        return 1
    fi
}

# Validation checks
validate_remote_environment() {
    if [[ -z "$VERSION" ]]; then
        handle_error "validate_remote_environment" "VERSION is not set"
        return 1
    fi

    # Verify and create necessary directories and files
    verify_and_create_directory "$BACKUP_LOG_DIR" || return 1
    verify_file_path "$LOG_FILE" "create" || return 1
    verify_file_path "$BACKUP_LOG_FILE" "create" || return 1
    verify_file_path "$SUDO_ASKPASS_PATH" || return 1
    verify_file_path "$RUN_LOG" "create" || return 1
    verify_file_path "$ERROR_LOG" "create" || return 1

    # Check for required commands
    local required_commands=("ssh" "scp" "md5sum" "sudo" "apt-get" "pihole")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            handle_error "validate_remote_environment" "Required command not found: $cmd"
            return 1
        fi
    done

    return 0
}

# Function to generate and display sytem info
get_system_identification() {
    {
        echo -e "\n\e[36mSystem Identification:\e[0m"
        echo

        # System Info
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Hostname:" "$(hostname)"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Operating System:" "$(lsb_release -d | cut -f2)"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Kernel Version:" "$(uname -r)"

        # CPU Info
        cpu_info=$(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//')
        cpu_cores=$(lscpu | grep '^CPU(s):' | awk '{print $2}')
        printf "\e[36m%-18s\e[0m \e[32m%s (%s cores)\e[0m\n" "CPU Info:" "$cpu_info" "$cpu_cores"

        # GPU Info
        gpu_info=$(lspci | grep -i vga | sed 's/.*: //')
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "GPU Info:" "$gpu_info"

        # Memory Info
        total_mem=$(free -h | awk '/^Mem:/ {print $2}')
        used_mem=$(free -h | awk '/^Mem:/ {print $3}')
        printf "\e[36m%-18s\e[0m \e[32m%s / %s\e[0m\n" "Memory Info:" "$used_mem" "$total_mem"

        # Disk Info
        echo -e "\e[36mDisk Info:\e[0m"
        echo -e "  \e[36mDrives:\e[0m"
        printf "  \e[36m%-10s %-30s %-10s %-15s\e[0m\n" "Device" "Model" "Size" "Used"

        lsblk -d -o NAME,MODEL,SIZE | grep -v 'loop' | while read -r name model size; do
            used=$(df -h | grep "^/dev/${name}" | awk '{print $3}')
            if [[ -z "$used" ]]; then
                used="N/A"
            fi
            printf "  \e[32m%-10s %-30s %-10s %-15s\e[0m\n" "$name" "${model:0:30}" "$size" "$used"
        done

        # Network Info
        echo -e "\n\e[36mNetwork Info:\e[0m"
        ip -br addr show | grep -v '^lo' | while read -r iface ip; do
            printf "  \e[36m%-12s\e[0m \e[32m%s\e[0m\n" "$iface" "$ip"
        done

        echo
    } || handle_error "get_system_identification" "$?"
}


get_system_identification

perform_remote_update() {
    local update_steps=(
        "Updating remote package list:sudo -A apt-get update"
        "Upgrading remote packages:sudo -A apt-get upgrade -y"
        "Performing remote distribution upgrade:sudo -A apt-get dist-upgrade -y"
        "Removing unnecessary remote packages:sudo -A apt-get autoremove -y"
        "Cleaning up remote system:sudo -A apt-get clean"
        "Updating Pi-hole:sudo -A pihole -up"
        "Updating Pi-hole gravity:sudo -A pihole -g > /tmp/pihole_gravity.log 2>&1"
    )
    
    # Verify pihole_gravity.log path
    verify_file_path "/tmp/pihole_gravity.log" "create" || return 1
    
    for step in "${update_steps[@]}"; do
        IFS=':' read -r description command <<< "$step"
        echo
        log_message blue "$(printf '\e[3m%s\e[0m' "$description")"
        echo
        
        if [[ "$DRY_RUN" != "true" ]]; then
            if [[ "$description" == "Updating Pi-hole gravity" ]]; then
                # Start the command in the background
                eval "$command" &
                pid=$!
                
                # Display a spinning progress indicator
                spin='-\|/'
                i=0
                while kill -0 $pid 2>/dev/null; do
                    i=$(( (i+1) % 4 ))
                    printf "\r[%c] Updating Pi-hole gravity..." "${spin:$i:1}"
                    sleep .1
                done
                printf "\r%s\n" "Pi-hole gravity update completed!"
                
                # Wait for the background process to finish
                wait $pid
                if [ $? -ne 0 ]; then
                    handle_error "perform_remote_update" "Failed to $description"
                fi
            else
                if ! eval "$command" 2>&1 | tee -a "$LOG_FILE"; then
                    handle_error "perform_remote_update" "Failed to $description"
                fi
            fi
        else
            log_message yellow "[DRY RUN] Would run: $command"
        fi
    done
    
    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ -f /tmp/pihole_gravity.log ]] && grep -q "FTL is listening" /tmp/pihole_gravity.log; then
            log_message green "Pi-hole gravity update completed successfully!"
            echo
        else
            handle_error "perform_remote_update" "Pi-hole gravity update encountered an issue. Check /tmp/pihole_gravity.log for details."
            echo -e "Pi-hole gravity update encountered an issue" >> "$SUMMARY_LOG"
        fi
    fi
}

# Check for restart
if [ -f /var/run/reboot-required ]; then
  echo 'Remote Machine needs restarting'
fi

# Main execution
main() {
    log_message blue "Starting remote update process"
    
    if validate_remote_environment; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_message yellow "Running in DRY RUN mode. No changes will be made."
        fi

        perform_remote_update

        # Check for errors
        if [ -s "$ERROR_LOG" ]; then
            log_message red "Errors were encountered during the script execution:"
            cat "$ERROR_LOG"
        else
            log_message green "<----[No errors detected during the Remote script execution.]---->"
        fi

        if [[ "$DRY_RUN" == "true" ]]; then
            log_message yellow "DRY RUN completed. No changes were made."
        else
            log_message cyan "         {{[[[**Completed, Remote Script finished.**]]]}}"
        fi
    else
        log_message red "Validation of remote environment failed. Aborting update process."
        return 1
    fi
}

# Run main function
main

EOF

    # Set execute permissions on the remote script
    if ! chmod +x "$REMOTE_SCRIPT_LOCAL"; then
        log_message red "Error: Failed to set execute permissions on remote script"
        return 1
    fi

    log_message green "Remote script created at: $REMOTE_SCRIPT_LOCAL"
}

# Invoke remote script creation
chaos_monkey
create_remote_script

trap 'handle_error "$BASH_COMMAND" "$?"' ERR

# Function to check dry-run mode and return a status code
check_dry_run_mode() {
    if $DRY_RUN; then
        echo -e "\e[33m[DRY-RUN MODE] The following actions will be taken (no actual changes will be made):\e[0m"
        return 0 # Success
    fi

    return 1 # Failure
}

# Function to display usage information
usage() {
    echo -e "Usage: $SCRIPT_NAME [OPTIONS]"
    echo -e "Options:"
    echo -e "  --dry-run        Simulate the script's execution without making changes"
    echo -e "  --help           Display this help message"
}

# Function to copy script to remote and set permissions
copy_local_to_remote() {
    if check_dry_run_mode; then
        echo "scp $REMOTE_SCRIPT_LOCAL $REMOTE_USER@$REMOTE_HOST:$REMOTE_SCRIPT_REMOTE"
        echo "ssh $REMOTE_USER@$REMOTE_HOST 'chmod +x $REMOTE_SCRIPT_REMOTE'"
        echo "ssh $REMOTE_USER@$REMOTE_HOST 'md5sum $REMOTE_SCRIPT_REMOTE'"
    else
        if ! scp "$REMOTE_SCRIPT_LOCAL" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SCRIPT_REMOTE"; then
            handle_error "copy_local_to_remote" "Failed to copy script to remote host"
        fi
        if ! ssh "$REMOTE_USER@$REMOTE_HOST" "chmod +x $REMOTE_SCRIPT_REMOTE"; then
            handle_error "copy_local_to_remote" "Failed to set execute permissions on remote script"
        fi
        if ! ssh "$REMOTE_USER@$REMOTE_HOST" "md5sum $REMOTE_SCRIPT_REMOTE" > "$CHECKSUM_FILE"; then
            handle_error "copy_local_to_remote" "Failed to generate checksum on remote host"
        fi
    fi
}

#Invoke to pass script to remote
chaos_monkey
#create_remote_script
copy_local_to_remote

# Log Information Function
get_log_info() {
    {
        echo -e "\n\e[36mLog Information:\e[0m"
        local_logs=()
        remote_logs=()
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
            "$LOCAL_UPDATE_ERROR:Local Error Log:local"
            "$LOCAL_UPDATE_DEBUG:Local Debug Log:local"
            "/var/log/auth.log:Auth Log:remote"         # Added for remote
            "/var/log/boot.log:Boot Log:remote"         # Added for remote
            "/var/log/dpkg.log:DPKG Log:remote"         # Added for remote
            "/var/log/fail2ban.log:Fail2Ban Log:remote" # Added for remote
            "/var/log/kern.log:Kernel Log:remote"       # Added for remote
            "/var/log/syslog:System Log:remote"         # Added for remote
        )

        for log in "${logs[@]}"; do
            IFS=':' read -r path name location <<< "$log"
            if [ "$location" = "local" ]; then
                if [ -f "$path" ]; then
                    log_size=$(du -h "$path" | cut -f1)
                    local_logs+=("✓ $name:$log_size")
                else
                    local_logs+=("✗ $name:Not Found")
                fi
            else
                remote_log=$(ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $path && du -h $path || echo 'Not Found'")
                if [[ $remote_log == *"Not Found"* ]]; then
                    remote_logs+=("✗ $name:Not Found")
                else
                    log_size=$(echo "$remote_log" | cut -f1)
                    remote_logs+=("✓ $name:$log_size")
                fi
            fi
        done

        # Print the logs side by side
        max_lines=$((${#local_logs[@]} > ${#remote_logs[@]} ? ${#local_logs[@]} : ${#remote_logs[@]}))

        printf "\e[36m%-36s %-10s  \e[36m%-36s %-10s\e[0m\n" "Local Logs:" "Size:" "Remote Logs:" "Size:"
        for ((i = 0; i < max_lines; i++)); do
            local_log=${local_logs[i]:-""}
            remote_log=${remote_logs[i]:-""}

            local_name=$(echo "$local_log" | cut -d':' -f1)
            local_size=$(echo "$local_log" | cut -d':' -f2)

            remote_name=$(echo "$remote_log" | cut -d':' -f1)
            remote_size=$(echo "$remote_log" | cut -d':' -f2)

            printf "   \e[32m%-36s\e[0m : \e[32m%-10s\e[0m  \e[32m%-36s\e[0m : \e[32m%-10s\e[0m\n" "$local_name" "$local_size" "$remote_name" "$remote_size"
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
            > "$RUN_LOG" # Clear the RUN_LOG after displaying errors
        else
            log_message green "<----[No errors detected during the Local script execution.]---->"
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

# Announce the version
log_message cyan "Starting script version $VERSION"

# Backup log file if it exists
if [ -f "$LOG_FILE" ]; then
    {
        log_message yellow "Backing up existing log file..."
        cat "$LOG_FILE" >> "$BACKUP_LOG_FILE"
    } || handle_error "backup_log_file" "$?"
fi

# Function to generate and display system info
function get_system_identification() {
    {
        echo -e "\n\e[36mSystem Identification:\e[0m"
        echo

        # System Info
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Hostname:" "$(hostname)"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Operating System:" "$(lsb_release -d | cut -f2)"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Kernel Version:" "$(uname -r)"
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Uptime:" "$(uptime | awk '{print $3,$4,$5}')"

        # CPU Info
        cpu_info=$(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//')
        cpu_cores=$(lscpu | grep '^CPU(s):' | awk '{print $3}')
        printf "\e[36m%-18s\e[0m \e[32m%s (%s cores)\e[0m\n" "CPU Info:" "$cpu_info" "$cpu_cores"

        # GPU Info
        gpu_info=$(lspci | grep -i vga | sed 's/.*: //')
        printf "\e[36m%-18s\e[0m \e[32m%s\e[0m\n" "Graphics Card:" "$gpu_info"

        # Memory Info
        total_mem=$(free -h | awk '/^Mem:/ {print $2}')
        used_mem=$(free -h | awk '/^Mem:/ {print $3}')
        printf "\e[36m%-18s\e[0m \e[32m%s / %s\e[0m\n" "Memory Info:" "$used_mem" "$total_mem"

        # Disk Info
        echo -e "\e[36mDisk Info:\e[0m"
        echo -e "\e[36mDrives:\e[0m"
        printf "\e[36m%-10s %-30s %-10s %-10s %-20s\e[0m\n" "Device" "Model" "Size" "Used" "Mountpoint"

        # List all block devices
        lsblk -o NAME,MODEL,SIZE,TYPE,MOUNTPOINT | awk '{ if (NR > 1) print }' | while read -r name model size type mountpoint; do
            if [[ "$type" == "disk" || "$type" == "part" ]]; then
                device="/dev/$name"
                # Get used space
                used=$(df -h "$device" | awk 'NR==2 {print $3}' || echo "N/A")
                # Display information
                printf "  \e[32m%-10s %-30s %-10s %-10s %-20s\e[0m\n" "$name" "$model" "$size" "$used" "${mountpoint:-N/A}"
            fi
        done

        # Network Info
        echo -e "\n\e[36mNetwork Info:\e[0m"
        ifconfig | grep -A 1 '^eth' | awk '{print $1, $2}' | while read -r iface description; do
            printf "  \e[36m%-12s\e[0m \e[32m%s\e[0m\n" "$iface" "$description"
        done
        ip -br addr show | grep -v '^lo' | while read -r iface ip; do
            printf "  \e[36m%-12s\e[0m \e[32m%s\e[0m\n" "$iface" "$ip"
        done

        echo
    } || handle_error "get_system_identification" "$?"
}



# Error handling function
function handle_error() {
    echo "Error executing $1: $2"
    exit 1
}

# Run system identification
chaos_monkey
get_system_identification
get_log_info

# Function to backup the script only if it's changed
backup_script() {
    {
        log_message yellow "Backing up script..."

        # Verify write permissions for BACKUP_DIR2
        if [[ ! -w "$BACKUP_DIR2" ]]; then
            log_message red "Error: No write permissions for $BACKUP_DIR2. Backup aborted."
            exit 1
        fi

        # Get the latest backup file if it exists
        latest_backup=$(find "$BACKUP_DIR" -name "$(basename "$0")_*.sh" -type f -print0 2> /dev/null | xargs -0 ls -t | head -n 1)

        # Compare the current script with the latest backup
        if [ -f "$latest_backup" ] && cmp -s "$0" "$latest_backup"; then
            log_message green "No changes detected. Backup not needed."
        else
            backup_name="$(basename "$0")_$(date +%Y%m%d%H%M%S).sh"
            if cp "$0" "$BACKUP_DIR/$backup_name"; then
                log_message green "Script backed up successfully."
            else
                log_message red "Failed to backup script to $BACKUP_DIR."
                exit 1
            fi
        fi

        # Always copy the script to the second backup location
        second_backup_name="$(basename "$0")_$(date +%Y%m%d%H%M%S).sh"
        if cp "$0" "$BACKUP_DIR2/$second_backup_name"; then
            log_message green "Script backed up to second location successfully."
        else
            log_message red "Failed to backup script to $BACKUP_DIR2."
            exit 1
        fi

    } || handle_error "backup_script" "$?"
}

# Backup the script
backup_script

# Function to check sudo permissions
check_sudo_permissions() {
    {
        if ! sudo -A true 2> /dev/null; then
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

        echo
        log_message blue "$(printf '\e[3mUpdating package list...\e[0m')"
        echo
        if ! sudo -A apt-get update 2>&1 | tee -a "$LOG_FILE"; then
            log_message red "Error: Failed to update package list"
            return 1
        fi

        echo
        log_message blue "$(printf '\e[3mUpgrading packages...\e[0m')"
        echo
        if ! sudo -A apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"; then
            log_message red "Error: Failed to upgrade packages"
            return 1
        fi

        echo
        log_message blue "$(printf '\e[3mPerforming distribution upgrade...\e[0m')"
        echo
        if ! sudo -A apt-get dist-upgrade -y 2>&1 | tee -a "$LOG_FILE"; then
            log_message red "Error: Failed to perform distribution upgrade"
            return 1
        fi

        echo
        log_message blue "$(printf '\e[3mRemoving unnecessary packages...\e[0m')"
        echo
        if ! sudo -A apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"; then
            log_message red "Error: Failed to remove unnecessary packages"
            return 1
        fi

        echo
        log_message blue "$(printf '\e[3mCleaning up...\e[0m')"
        echo
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

# Verify the checksum
echo
log_message blue "$(printf '\e[3mVerifying script checksum on remote server...\e[0m')"
echo
verify_checksum

# Run the script on the remote server
echo
log_message blue "$(printf '\e[3mExecuting remote update script...\e[0m')"
echo
if ! ssh "$REMOTE_USER@$REMOTE_HOST" "$REMOTE_SCRIPT_REMOTE"; then
    log_message red "Failed to execute remote script. Check permissions and script content."
    exit 1
fi

# Retrieve remote log
echo
log_message blue "$(printf '\e[3mRetrieving remote log file...\e[0m')"
echo
scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_LOG" "$BACKUP_REMOTE_LOG"

log_message cyan "Remote log backed up at $BACKUP_LOG_FILE"

# Final log and backup
echo
log_message green "Backing up Local logs"
echo
cp "$LOG_FILE" "$BACKUP_DIR/$(basename $LOG_FILE)_$(date +%Y%m%d%H%M%S).log"
cp "$LOG_FILE" "$BACKUP_LOG_FILE"

# Check for errors
chaos_monkey
check_run_log

log_message cyan "         {{[[[**Completed, Local Script finished.**]]]}}"

# Append to changelog if version is new
echo
log_message blue "Checking for new version..."
echo

LAST_LOGGED_VERSION=$(grep -oP '(?<=Script version )\S+' "$CHANGELOG_FILE" | tail -1)
if [ "$VERSION" != "$LAST_LOGGED_VERSION" ]; then
    echo
    log_message blue "Updating changelog..."
    echo
    cat << EOF >> "$CHANGELOG_FILE"
[$(date +"%Y-%m-%d %H:%M:%S")] Script version $VERSION
- Log file error parsing and displaying
EOF

else
    echo
    log_message blue "Version $VERSION is already logged. No changes made to changelog."
    echo
fi

# Retrieves the last position read from a log file
get_last_position() {
    local log_file="$1"
    local position_file="$CACHE_DIR/$(basename "$log_file").pos"
    if [ -f "$position_file" ]; then
        cat "$position_file"
    else
        echo 0
    fi
}

# Saves the last position read from a log file
set_last_position() {
    local log_file="$1"
    local position="$2"
    local position_file="$CACHE_DIR/$(basename "$log_file").pos"
    echo "$position" > "$position_file"
}

source /home/ageorge/Desktop/log_functions.sh
export -f get_last_position
export -f set_last_position

# Validation and setup section
setup_and_validate() {
    # Create cache directory if it doesn't exist
    if [ ! -d "$CACHE_DIR" ]; then
        mkdir -p "$CACHE_DIR"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create cache directory $CACHE_DIR"
            exit 1
        fi
    fi

    # Set proper permissions for cache directory
    chmod 700 "$CACHE_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set permissions for cache directory $CACHE_DIR"
        exit 1
    fi

    # Create last run file if it doesn't exist
    if [ ! -f "$LAST_RUN_FILE" ]; then
        touch "$LAST_RUN_FILE"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create last run file $LAST_RUN_FILE"
            exit 1
        fi
    fi

    # Set proper permissions for last run file
    chmod 600 "$LAST_RUN_FILE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set permissions for last run file $LAST_RUN_FILE"
        exit 1
    fi

    # Validate remote access if remote logs are configured
    if [[ "${logs[@]}" =~ ":remote" ]]; then
        ssh -q -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_USER@$REMOTE_HOST" exit
        if [ $? -ne 0 ]; then
            echo "Error: Cannot connect to remote host $REMOTE_HOST as $REMOTE_USER"
            echo "Please ensure SSH key-based authentication is set up correctly."
            exit 1
        fi
    fi

    # Check if 'parallel' is installed
    if ! command -v parallel &> /dev/null; then
        echo "Error: 'parallel' command not found. Please install GNU Parallel."
        echo "On Ubuntu/Debian: sudo apt-get install parallel"
        echo "On macOS with Homebrew: brew install parallel"
        exit 1
    fi

    echo "Setup and validation completed successfully."
}

# Call the setup and validation function
setup_and_validate

# Log Information Function
# Define local and remote log paths
logs=(
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
    "$LOCAL_UPDATE_ERROR:Local Error Log:local"
    "$LOCAL_UPDATE_DEBUG:Local Debug Log:local"
    "$centralized_error_log:Centralized Error Log:local"
    "$SEEN_ERRORS_FILE:Seen Errors File:local"
    "/var/log/auth.log:Auth Log:remote"
    "/var/log/boot.log:Boot Log:remote"
    "/var/log/dpkg.log:DPKG Log:remote"
    "/var/log/fail2ban.log:Fail2Ban Log:remote"
    "/var/log/kern.log:Kernel Log:remote"
    "/var/log/syslog:System Log:remote"
)

# Function to get log information
get_log_info() {
    echo -e "\n\e[36mLog Information:\e[0m"
    local local_logs=()
    local remote_logs=()

    for log in "${logs[@]}"; do
        IFS=':' read -r path name location <<< "$log"
        if [ "$location" = "local" ]; then
            if [ -f "$path" ]; then
                log_size=$(du -h "$path" | cut -f1)
                local_logs+=("✓ $name:$log_size")
            else
                local_logs+=("✗ $name:Not Found")
            fi
        else
            remote_log=$(ssh "$REMOTE_USER@$REMOTE_HOST" "test -f $path && du -h $path || echo 'Not Found'")
            if [[ $remote_log == *"Not Found"* ]]; then
                remote_logs+=("✗ $name:Not Found")
            else
                log_size=$(echo "$remote_log" | cut -f1)
                remote_logs+=("✓ $name:$log_size")
            fi
        fi
    done

    max_lines=$((${#local_logs[@]} > ${#remote_logs[@]} ? ${#local_logs[@]} : ${#remote_logs[@]}))

    printf "\e[36m%-36s %-10s  \e[36m%-36s %-10s\e[0m\n" "Local Logs:" "Size:" "Remote Logs:" "Size:"
    for ((i = 0; i < max_lines; i++)); do
        local_log=${local_logs[i]:-""}
        remote_log=${remote_logs[i]:-""}

        local_name=$(echo "$local_log" | cut -d':' -f1)
        local_size=$(echo "$local_log" | cut -d':' -f2)

        remote_name=$(echo "$remote_log" | cut -d':' -f1)
        remote_size=$(echo "$remote_log" | cut -d':' -f2)

        printf "   \e[32m%-36s\e[0m : \e[32m%-10s\e[0m  \e[32m%-36s\e[0m : \e[32m%-10s\e[0m\n" "$local_name" "$local_size" "$remote_name" "$remote_size"
    done

    echo -e "\n"
}

# Trap errors and signals
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >> "$RUN_LOG"' ERR
trap 'echo "Script terminated prematurely" >> "$RUN_LOG"; exit 1' SIGINT SIGTERM

# Error classification patterns
declare -A error_patterns=(
    ["PermissionError"]="permission denied"
    ["FileNotFoundError"]="file not found"
    ["MemoryError"]="out of memory"
    ["OSError"]="OSError"
    ["DatabaseError"]="DatabaseError"
    ["OperationalError"]="OperationalError"
    ["IntegrityError"]="IntegrityError"
    ["TypeError"]="TypeError"
    ["ValueError"]="ValueError"
    ["KeyError"]="KeyError"
    ["IndexError"]="IndexError"
    ["ConnectionError"]="ConnectionError"
    ["TimeoutError"]="TimeoutError"
    ["URLError"]="URLError"
)

# Function to scan and classify log entries using parallel
scan_and_classify_logs() {
    log_files=("${logs[@]}")
    centralized_error_log="$BACKUP_LOG_DIR/centralized_error_log.log"

    echo -e "\n\e[36mScanning Logs:\e[0m"

    # Define a function to process each log file
    process_log() {
    local log_file="$1"
    local log_name="$2"
    local log_type="$3"
    local last_position=0  # Default to 0 if unset

    # Initialize last_position for local logs
    if [ "$log_type" = "local" ]; then
        if [ -f "$log_file" ]; then
            echo -e "\e[36mScanning Local Log: $log_name\e[0m"
            last_position=$(get_last_position "$log_file")
            # Ensure last_position is a valid integer
            if ! [[ "$last_position" =~ ^[0-9]+$ ]]; then
                last_position=0
            fi
            tail -n +$((last_position + 1)) "$log_file" \
                | while IFS= read -r line; do
                    for error_type in "${!error_patterns[@]}"; do
                        if echo "$line" | grep -qi "${error_patterns[$error_type]}"; then
                            echo -e "\e[31m[ERROR]\e[0m $log_name: $line" >> "$centralized_error_log"
                            echo "$log_name:$line" >> "$SEEN_ERRORS_FILE"
                            break
                        fi
                    done
                done
            # Update last position
            new_last_position=$(wc -l < "$log_file")
            set_last_position "$log_file" $((last_position + new_last_position))
        else
            echo -e "\e[31m[ERROR]\e[0m Log file not found: $log_name"
        fi
    elif [ "$log_type" = "remote" ]; then
        echo -e "\e[36mScanning Remote Log: $log_name\e[0m"
        ssh "$REMOTE_USER@$REMOTE_HOST" "tail -n +1 $log_file" \
            | while IFS= read -r line; do
                for error_type in "${!error_patterns[@]}"; do
                    if echo "$line" | grep -qi "${error_patterns[$error_type]}"; then
                        echo -e "\e[31m[ERROR]\e[0m $log_name: $line" >> "$centralized_error_log"
                        echo "$log_name:$line" >> "$SEEN_ERRORS_FILE"
                        break
                    fi
                done
            done
    fi
}

    # Export the function and variables for parallel execution
    export -f process_log
    export centralized_error_log SEEN_ERRORS_FILE REMOTE_USER REMOTE_HOST error_patterns CACHE_DIR

    # Run the log processing in parallel
    printf "%s\n" "${log_files[@]}" | parallel --colsep ':' process_log '{1}' '{2}' '{3}'

    echo -e "\n\e[32mLog scanning and classification completed.\e[0m"
}

# Call the get_log_info function
get_log_info

# Call the scan_and_classify_logs function
scan_and_classify_logs

echo -e "\nFinished scanning logs."

# Update last run timestamp
date +%s > "$LAST_RUN_FILE"

echo -e "\nFinished scanning logs."

echo -e "\nSummary of new logged errors:"
sort "$centralized_error_log" | uniq -c | sort -rn | head -n 10

# Cleanup old entries from seen errors file (optional)
#if [ -f "$SEEN_ERRORS_FILE" ]; then
#    tail -n 10000 "$SEEN_ERRORS_FILE" > "${SEEN_ERRORS_FILE}.tmp" && mv "${SEEN_ERRORS_FILE}.tmp" "$SEEN_ERRORS_FILE"
#fi
