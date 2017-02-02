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

rm -f config
rm -f CamadaRede/tabelaServidor
rm -f CamadaRede/nexthopServidor
rm -f CamadaFisica/chaveServidor.txt

read -p "Qual a interface usar? " inter
ip=`ifconfig $inter | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`

echo "---Configuracao da tabela de roteamento---"
echo "Digite a (unica) linha da tabela no seguinte formato:"
echo "IP REDE      MASCARA      NEXT HOP"
read -p "" lin1

echo $lin1 >> CamadaRede/tabelaServidor

echo $inter >> config

read -p "Digite a chave da Criptografia: " chave
echo $chave >> CamadaFisica/chaveServidor.txt

./check.sh
terminator -l redes &>/dev/null
