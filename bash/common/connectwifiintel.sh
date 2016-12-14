#!/bin/bash
set -e
update-rc.d -f hostapd remove
cat << EOF > /etc/network/interfaces
# Wireless interfaces
auto $3
iface $3 inet dhcp
        wireless_mode managed
        wireless_essid any
        wpa-driver nl80211
        wpa-conf /etc/wpa_supplicant.conf
EOF
wpa_passphrase $1 $2  > /etc/wpa_supplicant.conf
rfkill unblock all
ifconfig $3 up
killall wpa_supplicant
wpa_supplicant -i $3 -D nl80211 -c /etc/wpa_supplicant.conf -B
udhcpc -i $3
