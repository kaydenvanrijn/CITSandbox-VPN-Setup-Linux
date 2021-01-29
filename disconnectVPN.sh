MY_PUBLIC_IP=162.xxx.xxx.240        #Your public IPV4, find it at:   https://www.whatismyip.com/
MY_DEFAULT_GATEWAY=192.168.1.254    #Find it after the word 'via':   ip route | grep -w default
VPN_IP=xxx.185.xxx.x7               #Find it on canvas

# DELETE THE ROUTES
echo "Deleting routes.." &&
ip route del default dev ppp0 &&
ip route del $VPN_IP via $MY_DEFAULT_GATEWAY dev wlan0 &&
ip route del $MY_PUBLIC_IP via $MY_DEFAULT_GATEWAY dev wlan0 &&

echo "..DONE!"
sleep 2
# DISCONNECT

echo "Disconnecting the VPN.." &&
bash -c 'echo "d vpn-connection" > /var/run/xl2tpd/l2tp-control' &&

sleep 2 &&

ipsec down L2TP-PSK &&
echo "..DONE!"

# PRINT IP
echo "Disconnected! Your IP should be $MY_PUBLIC_IP:" &&
sleep 2 &&
echo "Your IP is:" &&
wget -qO- http://ipv4.icanhazip.com; echo
