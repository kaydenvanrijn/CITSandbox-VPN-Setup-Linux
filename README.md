# PLEASE READ THE FILES AND EDIT THE VARIABLES

This is for linux users attempting to connect the CIT Sandbox VPN

# PREQUISITES

## For Ubuntu & Debian
- apt-get update
- apt-get -y install strongswan xl2tpd
 
## For RHEL/CentOS
- yum -y install epel-release
- yum --enablerepo=epel -y install strongswan xl2tpd
 
- yum -y install strongswan xl2tpd

## For Arch
- sudo pacman -S xl2tpd strongswan
