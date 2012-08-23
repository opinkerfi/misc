#!/bin/bash


HOST=$1
IP=$2
STORAGEPOOL="pool=vm00"
SIZE=10
RAM=1024
NETWORK="bridge=br268"
DNS=8.8.8.8
GATEWAY=192.168.68.254
NETMASK=255.255.255.0
LOCATION="http://ks.ok.is/ftp/redhat/6.1/x86-64/os/"
KS="http://pall.sigurdsson.is/tr.ks"



function read_value {
	text=$1
	default=$2
	read -p "$text [$default]: " input
	if [ -z $input ]; then
		input=$default
	fi
	echo $input
}


HOST=`read_value "Host" "$HOST"`
IP=`read_value "IP Address" "$IP"`
SIZE=`read_value "Disk Size (gb)" "$SIZE"`
STORAGEPOOL=`read_value "Storage Pool" "$STORAGEPOOL"`
RAM=`read_value "Memory (mb) " "$RAM"`
NETWORK=`read_value "Network interface" "$NETWORK"`
DNS=`read_value "DNS" "$DNS"`
GATEWAY=`read_value "Default gateway" "$GATEWAY"`
NETMASK=`read_value "Netmask" "$NETMASK"`
LOCATION=`read_value "Install Location" "$LOCATION"`

virt-install 	\
--name $HOST 	\
--ram $RAM 	\
--disk $STORAGEPOOL,size=$SIZE,bus=virtio \
--network $NETWORK,model=virtio \
--virt-type kvm \
--location=$LOCATION \
--graphics=none \
--extra-args "ks=$KS hostname=$HOST console=ttyS0 ip=$IP dns=$DNS gateway=$GATEWAY netmask=$NETMASK"

