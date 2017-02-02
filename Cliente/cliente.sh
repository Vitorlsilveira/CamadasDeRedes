#!/bin/bash
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
rm -f CamadaRede/tabelaCliente
rm -f CamadaRede/nexthopCliente
rm -f CamadaFisica/chaveCliente.txt

read -p "Qual a interface usar? " inter
ip=`ifconfig $inter | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`

echo "---Configuracao da tabela de roteamento---"
echo "Digite a (unica) linha da tabela no seguinte formato:"
echo "IP REDE      MASCARA      NEXT HOP"
read -p "" lin1

echo $lin1 >> CamadaRede/tabelaCliente

read -p "Qual o IP do destino? " ipDest

read -p "Qual arquivo requisitar? " arquivo

echo $ipDest >> config
echo $inter >> config
echo $arquivo >> config

read -p "Digite a chave da Criptografia: " chave
echo $chave >> CamadaFisica/chaveCliente.txt

./check.sh
terminator -l redes &>/dev/null
