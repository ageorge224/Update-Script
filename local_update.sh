#!/bin/bash

LOG_FILE="/tmp/local_update.log"
BACKUP_LOG_DIR="$HOME/Desktop"
BACKUP_LOG_FILE="$BACKUP_LOG_DIR/local_update.log"
REMOTE_USER="ageorge"
REMOTE_HOST="192.168.1.248"
REMOTE_SCRIPT_LOCAL="/tmp/remote_update.sh"
REMOTE_SCRIPT_REMOTE="/tmp/remote_update.sh"
SUDO_ASKPASS_PATH="$HOME/sudo_askpass.sh"

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

# Function to display a cascading rainbow effect
function show_rainbow_progress() {
  local message=$1
  local colors=(31 32 33 34 35 36 37 91 92 93 94 95 96)
  local color_index=0

  # Save cursor position
  tput sc

  while kill -0 $! 2>/dev/null; do
    # Clear the current line
    tput el

    # Print the progress message with color
    echo -ne "\e[${colors[color_index]}m$message\e[0m\r"
    color_index=$(( (color_index + 1) % ${#colors[@]} ))
    sleep 0.2

    # Restore cursor position
    tput rc
  done

  # Clear the line and print "Done"
  tput el
  echo -e "\e[32m$message [Done]\e[0m"
}

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
#!/bin/bash

LOG_FILE="/tmp/remote_update.log"
SUMMARY_LOG="/tmp/remote_update_summary.log"
BACKUP_LOG_DIR="$HOME/Desktop"
BACKUP_LOG_FILE="$BACKUP_LOG_DIR/remote_update.log"
SUDO_ASKPASS_PATH="$HOME/sudo_askpass.sh"

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

function handle_error() {
  echo_colored red "Error on line $1"
  exit 1
}

trap 'handle_error $LINENO' ERR

# Ensure log file exists
if [ ! -f $LOG_FILE ]; then
  touch $LOG_FILE
fi
cp $LOG_FILE $BACKUP_LOG_FILE

# Function to display a cascading rainbow effect
function show_rainbow_progress() {
  local message=$1
  local colors=(31 32 33 34 35 36 37 91 92 93 94 95 96)
  local color_index=0

  while kill -0 $! 2>/dev/null; do
    echo -ne "\e[${colors[color_index]}m$message\e[0m\r"
    color_index=$(( (color_index + 1) % ${#colors[@]} ))
    sleep 0.2
  done
  echo -e "\e[32m$message [Done]\e[0m"
}

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

echo_colored cyan "Remote System Identification:"
get_system_identification

echo_colored blue "\nUpdating remote package list..."
sudo -A apt-get update 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Updating package list"

echo_colored blue "\nUpgrading remote packages..."
sudo -A apt-get upgrade -y 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Upgrading packages"

echo_colored blue "\nPerforming remote distribution upgrade..."
sudo -A apt-get dist-upgrade -y 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Performing distribution upgrade"

echo_colored blue "\nRemoving unnecessary remote packages..."
sudo -A apt-get autoremove -y 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Removing unnecessary packages"

echo_colored blue "\nCleaning up remote system..."
sudo -A apt-get clean 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Cleaning up"

echo_colored blue "\nUpdating Pi-hole..."
sudo -A pihole -up 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Updating Pi-hole"

echo_colored blue "\nUpdating Pi-hole gravity (less verbose)..."
sudo -A pihole -g > /tmp/pihole_gravity.log 2>&1 & show_rainbow_progress "Updating Pi-hole gravity"
if grep -q "FTL is listening" /tmp/pihole_gravity.log; then
  echo_colored green "\nPi-hole gravity update completed successfully!"
else
  echo_colored red "\nPi-hole gravity update encountered an issue. Check /tmp/pihole_gravity.log for details."
fi

# Summarize the log
echo_colored blue "\nSummarizing remote update log..."
grep -E '^(Reading|Building|Calculating|Processing)' $LOG_FILE > $SUMMARY_LOG

# Generate summary
echo_colored blue "\nGenerating remote summary report..."
echo -e "Summary of Remote Updates:\n" > $SUMMARY_LOG
if grep -q "Reading package lists..." $LOG_FILE; then
  echo -e "Update Applied: Yes" >> $SUMMARY_LOG
else
  echo -e "Update Applied: No" >> $SUMMARY_LOG
fi

echo -e "\nPi-hole Gravity Log Summary:" >> $SUMMARY_LOG
if grep -q "FTL is listening" /tmp/pihole_gravity.log; then
  echo -e "Pi-hole gravity update successful" >> $SUMMARY_LOG
else
  echo -e "Pi-hole gravity update had issues" >> $SUMMARY_LOG
fi

cat $SUMMARY_LOG

echo_colored green "\nRemote Pi-hole update completed successfully!"
EOF

# Make the remote script executable
chmod +x $REMOTE_SCRIPT_LOCAL

# Update and upgrade functions with cascading rainbow effect
function update_system() {
  echo_colored green "Local System Identification:"
  get_system_identification

  echo_colored blue "\nUpdating package list..."
  sudo -A apt-get update 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Updating package list"

  echo_colored blue "\nUpgrading packages..."
  sudo -A apt-get upgrade -y 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Upgrading packages"

  echo_colored blue "\nPerforming distribution upgrade..."
  sudo -A apt-get dist-upgrade -y 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Performing distribution upgrade"

  echo_colored blue "\nRemoving unnecessary packages..."
  sudo -A apt-get autoremove -y 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Removing unnecessary packages"

  echo_colored blue "\nCleaning up..."
  sudo -A apt-get clean 2>&1 | tee -a $LOG_FILE & show_rainbow_progress "Cleaning up"
}

# Function to execute remote script
function execute_remote_script() {
  echo_colored blue "Copying remote update script..."
  scp $REMOTE_SCRIPT_LOCAL $REMOTE_USER@$REMOTE_HOST:$REMOTE_SCRIPT_REMOTE

  echo_colored blue "Executing remote update script..."
  ssh -t $REMOTE_USER@$REMOTE_HOST "bash $REMOTE_SCRIPT_REMOTE"
}

# Main script execution
echo_colored green "Starting local update..."
update_system

echo_colored green "Starting remote update..."
execute_remote_script

echo_colored green "Update process completed successfully!"
