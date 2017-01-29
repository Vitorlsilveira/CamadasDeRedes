#kill ports
fuser -k 7777/tcp
fuser -k 9999/tcp
fuser -k 3333/tcp

if [ "$1" = "udp" ] 
then
	cp clienteConfigUDP ~/.config/terminator/config
	echo "UDP"
elif [ "$1" = "tcp" ] 
then 
	cp clienteConfigTCP ~/.config/terminator/config
	echo "TCP"
else 
	echo "FALTA PARAMETRO"
	exit
fi
terminator -l redes
