local_update.sh

Overview
local_update.sh is a Bash script designed to automate the process of updating and maintaining a Linux system. This script handles tasks such as updating and upgrading packages, creating backups, and verifying file integrity using checksums. Additionally, it includes functions to gather and display system identification information, as well as log management capabilities.

Features
-Automated System Updates: The script performs package updates, upgrades, distribution upgrades, and cleans up unnecessary packages.
-Checksum Verification: Ensures the integrity of files by creating and verifying checksums.
-ogging: Logs actions with colored output and timestamps. The logs are backed up and displayed in a user-friendly format.
-System Identification: Displays detailed information about the system, including CPU, GPU, memory, and disk usage.
-Remote Update Functionality: Capable of performing updates on a remote system using SSH.
Usage

Prerequisites

Ensure that the following commands are installed on your system:
-apt-get
-ssh
-scp
-md5sum
You should also set up a sudo_askpass.sh script that allows the script to run sudo commands without requiring user input.

Running the Script
Clone the repository:

bash
Copy code
git clone https://github.com/ageorge224/Update-Script.git

Navigate to the script directory:

bash
Copy code
cd yourrepository

Make the script executable:

bash
Copy code
chmod +x local_update.sh

Run the script:

bash
Copy code
./local_update.sh

Script Workflow

Logging:

-Initializes the log file at /tmp/local_update.log.
-Backups existing log files to a specified directory (~/Desktop/local_update.log).
-Displays log information and paths.

System Identification:
-Displays detailed system information including hostname, OS, kernel version, CPU, GPU, memory, and disk information.

Checksum Verification:
-Creates a checksum for the local script and verifies it against a remote script.

Performing Updates:
-Updates the local package list, upgrades packages, performs a distribution upgrade, removes unnecessary packages, and cleans up.

Remote Update:
-If required, the script can generate and execute a remote update script via SSH.

Error Handling
-The script includes traps for handling errors and signals, ensuring that it logs any issues and exits gracefully.

Backup
-The script automatically creates backups of itself if changes are detected. The backups are stored in /home/ageorge/Documents/Backups.

System Logs
-The script checks and logs various system logs such as auth.log, syslog, and Pi-hole logs from a remote server.

License
-This project is licensed under the MIT License - see the LICENSE file for details.

Contributing
Please feel free to submit issues or pull requests to improve this script.

Version
Current version: 1.0.28
