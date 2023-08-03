# Lethbridge College CIT Sandbox VPN Setup for Linux
This is for linux users attempting to connect the CIT Sandbox VPN

## Prerequisites
### For Ubuntu & Debian
- `apt-get update`
- `apt-get -y install strongswan xl2tpd networkmanager`
 
### For RHEL/CentOS
- `yum -y install epel-release`
- `yum --enablerepo=epel -y install strongswan xl2tpd networkmanager`
- `yum -y install strongswan xl2tpd networkmanager`

### For Arch
- `sudo pacman -S xl2tpd strongswan networkmanager`

## Usage
1. Put the script into a folder
2. Allow the file to be read and executed
   - `sudo chmod ug=rx ./configureVPN.sh`
3. Run the script
   - `sudo ./configureVPN.sh`
