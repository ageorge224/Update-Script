#!/bin/bash

VERSION="1.0.0"
SCRIPT_NAME="local_update.sh"
BACKUP_DIR="/home/ageorge/Documents/Backups"
LOG_FILE="/tmp/local_update.log"
BACKUP_LOG_DIR="$HOME/Desktop"
BACKUP_LOG_FILE="$BACKUP_LOG_DIR/local_update.log"
REMOTE_USER="ageorge"
REMOTE_HOST="192.168.1.248"
REMOTE_SCRIPT_LOCAL="/tmp/remote_update.sh"
REMOTE_SCRIPT_REMOTE="/tmp/remote_update.sh"
SUDO_ASKPASS_PATH="$HOME/sudo_askpass.sh"
CHANGELOG_FILE="$BACKUP_DIR/changelog.txt"

# Export SUDO_ASKPASS
export SUDO_ASKPASS="$SUDO_ASKPASS_PATH"

# Function to display messages in color
function echo_colored() {
  local color=$1
  local message=$2
  case $color in
    red) echo -e "\e[31m$message\e[0m" | tee -a $LOG_FILE ;;
    green) echo -e "\e[32m$message\e[0m" | tee -a $LOG_FILE ;;
    yellow) echo -e "\e[33m$message\e[0m" | tee -a $LOG_FILE ;;
    blue) echo -e "\e[34m$message\e[0m" | tee -a $LOG_FILE ;;
    magenta) echo -e "\e[35m$message\e[0m" | tee -a $LOG_FILE ;;
    cyan) echo -e "\e[36m$message\e[0m" | tee -a $LOG_FILE ;;
    white) echo -e "\e[37m$message\e[0m" | tee -a $LOG_FILE ;;
    *) echo "$message" | tee -a $LOG_FILE ;;
  esac
}

# Function to handle errors
function handle_error() {
  echo_colored red "Error on line $1"
  exit 1
}

trap 'handle_error $LINENO' ERR

# Function to check if a command exists
function command_exists() {
  command -v "$1" &> /dev/null
}

# Ensure required commands are available
for cmd in apt-get ssh scp; do
  if ! command_exists $cmd; then
    echo_colored red "Error: $cmd is not installed."
    exit 1
  fi
done

# Ensure log file exists and create backup
if [ ! -f $LOG_FILE ]; then
  touch $LOG_FILE
fi
cp $LOG_FILE "$BACKUP_LOG_FILE"

# Function to get system identification
function get_system_identification() {
  echo -e "\n\e[36mSystem Identification:\e[0m"
  echo -e "\e[36mHostname:\e[0m \e[32m$(hostname)\e[0m"
  echo -e "\e[36mOperating System:\e[0m \e[32m$(lsb_release -d | cut -f2)\e[0m"
  echo -e "\e[36mKernel Version:\e[0m \e[32m$(uname -r)\e[0m"
  echo -e "\e[36mLog File Path:\e[0m \e[32m$LOG_FILE\e[0m"
  echo -e "\e[36mLog File Size:\e[0m \e[32m$(du -h $LOG_FILE | cut -f1)\e[0m"
  echo -e "\e[36mBackup Log File:\e[0m \e[32m$BACKUP_LOG_FILE\e[0m"
}

# Create the remote update script if it doesn't exist
cat << 'EOF' > $REMOTE_SCRIPT_LOCAL
# Remote script content (remains the same)
EOF

# Make the remote script executable
chmod +x $REMOTE_SCRIPT_LOCAL

# Update and upgrade functions
function update_system() {
  echo_colored green "Local System Identification:"
  get_system_identification

  echo_colored blue "\nUpdating package list..."
  sudo -A apt-get update 2>&1 | tee -a $LOG_FILE

  echo_colored blue "\nUpgrading packages..."
  sudo -A apt-get upgrade -y 2>&1 | tee -a $LOG_FILE

  echo_colored blue "\nPerforming distribution upgrade..."
  sudo -A apt-get dist-upgrade -y 2>&1 | tee -a $LOG_FILE

  echo_colored blue "\nRemoving unnecessary packages..."
  sudo -A apt-get autoremove -y 2>&1 | tee -a $LOG_FILE

  echo_colored blue "\nCleaning up..."
  sudo -A apt-get clean 2>&1 | tee -a $LOG_FILE
}

# Function to execute remote script
function execute_remote_script() {
  echo_colored blue "Copying remote update script..."
  scp $REMOTE_SCRIPT_LOCAL $REMOTE_USER@$REMOTE_HOST:$REMOTE_SCRIPT_REMOTE

  echo_colored blue "Executing remote update script..."
  ssh -t $REMOTE_USER@$REMOTE_HOST "bash $REMOTE_SCRIPT_REMOTE"
}

# Function to backup the script with versioning
function backup_script() {
  local versioned_backup="$BACKUP_DIR/${SCRIPT_NAME%.sh}_v${VERSION}.sh"
  cp "$0" "$versioned_backup"
  echo "[$(date)] - Version $VERSION backed up as $versioned_backup" >> "$CHANGELOG_FILE"
  echo_colored green "Script backed up as $versioned_backup"
}

# Main script execution
echo_colored green "Starting local update..."
update_system

echo_colored green "Starting remote update..."
execute_remote_script

# Backup script with versioning
backup_script

echo_colored green "Update process completed successfully!"
