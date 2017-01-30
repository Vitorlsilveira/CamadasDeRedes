Trabalho de implementaçao das camadas da pilha de protocolos tcp/ip

Autores:Andre Dornas,Gabriel Mattar,Vitor Lemos

##Execução
Executar o comando
```
./script.sh
```
e seguir os passos indicados.

##Camada Física
####Linguagem
Ruby 2.0+

####Funcionalidades
- Transferência de um quadro entre um cliente e um servidor;
- Criptografia por chave

####Requisitos
- digest-crc
- gibberish

##Camada Rede
####Linguagem
Python 2.7+

####Funcionalidades
- Tabela de roteamento

####Requisitos
- crc16

##Camada Transporte
####Linguagem
Dlang - v2.073.0+

####Funcionalidades
- TCP/UDP

####Requisitos
- Bibliotecas padrões

##Camada Aplicação
####Linguagem
Java

####Funcionalidades
- TCP/UDP

####Requisitos
- JDK 1.8
