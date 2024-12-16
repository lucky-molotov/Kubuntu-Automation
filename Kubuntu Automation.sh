#!/bin/bash
# Define snapshot name
SNAPSHOT_NAME="pre-setup-$(date +'%Y-%m-%d_%H-%M-%S')"
export SNAPSHOT_NAME
LOG_FILE="/var/log/setup-script.log"
ERROR_LOG_FILE="/var/log/setup-script-error.log"

# Function to log messages to both console and log file, with separate error logging
log_message() {
    local message=$1
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message=$1
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: $message" | tee -a "$ERROR_LOG_FILE"
}

# Function to check command success and offer recovery options (Continue, Skip, Exit)
check_command() {
    local step_name=$1
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_message "Error: $step_name failed with exit code $exit_code."
        
        # Log to error file if in non-interactive mode
        log_error "$step_name failed with exit code $exit_code."
        # Ask the user what they want to do
        while true; do
            read -r -p "Do you want to (c)ontinue, (s)kip, or (e)xit the script? (c/s/e): " choice
            case "$choice" in
                c|C) 
                    log_message "User chose to continue. Moving to the next step."
                    break
                    ;;
                s|S) 
                    log_message "User chose to skip this step."
                    break
                    ;;
                e|E) 
                    log_message "User chose to exit the script."
                    exit 1
                    ;;
                *)
                    echo "Invalid option. Please enter 'c' to continue, 's' to skip, or 'e' to exit."
                    ;;
            esac
        done
    else
        log_message "$step_name completed successfully."
    fi
}

# Function to check if a package is installed
is_package_installed() {
    dpkg -l | grep -q "$1"
}

# Function to check network availability
check_network() {
    ping -c 1 google.com &>/dev/null
    if ! sudo apt-get update && sudo apt-get upgrade -y; then
    log_message "System update and upgrade failed."
    exit 1
fi
}

# Check network before proceeding
log_message "Checking network connectivity..."
check_network

# Create a Timeshift snapshot before proceeding with the installation
log_message "Creating a Timeshift snapshot..."
DEVICE=$(lsblk -o NAME,SIZE,MOUNTPOINT | grep '^/dev' | awk '{print $1}' | head -n 1)
sudo timeshift --create --comments "Pre-setup snapshot" --tags D --snapshot-device "$DEVICE"
check_command "Timeshift snapshot creation"

# Update and upgrade the system
log_message "Updating and upgrading the system..."
if ! sudo apt-get update && sudo apt-get upgrade -y; then
    log_message "System update and upgrade failed."
    exit 1
fi
check_command "System update and upgrade"

# Add multiverse repository for additional software (e.g., multimedia codecs)
log_message "Adding multiverse repository..."
if ! is_package_installed "software-properties-common"; then
    sudo apt-get install -y software-properties-common
    check_command "Installing software-properties-common"
fi
sudo add-apt-repository multiverse -y
check_command "Adding multiverse repository"
sudo apt-get update

# Check and install snapd if necessary
if ! command -v snap &>/dev/null; then
    log_message "snapd not found, installing snapd..."
    sudo apt-get install -y snapd
    check_command "Installing snapd"
fi

# Install Kubuntu restricted extras and other essential packages in one go
log_message "Installing necessary packages (restricted extras, apt-fast, Flatpak, Snap)..."
if ! is_package_installed "apt-fast"; then
    sudo apt-get install -y apt-fast
    check_command "Installing apt-fast"
fi
if ! is_package_installed "flatpak"; then
    sudo apt-get install -y flatpak
    check_command "Installing flatpak"
fi
if ! is_package_installed "snapd"; then
    sudo apt-get install -y snapd
    check_command "Installing snapd"
fi
sudo apt-get install -y kubuntu-restricted-extras apt-fast flatpak gnome-software-plugin-flatpak snapd
check_command "Installing Kubuntu extras and utilities"

# Install TLP (power management for laptops)
log_message "Installing TLP for power management..."
if ! is_package_installed "tlp"; then
    sudo add-apt-repository ppa:linrunner/tlp -y
    check_command "Adding TLP PPA"
    sudo apt-get update
    sudo apt-get install -y tlp
    check_command "Installing TLP"
    sudo tlp start
    tlp-stat -s
else
    log_message "TLP is already installed."
fi

# Install essential software and development libraries
log_message "Installing essential packages..."
sudo apt-get install -y python3 python3-pip build-essential neofetch git vlc \
    code --classic steam virtualbox nextcloud-desktop playonlinux firefox \
    wine wine-staging heroic-games-launcher lutris vulkan-utils mangohud clamav \
    mesa-utils bluetooth bluez bluez-tools sixad ufw
