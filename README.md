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

# USAGE (RUN IT WITH SUDO)
Place these files into some folder, for example /home/kayden/
- sudo /home/kayden/connectVPN.sh
- sudo /home/kayden/disconnectVPN.sh

You can alias these in your ~/.bashrc, by adding them to the last lines
- alias connectvpn='/home/kayden/connectVPN.sh'
- alias disconnectvpn='/home/kayden/disconnectVPN.sh'

After you add those lines run:
- source ~/.bashrc
