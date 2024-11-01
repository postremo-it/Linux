#!/bin/bash

##################################################################
## Commands to use
##
## Check USB Connected Devices - lsusb
## Check network connections - iwconfig
## Connect to a wifi network - sudo nmcli dev wifi connect "<SSID>" password "<password>"
## 
##################################################################

##################################################################
## Change Wifi Card Mode 
## - Do not run this untill the drivers have been installed.
##
## sudo ip link set wlan0 down      # Disable the interface
## sudo iw dev wlan0 set type monitor  # Set to monitor mode
## sudo ip link set wlan0 up        # Re-enable the interface
## 
## 
##################################################################

##################################################################
## Setup Fluxion 
## 
## sudo git clone https://github.com/FluxionNetwork/fluxion.git
## cd fluxion
## /fluxion.sh -i
## 
## 
## 
## 
##################################################################

# Update Kali 
sudo apt-get update
sudo apt-get dist-upgrade
reboot

# Setup Kali VM for Tools to allow copy and paste
sudo dpkg --configure -a
sudo apt install spice-vdagent
sudo apt install qemu-guest-agent
reboot

# Setup WiFI Drivers - Do not plug in WiFi card until this is run
mkdir /home/kali/Desktop/WiFi_Drivers
cd /home/kali/Desktop/WiFi_Drivers
sleep 5
sudo git clone https://github.com/Khatcode/AWUS036ACH-Automated-Driver-Install.git
sleep 5
cd AWUS036ACH-Automated-Driver-Install
sleep 5
sudo chmod +x Alfasetup.sh
sleep 5``
sudo ./Alfasetup.sh

# Install Tools needed
sudo apt install hcxtools

## Select 1 when prompted for the source of the install
## When prompted, Reboot
## After rebooting plug in the Adaptor

# Unpack Worklist in Kali
## This is needed to crack WiFi password
sudo gzip -d /usr/share/wordlists/rockyou.txt.gz


gzip -d /usr/share/wordlists/rockyou.txt.gz
 