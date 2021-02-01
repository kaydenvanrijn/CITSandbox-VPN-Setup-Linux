#!/bin/sh

# Written by Kayden van Rijn
# Saturday, January 31st 2021
# For use by students

## GET IPv4
printf "Do you want to automatically get your IPv4? (Y/n): "
read -r answer

if [ "$answer" != "${answer#[Nn]}" ] ;then
    printf "Please type your IPv4: ";
    read -r MY_IP
else
    echo "Getting your IPv4...";
    MY_IP="`wget -qO- http://ipv4.icanhazip.com`"
fi

echo "Your IPv4: $MY_IP"; echo

## GET NETWORK DEVICE
printf "Do you want to automatically get your network device? (Y/n): "
read -r answer

if [ "$answer" != "${answer#[Nn]}" ] ;then
    printf "Please type your network device (ex. wlan0, eth0): ";
    read -r MY_NETWORK_DEVICE
else
    echo "Getting your network device...";
    MY_NETWORK_DEVICE="`nmcli | grep -w connected | cut -d : -f -1`"
fi

echo "Your network device: $MY_NETWORK_DEVICE"; echo

## GET DEAFULT GATEWAY
printf "Do you want to automatically get your default gateway? (Y/n): "
read -r answer

if [ "$answer" != "${answer#[Nn]}" ] ;then
    printf "Please type your default gateway: ";
    read -r MY_DEFAULT_GATEWAY
else
    echo "Getting your default gateway...";
    MY_DEFAULT_GATEWAY="`ip route | grep -w default | cut -d ' ' -f 3-3`"
fi

echo "Your default gateway: $MY_DEFAULT_GATEWAY"; echo

echo "ALL OF THE FOLLOWING CAN BE FOUND ON CANVAS!"; echo

## GET VPN IPv4
printf "Please type your VPN's IPv4: ";
read -r VPN_IP

echo "Your VPN's IPv4: $VPN_IP"; echo

## GET VPN PRESHARED KEY
printf "Please type your VPN's preshared key: ";
read -r VPN_PRESHAREDKEY

## WARNING
echo "Your VPN's preshared key: $VPN_PRESHAREDKEY"; echo

## GET VPN USERNAME
printf "Please type your username for the VPN: ";
read -r VPN_USERNAME

echo "Your username for the VPN: $VPN_USERNAME"; echo

## GET VPN PASSWORD
printf "Please type your password for the VPN (input is hidden): ";
read -r -s VPN_PASSWORD; echo

## LINUX VM IPv4
printf "Please type your CIT Sandbox Linux IP: ";
read -r MY_LINUX_VM_IP

echo "Your CIT Sandbox Linux IP: $MY_LINUX_VM_IP"; echo

## MESSAGE
printf "All done! Is all of your information correct? (Y/n): ";
read answer;

if [ "$answer" != "${answer#[Nn]}" ] ;then
    echo; echo "Please run the script again!"; exit;
fi

## WRITE CONFIG FILES
echo; echo "Writing config files for you..";

# IPSEC.CONF
echo "Writing /etc/ipsec.conf ..."

touch /etc/ipsec.conf
cat > /etc/ipsec.conf <<EOF
config setup

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1
    keyexchange=ikev1
    authby=secret
    ike=aes128-sha1-modp1024,3des-sha1-modp1024!
    esp=aes128-sha1-modp1024,3des-sha1-modp1024!

conn L2TP-PSK
    keyexchange=ikev1
    left=%defaultroute
    auto=add
    authby=secret
    type=transport
    leftprotoport=17/1701
    rightprotoport=17/1701
    right=$VPN_IP
    esp=aes256-sha1!
EOF

chmod 600 /etc/ipsec.conf

echo "..DONE!"; echo;

# IPSEC.SECRETS
echo "Writing /etc/ipsec.secrets ..."

touch /etc/ipsec.secrets
cat > /etc/ipsec.secrets <<EOF
: PSK "$VPN_PRESHAREDKEY"
EOF

chmod 600 /etc/ipsec.secrets

echo "..DONE!"; echo;

## OS CHECK
printf "Are you running CentOS/RHEL or Fedora? (y/N): ";
read answer;

if [ "$answer" != "${answer#[Yy]}" ] ;then
    mv /etc/strongswan/ipsec.conf /etc/strongswan/ipsec.conf.old 2>/dev/null
    mv /etc/strongswan/ipsec.secrets /etc/strongswan/ipsec.secrets.old 2>/dev/null
    ln -s /etc/ipsec.conf /etc/strongswan/ipsec.conf
    ln -s /etc/ipsec.secrets /etc/strongswan/ipsec.secrets
fi

