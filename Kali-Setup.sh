#!/bin/bash

# Set TERM environment variable to suppress potential debconf warnings
export TERM=xterm

# Check if running as root; if not, re-run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit
fi

echo "Starting consolidated Kali setup script..."

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts throughout the script
export DEBIAN_FRONTEND=noninteractive

# Remove console-setup package to avoid character set prompt during upgrades
echo "Removing console-setup to avoid character set configuration prompt..."
sudo apt-get remove -y console-setup

# Automatically allow service restarts during libc upgrades
echo "Configuring automatic service restarts during package upgrades..."
sudo debconf-set-selections <<< 'libc6:amd64 libraries/restart-without-asking boolean true'
sudo debconf-set-selections <<< 'libc6:arm64 libraries/restart-without-asking boolean true'

# Suppress PostgreSQL prompt about obsolete version
echo "Setting PostgreSQL configuration to suppress obsolete version prompt..."
sudo debconf-set-selections <<< 'postgresql-common postgresql-common/obsolete-major note'

# Run update and upgrade in non-interactive mode to avoid prompts
echo "Updating system packages..."
sudo apt-get update -y && sudo apt-get dist-upgrade -y

# Install VM tools for clipboard and drag-and-drop support
echo "Installing VM tools (spice-vdagent and qemu-guest-agent)..."
sudo apt-get install -y spice-vdagent qemu-guest-agent

# Set up WiFi drivers directly, removing the need for a separate script
echo "Setting up Realtek WiFi drivers without external script..."

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Use 'sudo' or log in as the root user."
        exit 1
    fi
}

# Detect Linux distribution and set package manager
detect_distribution() {
    if [[ -f /etc/debian_version ]]; then
        PACKAGE_MANAGER="apt-get"
    elif [[ -f /etc/redhat-release ]]; then
        PACKAGE_MANAGER="dnf"
    else
        echo "Unsupported Linux distribution. Exiting."
        exit 1
    fi
}

# Install git if not present
install_git() {
    if ! command -v git &> /dev/null; then
        echo "git is not installed. Installing git..."
        sudo "$PACKAGE_MANAGER" install git -y
    fi
}

# Install kernel headers
install_kernel_headers() {
    echo "Installing kernel headers..."
    if ! sudo "$PACKAGE_MANAGER" install linux-headers-$(uname -r) -y; then
        echo "Specific kernel headers not found. Installing generic headers instead..."
        sudo "$PACKAGE_MANAGER" install linux-headers-generic -y
        if [[ $? -ne 0 ]]; then
            echo "Failed to install kernel headers. Exiting."
            exit 1
        fi
    fi
}

# Update and upgrade system packages
update_system() {
    echo "Installing updates and upgrades. This may take some time."
    sudo "$PACKAGE_MANAGER" update -y && \
    sudo "$PACKAGE_MANAGER" upgrade -y && \
    sudo "$PACKAGE_MANAGER" dist-upgrade -y
}

# Check if the Realtek driver is already installed
check_existing_driver() {
    if lsmod | grep -q "88XXau"; then
        echo "Driver already installed."
        
        # Prompt for driver removal
        read -p "Do you want to remove the existing installation? (y/n): " REMOVE_CHOICE
        
        if [[ "$REMOVE_CHOICE" == "y" || "$REMOVE_CHOICE" == "Y" ]]; then
            echo "Removing existing driver installation."
            sudo rmmod 88XXau
            if [[ $? -ne 0 ]]; then
                echo "Failed to remove the driver from the kernel. Exiting."
                exit 1
            fi
            
            # Remove driver via DKMS, if applicable
            if command -v dkms &> /dev/null; then
                sudo dkms remove rtl8812au/<version> --all || echo "Continuing to manual removal..."
            fi
            
            # Remove manually from /lib/modules if needed
            DRIVER_PATH="/lib/modules/$(uname -r)/kernel/drivers/net/wireless/88XXau.ko"
            [ -f "$DRIVER_PATH" ] && sudo rm -f "$DRIVER_PATH" && echo "Driver files removed from $DRIVER_PATH."
            
            sudo depmod -a
            echo "Driver uninstalled successfully."
        else
            echo "Skipping driver removal."
            exit 0
        fi
    fi
}

# Install Realtek drivers (always use package manager)
install_realtek_drivers() {
    echo "Installing Realtek drivers using the package manager."
    sudo "$PACKAGE_MANAGER" install realtek-rtl88xxau-dkms -y
}

# Execute WiFi driver setup steps directly
detect_distribution
update_system
install_git
install_kernel_headers
check_existing_driver
install_realtek_drivers

# Install additional tools if not already installed
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

echo "Setup complete. Rebooting system to apply changes..."
sudo reboot