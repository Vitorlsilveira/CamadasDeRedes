#kill ports
fuser -k 7777/tcp
fuser -k 6768/tcp
fuser -k 5555/tcp
fuser -k 5554/tcp
fuser -k 4444/tcp
fuser -k 9999/tcp
fuser -k 3333/tcp


if [ "$1" = "udp" ] 
then
	cp configServidorUDP ~/.config/terminator/config
	echo "UDP"
elif [ "$1" = "tcp" ] 
then 
	cp configServidorTCP ~/.config/terminator/config
	echo "TCP"
else 
	echo "FALTA PARAMETRO"
	exit
fi
terminator -l redes