# XL2TPD.conf
echo "Writing /etc/xl2tpd/xl2tpd.conf ..."

touch /etc/xl2tpd/xl2tpd.conf
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[lac vpn-connection]
lns = $VPN_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

chmod 600 /etc/xl2tpd/xl2tpd.conf

echo "..DONE!"; echo;

# OPTIONS.L2TPD.CLIENT
echo "Writing /etc/ppp/options.l2tpd.client ..."

touch /etc/ppp/options.l2tpd.client
cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-mschap-v2
noccp
noauth
idle 1800
mtu 1410
mru 1410
defaultroute
usepeerdns
debug
connect-delay 5000
name $VPN_USERNAME
password $VPN_PASSWORD
EOF
 
chmod 600 /etc/ppp/options.l2tpd.client

echo "..DONE!"; echo;
#####################################################

##WRITE OTHER SCRIPTS
#citVPN.sh
echo "Writing connect_citVPN.sh..."

touch ./connect_citVPN.sh
cat > ./connect_citVPN.sh <<EOF
# ADD VPN CONTROLLER

echo "Adding VPN controller file.."
mkdir -p /var/run/xl2tpd
touch /var/run/xl2tpd/l2tp-control

echo "..DONE!"; echo;
sleep 2

# RESTART SERVICES
echo "Restarting strongSwan/ipsec and xl2tpd services..."
systemctl restart strongswan
systemctl restart xl2tpd

echo "Restarting ipsec.."
sudo ipsec restart --conf /etc/ipsec.conf

echo "..DONE!"; echo;
sleep 4

# CONNECT TUNNEL TO L2TP-PSK NVP
echo "Starting tunnel for L2TP-PSK.."
ipsec up L2TP-PSK

echo "..DONE!"; echo;
sleep 2

# CREATE PPP0 DEVICE
echo "Creating ppp0 interface.."
bash -c 'echo "c vpn-connection" > /var/run/xl2tpd/l2tp-control'

echo "..DONE!"; echo;
sleep 4

# PRINT DEVICES
echo "You should see a ppp device:"
ip addr | grep ppp; echo

sleep 2

# CONNECT TO VPN
echo "Connecting to VPN..."
ip route add $VPN_IP via $MY_DEFAULT_GATEWAY dev $MY_NETWORK_DEVICE
ip route add $MY_IP via $MY_DEFAULT_GATEWAY dev $MY_NETWORK_DEVICE
ip route add default dev ppp0

sleep 4

# PRINT IP
echo "Connected! Your IPv4 should be $VPN_IP:"

printf "Your IPv4 is: " 
echo "\`wget -qO- http://ipv4.icanhazip.com\`"; echo;

# SSH
printf "Do you want to connect to your terminal now? (Y/n): "
read -r answer

echo;

if [ "$answer" != "${answer#[Nn]}" ] ;then
    echo "You answered no! To connect to your terminal please type: ssh yourusernameORroot@$MY_LINUX_VM_IP";
else
    echo "Connecting to your terminal...";
    ssh $MY_LINUX_VM_IP;
fi

printf "All done! To disconnect, please run: sudo \`pwd\`"; echo /disconnect_citVPN.sh
EOF
 
chmod ug=rwx ./connect_citVPN.sh

echo "..DONE!"; echo;

#disconnect_citVPN.sh
echo "Writing disconnect_citVPN.sh..."

touch ./disconnect_citVPN.sh
cat > ./disconnect_citVPN.sh <<EOF
# DELETE THE ROUTES
echo "Deleting routes.."
ip route del default dev ppp0
ip route del $VPN_IP via $MY_DEFAULT_GATEWAY dev $MY_NETWORK_DEVICE
ip route del $MY_IP via $MY_DEFAULT_GATEWAY dev $MY_NETWORK_DEVICE

echo "..DONE!"; echo;
sleep 2
# DISCONNECT

echo "Disconnecting the VPN.."
bash -c 'echo "d vpn-connection" > /var/run/xl2tpd/l2tp-control'

sleep 2

ipsec down L2TP-PSK
echo "..DONE!"; echo;

# PRINT IP
echo "Disconnected! Your IPv4 should be $MY_IP:"
sleep 2
printf "Your IPv4 is: " 
echo "\`wget -qO- http://ipv4.icanhazip.com\`";
EOF
 
chmod ug=rwx ./disconnect_citVPN.sh

echo "..DONE!"; echo;

#####################################################

echo "Everyting has been configured!"

printf "Do you want to start the VPN now? (Y/n): "
read -r answer

if [ "$answer" != "${answer#[Nn]}" ] ;then
    printf "You answered no! To connect, please run: sudo `pwd`"; echo /connect_citVPN.sh; exit;
fi

./connect_citVPN.sh
