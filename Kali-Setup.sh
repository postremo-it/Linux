#!/bin/bash

# Check if running as root; if not, re-run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit
fi

echo "Starting consolidated Kali setup script..."

# Preconfigure console-setup to select "Guess optimal character set"
echo "Configuring character set for console font to 'Guess optimal character set'..."
sudo debconf-set-selections <<< 'console-setup console-setup/charmap47 select Guess optimal character set'

# Automatically allow service restarts during libc upgrades
echo "Configuring automatic service restarts during package upgrades..."
sudo debconf-set-selections <<< 'libc6:amd64 libraries/restart-without-asking boolean true'
sudo debconf-set-selections <<< 'libc6:arm64 libraries/restart-without-asking boolean true'

# Set DEBIAN_FRONTEND to noninteractive to auto-confirm prompts, including PostgreSQL
export DEBIAN_FRONTEND=noninteractive

# Suppress PostgreSQL prompt about obsolete version
echo "Setting PostgreSQL configuration to suppress obsolete version prompt..."
sudo debconf-set-selections <<< 'postgresql-common postgresql-common/obsolete-major note'

# Run update and upgrade in non-interactive mode to avoid prompts
echo "Updating system packages..."
sudo apt-get update -y && sudo apt-get dist-upgrade -y

# Install VM tools for clipboard and drag-and-drop support
echo "Installing VM tools (spice-vdagent and qemu-guest-agent)..."
sudo apt-get install -y spice-vdagent qemu-guest-agent

# Setup WiFi drivers; only proceed if the directory does not exist
DRIVER_DIR="/home/kali/Desktop/WiFi_Drivers"
if [ ! -d "$DRIVER_DIR" ]; then
    echo "Setting up WiFi drivers..."
    mkdir -p "$DRIVER_DIR"
    cd "$DRIVER_DIR"
    sudo git clone https://github.com/Khatcode/AWUS036ACH-Automated-Driver-Install.git
    cd AWUS036ACH-Automated-Driver-Install
    # Automatically select "1" for Realtek drivers installation
    echo "Running Alfasetup.sh with automatic input selection..."
    echo "1" | sudo ./Alfasetup.sh
else
    echo "WiFi drivers already set up; skipping..."
fi

# Install additional tools if they are not already installed
if ! command -v hcxdumptool &> /dev/null; then
    echo "Installing hcxtools..."
    sudo apt-get install -y hcxtools
fi

# Unpack rockyou wordlist if not already unpacked
WORDLIST_PATH="/usr/share/wordlists/rockyou.txt"
if [ -f "${WORDLIST_PATH}.gz" ]; then
    echo "Unpacking rockyou wordlist..."
    sudo gzip -d "${WORDLIST_PATH}.gz"
else
    echo "rockyou wordlist already unpacked; skipping..."
fi

echo "Setup complete. Rebooting system..."
sudo reboot
