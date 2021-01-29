## For Ubuntu & Debian #############################
#apt-get update
#apt-get -y install strongswan xl2tpd
 
## For RHEL/CentOS ##################################
#yum -y install epel-release
#yum --enablerepo=epel -y install strongswan xl2tpd
 
#yum -y install strongswan xl2tpd

## For Arch #########################################
# sudo pacman -S xl2tpd strongswan

#####################################################

MY_PUBLIC_IP=162.xxx.xxx.xxx        #Your public IPV4, find it at:   https://www.whatismyip.com/
MY_NETWORK_DEVICE=wlan0             #Find it with:                   nmcli | grep -w connected
MY_DEFAULT_GATEWAY=192.168.1.254    #Find it after the word 'via':   ip route | grep -w default
MY_CLASS_LINUX_VM_IP=xxx.22.3.xxx   #Find it on canvas
VPN_IP=xxx.185.xxx.x7               #Find it on canvas
VPN_PRESHAREDKEY=CITSandboxxxxx     #Find it on canvas
VPN_USERNAME=s0123456               #Find it on canvas, @cit.local is not required.
VPN_PASSWORD=Passwordxxxx           #Find it on canvas

#####################################################

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

echo "..DONE!"

# IPSEC.SECRETS
echo "Writing /etc/ipsec.secrets ..."

touch /etc/ipsec.secrets
cat > /etc/ipsec.secrets <<EOF
: PSK "$VPN_PRESHAREDKEY"
EOF

chmod 600 /etc/ipsec.secrets

echo "..DONE!"

## For CentOS/RHEL & Fedora ONLY
#mv /etc/strongswan/ipsec.conf /etc/strongswan/ipsec.conf.old 2>/dev/null
#mv /etc/strongswan/ipsec.secrets /etc/strongswan/ipsec.secrets.old 2>/dev/null
#ln -s /etc/ipsec.conf /etc/strongswan/ipsec.conf
#ln -s /etc/ipsec.secrets /etc/strongswan/ipsec.secrets

# XL2TPD.conf
echo "Writing /etc/xl2tpd/xl2tpd.conf ..."

touch /etc/xl2tpd/xl2tpd.conf
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[lac vpn-connection]
lns = 199.185.125.27
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

chmod 600 /etc/xl2tpd/xl2tpd.conf

echo "..DONE!"

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

echo "..DONE!"
#####################################################

sleep 2

# ADD VPN CONTROLLER
echo "Adding VPN controller file.." &&
mkdir -p /var/run/xl2tpd &&
touch /var/run/xl2tpd/l2tp-control &&

echo "..DONE!"
sleep 2

# RESTART SERVICES
echo "Restarting strongSwan/ipsec and xl2tpd services..."
systemctl restart strongswan &&
systemctl restart xl2tpd &&

echo "Restarting ipsec.." &&
sudo ipsec restart --conf /etc/ipsec.conf &&

echo "..DONE!"
sleep 4

# CONNECT TUNNEL TO L2TP-PSK NVP
echo "Starting tunnel for L2TP-PSK.." &&
ipsec up L2TP-PSK &&

echo "..DONE!"
sleep 2

# CREATE PPP0 DEVICE
echo "Creating ppp0 interface.." &&
bash -c 'echo "c vpn-connection" > /var/run/xl2tpd/l2tp-control' &&

echo "..DONE!"
sleep 2

# PRINT DEVICES
echo "You should see a ppp device:" &&
ip addr | grep ppp

sleep 2

# CONNECT TO VPN
echo "Connecting to VPN..."
ip route add $VPN_IP via $MY_DEFAULT_GATEWAY dev $MY_NETWORK_DEVICE &&
ip route add $MY_PUBLIC_IP via $MY_DEFAULT_GATEWAY dev $MY_NETWORK_DEVICE &&
ip route add default dev ppp0 &&

sleep 2 &&

echo "If you see RTNETLINK answers: File exists, please run disconnectVPN.sh" &&

# PRINT IP
echo "Connected! Your IP should be $VPN_IP:" &&
sleep 2 &&
echo "Your IP is:" &&
wget -qO- http://ipv4.icanhazip.com; echo

# SSH
echo "Do you want to connect to your terminal now?(y/n)"
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Connecting to your terminal..."; ssh $MY_CLASS_LINUX_VM_IP;
fi

echo "All done! To disconnect, please run 'sudo disconnectVPN.sh'"