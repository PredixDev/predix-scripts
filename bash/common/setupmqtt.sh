#!/bin/bash
set -e
wget http://mosquitto.org/files/source/mosquitto-1.3.5.tar.gz
tar xzf mosquitto-1.3.5.tar.gz
cd mosquitto-1.3.5
make WITH_SRV=no
useradd mosquitto
cd test/broker
make test
cd ../../
cp client/mosquitto_pub /usr/bin
cp client/mosquitto_sub /usr/bin
cp lib/libmosquitto.so.1 /usr/lib
cp src/mosquitto /usr/bin
