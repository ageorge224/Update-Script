#!/bin/bash

# Variables

SCRIPT_NAME="local_update.sh"
REMOTE_USER="ageorge"
pihole="192.168.1.248"
pihole2="192.168.1.145"
AG_backup="192.168.1.238"
BACKUP_LOG_DIR="/home/ageorge/.local_update_logs"
BACKUP_DIR="/home/ageorge/Documents/Backups"
BACKUP_DIR2="/mnt/Nvme500Data/Update Backups"
REMOTE_LOG="/home/ageorge/Desktop/remote_update.log"
CHANGELOG_FILE="$BACKUP_DIR/changelog.txt"
LOG_FILE="/tmp/local_update.log"
pihole_log="$BACKUP_LOG_DIR/remote_update.log"
pihole2_log="$BACKUP_LOG_DIR/remote_update2.log"
AG_Backup_log="$BACKUP_LOG_DIR/remote_update3.log"
BACKUP_LOG_FILE="$BACKUP_LOG_DIR/local_update.log"
pihole_local="/tmp/remote_update.sh"
pihole2_local="/tmp/remote_update2.sh"
AG_Backup_local="/tmp/remote_update3.sh"
pihole_Remote="/tmp/remote_update.sh"
pihole2_Remote="/tmp/remote_update2.sh"
AG_Backup_Remote="/tmp/remote_update3.sh"
SUDO_ASKPASS_PATH="$HOME/sudo_askpass.sh"
RUN_LOG="/tmp/run_log.txt"
CHECKSUM_FILE="/tmp/remote_update.sh.md5"
LOCAL_UPDATE_ERROR="$BACKUP_LOG_DIR/local_update_error.log"
LOCAL_UPDATE_DEBUG="$BACKUP_LOG_DIR/local_update_debug.log"
centralized_error_log="$BACKUP_LOG_DIR/centralized_error_log.log"
SEEN_ERRORS_FILE="$BACKUP_LOG_DIR/seen_errors.log"
CACHE_DIR="$HOME/.logscan_cache"
temp_error_counts="$CACHE_DIR/temp_error_counts.txt"
LAST_RUN_FILE="$CACHE_DIR/last_run"
DRY_RUN=false

# Function to get the last position from a cached file
get_last_position() {
    local log_file="$1"
    local position_file="$CACHE_DIR/$(basename "$log_file").pos"
    if [ -f "$position_file" ]; then
        cat "$position_file"
    else
        echo 0
    fi
}

# Function to set the last position in a cached file
set_last_position() {
    local log_file="$1"
    local position="$2"
    local position_file="$CACHE_DIR/$(basename "$log_file").pos"
    echo "$position" >"$position_file"
}

# Ensure SUDO_ASKPASS is set
export SUDO_ASKPASS="$HOME/sudo_askpass.sh"
