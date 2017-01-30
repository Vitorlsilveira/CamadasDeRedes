#!/bin/bash
echo "Selecione o tipo da conexao: "
select type in "TCP" "UDP"; do
  echo "Deseja executar:"
  select a in "Servidor" "Cliente" "Roteador" "Sair"; do
    case $a in
      Servidor ) cd Servidor; echo "Executando $a - $type"; ./servidor.sh $type; break ;;
      Cliente ) cd Cliente; echo "Executando $a - $type"; ./cliente.sh $type; break ;;
      Roteador ) cd Roteador; echo "Executando $a - $type"; ./roteador.sh; break ;;
      Sair ) exit ;;
      * ) echo "Responda (1, 2 ou 3)";;
    esac
  done
  exit
done
