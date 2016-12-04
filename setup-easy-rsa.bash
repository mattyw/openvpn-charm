#!/bin/bash

set -e

EASY_RSA=/usr/share/easy-rsa

rm -f /etc/openvpn/easy-rsa
ln -s $EASY_RSA/ /etc/openvpn/easy-rsa
mkdir -p $EASY_RSA/keys
sed -i -e 's/KEY_NAME="EasyRSA"/KEY_NAME="server"/' $EASY_RSA/vars
openssl dhparam -out /etc/openvpn/dh2048.pem 2048

cd $EASY_RSA
. /etc/openvpn/easy-rsa/vars

# Optionally set indentity information for certificates:
# export KEY_COUNTRY="<%COUNTRY%>" # 2-char country code
# export KEY_PROVINCE="<%PROVINCE%>" # 2-char state/province code
# export KEY_CITY="<%CITY%>" # City name
# export KEY_ORG="<%ORG%>" # Org/company name
# export KEY_EMAIL="<%EMAIL%>" # Email address
# export KEY_OU="<%ORG_UNIT%>" # Orgizational unit / department

./clean-all
./build-ca --batch
./build-key-server --batch server

for fn in server.crt server.key ca.crt; do
	rm -f /etc/openvpn/${fn}
	ln -s $EASY_RSA/keys/${fn} /etc/openvpn
done
