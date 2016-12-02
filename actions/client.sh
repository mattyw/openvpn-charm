#!/bin/bash -e

IPADDR=`unit-get public-address`
PROFILE=$1

(cd /etc/openvpn/easy-rsa && source vars && ./build-key --batch $PROFILE)
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/easy-rsa/keys/client.ovpn
sed -i -e "s/my-server-1/$IPADDR/" /etc/openvpn/easy-rsa/keys/client.ovpn
sed -i -e 's/;user nobody/user nobody/' /etc/openvpn/easy-rsa/keys/client.ovpn
sed -i -e 's/;group nogroup/group nogroup/' /etc/openvpn/easy-rsa/keys/client.ovpn
sed -i -e 's/ca ca.crt//' /etc/openvpn/easy-rsa/keys/client.ovpn
sed -i -e 's/cert client.crt//' /etc/openvpn/easy-rsa/keys/client.ovpn
sed -i -e 's/key client.key//' /etc/openvpn/easy-rsa/keys/client.ovpn
echo "<ca>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
cat /etc/openvpn/ca.crt >> /etc/openvpn/easy-rsa/keys/client.ovpn
echo "</ca>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
echo "<cert>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
openssl x509 -outform PEM -in /etc/openvpn/easy-rsa/keys/$PROFILE.crt >> /etc/openvpn/easy-rsa/keys/client.ovpn
echo "</cert>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
echo "<key>" >> /etc/openvpn/easy-rsa/keys/client.ovpn
cat /etc/openvpn/easy-rsa/keys/$PROFILE.key >> /etc/openvpn/easy-rsa/keys/client.ovpn
echo "</key>" >> /etc/openvpn/easy-rsa/keys/client.ovpn

mkdir /home/ubuntu/$PROFILE/
cp /etc/openvpn/easy-rsa/keys/client.ovpn /home/ubuntu/$PROFILE
cp /etc/openvpn/easy-rsa/keys/$PROFILE.crt /home/ubuntu/$PROFILE
cp /etc/openvpn/easy-rsa/keys/$PROFILE.key /home/ubuntu/$PROFILE
cp /etc/openvpn/easy-rsa/keys/ca.crt /home/ubuntu/$PROFILE
(cd /home/ubuntu/$PROFILE && tar -czf $PROFILE.tgz *)
