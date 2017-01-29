#kill ports
fuser -k 6768/tcp
fuser -k 5555/tcp
fuser -k 4444/tcp

if [ "$1" = "udp" ] 
then
	cp servidorConfigUDP ~/.config/terminator/config
	echo "UDP"
elif [ "$1" = "tcp" ] 
then 
	cp servidorConfigTCP ~/.config/terminator/config
	echo "TCP"
else 
	echo "FALTA PARAMETRO"
	exit
fi
terminator -l redes
