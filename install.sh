#!/bin/bash -e

# Setup OpenVPN
IPADDR=$1
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
sed -i -e 's/dh dh1024.pem/dh dh2048.pem/' /etc/openvpn/server.conf
sed -i -e 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/' /etc/openvpn/server.conf
sed -i -e 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 208.67.222.222"/' /etc/openvpn/server.conf
sed -i -e 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS 208.67.220.220"/' /etc/openvpn/server.conf
sed -i -e 's/;user nobody/user nobody/' /etc/openvpn/server.conf
sed -i -e 's/;group nogroup/group nogroup/' /etc/openvpn/server.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i -e 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
ufw allow ssh
ufw allow 1194/udp
sed -i -e 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
sed -i "1i# START OPENVPN RULES\n# NAT table rules\n*nat\n:POSTROUTING ACCEPT [0:0]\n# Allow traffic from OpenVPN client to eth0\n\n-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE\nCOMMIT\n# END OPENVPN RULES\n" /etc/ufw/before.rules
ufw --force enable

cp -r /usr/share/easy-rsa/ /etc/openvpn
mkdir -p /etc/openvpn/easy-rsa/keys
sed -i -e 's/KEY_NAME="EasyRSA"/KEY_NAME="server"/' /etc/openvpn/easy-rsa/vars
openssl dhparam -out /etc/openvpn/dh2048.pem 2048
cd /etc/openvpn/easy-rsa && . ./vars

# Optionally set indentity information for certificates:
# export KEY_COUNTRY="<%COUNTRY%>" # 2-char country code
# export KEY_PROVINCE="<%PROVINCE%>" # 2-char state/province code
# export KEY_CITY="<%CITY%>" # City name
# export KEY_ORG="<%ORG%>" # Org/company name
# export KEY_EMAIL="<%EMAIL%>" # Email address
# export KEY_OU="<%ORG_UNIT%>" # Orgizational unit / department

cd /etc/openvpn/easy-rsa && ./clean-all
cd /etc/openvpn/easy-rsa && ./build-ca --batch
cd /etc/openvpn/easy-rsa && ./build-key-server --batch server
cp /etc/openvpn/easy-rsa/keys/server.crt /etc/openvpn
cp /etc/openvpn/easy-rsa/keys/server.key /etc/openvpn
cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn
service openvpn start