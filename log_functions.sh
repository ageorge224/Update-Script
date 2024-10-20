#!/bin/bash

# Function to get the last position from a cached file
get_last_position() {
    local log_file="$1"
    local position_file
    position_file="$CACHE_DIR/$(basename "$log_file").pos"
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
    local position_file
    position_file="$CACHE_DIR/$(basename "$log_file").pos"
    echo "$position" >"$position_file"
}

# shellcheck disable=SC1090
# Function to load exclusions from a config file
load_exclusions() {
    local config_file="${1:-/home/ageorge/Desktop/Update-Script/exclusions_config}"
    if [[ -f "$config_file" ]]; then
        # Source the file to load the exclusions array
        source "$config_file"
    else
        exclusions=() # Initialize an empty array if the file doesn't exist
    fi
}

# Function to save exclusions to a config file
save_exclusions() {
    local config_file="${1:-/home/ageorge/Desktop/Update-Script/exclusions_config}"
    {
        echo "exclusions=("
        for exclusion in "${exclusions[@]}"; do
            # Skip empty strings
            if [[ -n "$exclusion" ]]; then
                echo "    \"$exclusion\""
            fi
        done
        echo ")"
    } >"$config_file"
}

# Ensure SUDO_ASKPASS is set
export SUDO_ASKPASS="$HOME/sudo_askpass.sh"