check_command "Installing essential software"

# Install Snap packages
log_message "Installing Snap packages..."
sudo snap install spt
sudo snap install gitkraken
sudo snap install sublime-text --classic
check_command "Installing Snap packages"

# Install Flatpak packages
log_message "Installing Flatpak packages..."
flatpak install -y flathub io.github.shiftey.Desktop
check_command "Installing Flatpak packages"

# Install Proton VPN
log_message "Installing Proton VPN..."
# Step 1: Download Proton VPN's official package key and repository (stable version)
if ! wget --tries=3 --timeout=10 --spider https://protonvpn.com/download/protonvpn_public.asc; then
    log_message "Error: Unable to reach ProtonVPN key URL. Skipping ProtonVPN installation."
else
    wget -q -O - https://protonvpn.com/download/protonvpn_public.asc | sudo tee /etc/apt/trusted.gpg.d/protonvpn.asc
    check_command "Downloading ProtonVPN key"
    echo "deb http://repo.protonvpn.com/debian stable main" | sudo tee /etc/apt/sources.list.d/protonvpn.list
    check_command "Adding ProtonVPN repository"
fi

# Step 2: Install Proton VPN
sudo apt-get update
sudo apt-get install -y protonvpn
check_command "Installing ProtonVPN"

# Install additional Qt libraries and themes
log_message "Installing additional Qt libraries and themes..."
sudo apt install -y libqt5svg5 qml-module-qtquick-controls
sudo add-apt-repository ppa:papirus/papirus -y
check_command "Adding Papirus PPA"
sudo apt-get update
sudo apt install -y qt6-style-kvantum qt6-style-kvantum-themes
check_command "Installing Qt libraries and themes"

# Install additional apps and tools
log_message "Installing more tools..."
sudo apt install -y fail2ban docker kdeconnect krita kdenlive p7zip-full bleachbit virtualenv
check_command "Installing additional tools"

# Ensure cron is installed and running
log_message "Checking if cron is installed..."
if ! command -v cron &> /dev/null; then
    log_message "Installing cron..."
    sudo apt-get install -y cron
    check_command "Installing cron"
fi

# Start cron service if not running
log_message "Starting cron service..."
sudo systemctl enable cron
sudo systemctl start cron
check_command "Starting cron service"

# Set up hosts file update every day at 2 AM and on startup
log_message "Setting up automated hosts file update every day at 2 AM and on startup..."
# Backup current hosts file with timestamp
sudo mv "/etc/hosts" "/etc/hosts.bak.$(date +'%Y-%m-%d_%H-%M-%S')"

# Check if the URL is available before downloading
URL="https://hosts.ubuntu101.co.za/hosts"
if ! wget --tries=3 --timeout=10 --spider "$URL"; then
    log_message "Error: Unable to reach $URL. Hosts file update skipped."
else
    sudo wget "$URL" -O /etc/hosts
    if ! sudo wget "$URL" -O /etc/hosts; then
        log_error "Failed to download hosts file from $URL."
    fi
    sudo wget https://hosts.ubuntu101.co.za/superhosts.deny -O /etc/hosts.deny
    check_command "Updating hosts file"
fi

# Setup cron job for daily update at 2 AM
log_message "Setting cron job for daily hosts file update at 2 AM..."
(crontab -l ; echo "0 2 * * * wget -q -O /etc/hosts $URL && wget -q -O /etc/hosts.deny https://hosts.ubuntu101.co.za/superhosts.deny") | crontab -
check_command "Setting up daily cron job for hosts file update"

# Set up the hosts file update on startup
log_message "Setting up hosts file update on system startup..."
sudo mkdir -p /etc/cron.d
echo "@reboot root wget -q -O /etc/hosts $URL && wget -q -O /etc/hosts.deny https://hosts.ubuntu101.co.za/superhosts.deny" | sudo tee /etc/cron.d/hosts-update-on-startup
check_command "Setting up hosts file update on startup"

# Output success message
log_message "Setup complete! All necessary software installed, and hosts file will now be updated daily at 2 AM and on startup."

# Cleanup and optional reboot (only if not running in a non-interactive environment like SSH)
log_message "Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get clean

# Check if the script is running interactively or in a non-interactive environment (e.g., SSH)
if [ -t 1 ]; then
    log_message "Rebooting system now..."
    sudo shutdown -r now
else
    log_message "Reboot is required. Please restart your system manually."
fi
