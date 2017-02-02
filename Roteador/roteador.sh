#kill ports
fuser -k 1111/tcp
fuser -k 2222/tcp
cp roteadorConfig ~/.config/terminator/config

rm -f config
rm -f CamadaRede/tabela
rm -f CamadaRede/nexthop
rm -f CamadaFisica/Cliente/chaveServidor.txt
rm -f CamadaFisica/Servidor/chaveCliente.txt

read -p "Qual a interface para o servidor? " interS
ipS=`ifconfig $interS | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`

read -p "Qual a interface para o cliente? " interC
ipC=`ifconfig $interC | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`

echo $interS >> config
echo $interC >> config

echo "---Configuracao da tabela de roteamento---"
echo "Digite as 2 linhas da tabela no seguinte formato:"
echo "IP REDE      MASCARA      NEXT HOP"

read -p "" lin1
read -p "" lin2

echo $lin1 >> CamadaRede/tabela
echo $lin2 >> CamadaRede/tabela

read -p "Digite a chave da Criptografia: " chave
echo $chave >> CamadaFisica/Cliente/chaveServidor.txt
echo $chave >> CamadaFisica/Servidor/chaveCliente.txt

./check.sh
terminator -l redes &>/dev/null
