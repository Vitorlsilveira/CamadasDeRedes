#kill ports
fuser -k 7777/tcp
fuser -k 9999/tcp
fuser -k 3333/tcp

if [ "$1" = "UDP" ]
then
	cp clienteConfigUDP ~/.config/terminator/config
	echo "UDP"
elif [ "$1" = "TCP" ]
then
	cp clienteConfigTCP ~/.config/terminator/config
	echo "TCP"
else
	echo "FALTA PARAMETRO"
	exit
fi

rm -f config
read -p "Qual a interface usar? " inter
ip=`ifconfig $inter | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`

read -p "Qual o IP do destino? " ipDest

read -p "Qual arquivo requisitar? " arquivo

echo $ipDest >> config
echo $inter >> config
echo $arquivo >> config

./check.sh
terminator -l redes &>/dev/null
