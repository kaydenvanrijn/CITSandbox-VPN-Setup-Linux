# PUT THE FILE IN A FOLDER
- cd /path/to/folder
- sudo chmod ug=rx ./configureVPN.sh

- sudo ./configureVPN.sh

# PLEASE READ THE OUTPUTS GIVEN

This is for linux users attempting to connect the CIT Sandbox VPN

# PREQUISITES

## For Ubuntu & Debian
- apt-get update
- apt-get -y install strongswan xl2tpd networkmanager
 
## For RHEL/CentOS
- yum -y install epel-release
- yum --enablerepo=epel -y install strongswan xl2tpd networkmanager
 
- yum -y install strongswan xl2tpd networkmanager

## For Arch
- sudo pacman -S xl2tpd strongswan networkmanager
