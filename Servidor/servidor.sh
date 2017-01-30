#!/bin/bash
#kill ports
fuser -k 6768/tcp
fuser -k 5555/tcp
fuser -k 4444/tcp

if [ "$1" = "UDP" ]
then
	cp servidorConfigUDP ~/.config/terminator/config
	echo "UDP"
elif [ "$1" = "TCP" ]
then
	cp servidorConfigTCP ~/.config/terminator/config
	echo "TCP"
else
	echo "FALTA PARAMETRO"
	exit
fi
./check.sh
terminator -l redes &>/dev/null
