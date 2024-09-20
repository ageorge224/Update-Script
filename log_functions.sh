#!/bin/bash

# Variables

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
CACHE_DIR="$HOME/.logscan_cache"
temp_error_counts="$CACHE_DIR/temp_error_counts.txt"
LAST_RUN_FILE="$CACHE_DIR/last_run"

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
